'use server';

import { z } from 'zod';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken, verifyUserByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/lib/server/audit-log';
import type { MessageReport, ReportStatus, ModerationAction, MessageHiddenByAdmin } from '@/lib/types';
import { logger } from '@/lib/logger';

// SECURITY: Firestore document IDs are interpolated into paths; reject any
// shape that would let `..` / `/` walk outside the expected collection.
const FirestoreIdSchema = z
  .string()
  .min(1)
  .max(128)
  .regex(/^[A-Za-z0-9_-]+$/, 'invalid_id');

// Mirror src/lib/types.ts ReportReason — keep in sync.
const ReportReasonSchema = z.enum([
  'spam', 'harassment', 'inappropriate', 'offensive', 'violence', 'fraud', 'other',
]);

const CreateMessageReportSchema = z.object({
  idToken: z.string().min(1),
  conversationId: FirestoreIdSchema,
  messageId: FirestoreIdSchema.optional(),
  messageSenderId: z.string().min(1).max(128),
  messageSenderName: z.string().max(200).optional(),
  messageText: z.string().max(4000).optional(),
  reason: ReportReasonSchema,
  description: z.string().max(2000).optional(),
});

const HideMessageSchema = z.object({
  idToken: z.string().min(1),
  conversationId: FirestoreIdSchema,
  messageId: FirestoreIdSchema,
  reason: z.string().max(500).optional(),
});

// Mirror src/lib/types.ts ReportStatus / ModerationAction — keep in sync.
const ReviewReportSchema = z.object({
  idToken: z.string().min(1),
  reportId: FirestoreIdSchema,
  status: z.enum(['pending', 'reviewed', 'action_taken', 'dismissed']),
  actionTaken: z.enum(['hidden', 'user_warned', 'user_blocked', 'none']).optional(),
});

/**
 * SECURITY: previously this RPC took `reporterId` and `reporterName` as
 * client-supplied strings. Anyone could submit reports against any sender
 * while pretending to be any uid — useful for false-flag harassment, false
 * mass-reporting, and clogging the moderation queue under stolen identities.
 * Now we require an idToken and derive reporterId/reporterName server-side
 * from Firebase Auth + the trusted users/{uid} profile.
 */
export async function createMessageReportAction(input: {
  idToken: string;
  conversationId: string;
  messageId?: string;
  messageSenderId: string;
  messageSenderName?: string;
  messageText?: string;
  reason: MessageReport['reason'];
  description?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = CreateMessageReportSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные данные жалобы' };
  }
  try {
    const reporter = await verifyUserByIdToken(parsed.data.idToken);
    const ref = adminDb.collection('messageReports').doc();
    const report: MessageReport = {
      id: ref.id,
      reporterId: reporter.uid,
      reporterName: reporter.name,
      conversationId: parsed.data.conversationId,
      ...(parsed.data.messageId ? { messageId: parsed.data.messageId } : {}),
      messageSenderId: parsed.data.messageSenderId,
      messageSenderName: parsed.data.messageSenderName,
      messageText: parsed.data.messageText?.slice(0, 500),
      reason: parsed.data.reason,
      description: parsed.data.description?.slice(0, 1000),
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    await ref.set(report);
    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'UNAUTHORIZED') return { ok: false, error: 'Требуется вход' };
    if (msg === 'BLOCKED') return { ok: false, error: 'Аккаунт заблокирован' };
    logger.error('moderation', 'createMessageReportAction', e);
    return { ok: false, error: 'Не удалось отправить жалобу' };
  }
}

export async function hideMessageAction(input: {
  idToken: string;
  conversationId: string;
  messageId: string;
  reason?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = HideMessageSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные параметры' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);

    const hiddenByAdmin: MessageHiddenByAdmin = {
      at: new Date().toISOString(),
      by: actor.uid,
      reason: parsed.data.reason,
    };

    await adminDb
      .collection('conversations')
      .doc(parsed.data.conversationId)
      .collection('messages')
      .doc(parsed.data.messageId)
      .update({ hiddenByAdmin });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.hide_message',
      target: { type: 'message', id: parsed.data.messageId },
      details: { conversationId: parsed.data.conversationId, reason: parsed.data.reason },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[hideMessageAction]', e);
    return { ok: false, error: 'Не удалось скрыть сообщение' };
  }
}

export async function unhideMessageAction(input: {
  idToken: string;
  conversationId: string;
  messageId: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = z.object({
    idToken: z.string().min(1),
    conversationId: FirestoreIdSchema,
    messageId: FirestoreIdSchema,
  }).safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные параметры' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);

    const { FieldValue } = await import('firebase-admin/firestore');
    await adminDb
      .collection('conversations')
      .doc(parsed.data.conversationId)
      .collection('messages')
      .doc(parsed.data.messageId)
      .update({ hiddenByAdmin: FieldValue.delete() });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.unhide_message',
      target: { type: 'message', id: parsed.data.messageId },
      details: { conversationId: parsed.data.conversationId },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[unhideMessageAction]', e);
    return { ok: false, error: 'Не удалось восстановить сообщение' };
  }
}

export async function reviewReportAction(input: {
  idToken: string;
  reportId: string;
  status: ReportStatus;
  actionTaken?: ModerationAction;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = ReviewReportSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные параметры' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);

    await adminDb.collection('messageReports').doc(parsed.data.reportId).update({
      status: parsed.data.status,
      actionTaken: parsed.data.actionTaken ?? 'none',
      reviewedBy: actor.uid,
      reviewedAt: new Date().toISOString(),
    });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.review_report',
      target: { type: 'message', id: parsed.data.reportId },
      details: { status: parsed.data.status, actionTaken: parsed.data.actionTaken },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[reviewReportAction]', e);
    return { ok: false, error: 'Ошибка обработки жалобы' };
  }
}
