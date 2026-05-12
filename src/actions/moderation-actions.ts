'use server';

import { z } from 'zod';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken, verifyUserByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/lib/server/audit-log';
import type { MessageReport, Notification, ReportStatus, ModerationAction, MessageHiddenByAdmin } from '@/lib/types';
import { logger } from '@/lib/logger';

/**
 * Best-effort notification к автору жалобы по итогам ревью. Пишем в
 * `users/{reporterId}/notifications/{auto}` — клиент уже подписан на эту
 * коллекцию для собственных уведомлений.
 *
 * Ошибки тут не пробрасываем: пользователь должен увидеть «жалоба
 * рассмотрена», но если шаг провалится — flow модерации не блокируется
 * (статус жалобы уже обновлён в основной операции).
 */
async function notifyReporterOfDecision(opts: {
  reportId: string;
  reporterId: string;
  status: ReportStatus;
  actionTaken: ModerationAction;
}): Promise<void> {
  try {
    const { reporterId, status, actionTaken } = opts;
    if (!reporterId) return;
    let title: string;
    let body: string;
    if (status === 'action_taken') {
      title = 'Жалоба рассмотрена';
      body = actionTaken === 'hidden'
        ? 'Сообщение скрыто модератором.'
        : actionTaken === 'user_blocked'
          ? 'Автор сообщения заблокирован.'
          : actionTaken === 'user_warned'
            ? 'Автору вынесено предупреждение.'
            : 'По жалобе приняты меры.';
    } else if (status === 'dismissed') {
      title = 'Жалоба рассмотрена';
      body = 'Модератор не нашёл нарушений в сообщении.';
    } else if (status === 'reviewed') {
      title = 'Жалоба рассмотрена';
      body = 'Модератор изучил жалобу.';
    } else {
      return;
    }
    const ref = adminDb.collection('users').doc(reporterId).collection('notifications').doc();
    const notification: Notification = {
      id: ref.id,
      userId: reporterId,
      title,
      body,
      link: '',
      createdAt: new Date().toISOString(),
      isRead: false,
    };
    await ref.set(notification);
  } catch (e) {
    logger.error('moderation', 'notifyReporterOfDecision failed', { reportId: opts.reportId, e });
  }
}

// SECURITY: Firestore document IDs are interpolated into paths; reject any
// shape that would let `..` / `/` walk outside the expected collection.
// Whitelist-regex был слишком узким — резал валидные secret-chat IDs вида
// `sdm_5:alice_3:bob` (двоеточие). Переходим на blacklist: запрещаем `/` и
// чистые `.`/`..`; остальное Firestore SDK обрабатывает как identifier,
// а не как path-компонент, поэтому path-injection невозможен.
const FirestoreIdSchema = z
  .string()
  .min(1)
  .max(256)
  .refine((s) => !s.includes('/'), 'invalid_id: slash forbidden')
  .refine((s) => s !== '.' && s !== '..', 'invalid_id: dot/dotdot forbidden');

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
    logger.error('moderation', 'hideMessageAction', e);
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
    logger.error('moderation', 'unhideMessageAction', e);
    return { ok: false, error: 'Не удалось восстановить сообщение' };
  }
}

const ReviewAndHideSchema = z.object({
  idToken: z.string().min(1),
  reportId: FirestoreIdSchema,
  conversationId: FirestoreIdSchema,
  messageId: FirestoreIdSchema,
  reason: z.string().max(500).optional(),
});

/**
 * Атомарно скрывает сообщение и переводит жалобу в `action_taken`.
 * Запись в Firestore идёт одним `WriteBatch` — поэтому либо обе мутации
 * применяются, либо ни одна. Раньше две операции шли последовательно,
 * и при падении второй жалоба оставалась `pending`, а сообщение уже скрыто.
 */
export async function reviewAndHideReportAction(input: {
  idToken: string;
  reportId: string;
  conversationId: string;
  messageId: string;
  reason?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = ReviewAndHideSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные параметры' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);
    const now = new Date().toISOString();

    const hiddenByAdmin: MessageHiddenByAdmin = {
      at: now,
      by: actor.uid,
      reason: parsed.data.reason,
    };

    const messageRef = adminDb
      .collection('conversations')
      .doc(parsed.data.conversationId)
      .collection('messages')
      .doc(parsed.data.messageId);
    const reportRef = adminDb.collection('messageReports').doc(parsed.data.reportId);

    const batch = adminDb.batch();
    batch.update(messageRef, { hiddenByAdmin });
    batch.update(reportRef, {
      status: 'action_taken' satisfies ReportStatus,
      actionTaken: 'hidden' satisfies ModerationAction,
      reviewedBy: actor.uid,
      reviewedAt: now,
    });
    await batch.commit();

    const reportSnap = await reportRef.get();
    const reporterId = reportSnap.exists ? String(reportSnap.data()?.reporterId ?? '') : '';

    await Promise.all([
      logAdminAction({
        actorId: actor.uid,
        actorName: actor.name,
        action: 'moderation.hide_message',
        target: { type: 'message', id: parsed.data.messageId },
        details: { conversationId: parsed.data.conversationId, reason: parsed.data.reason, reportId: parsed.data.reportId },
      }),
      logAdminAction({
        actorId: actor.uid,
        actorName: actor.name,
        action: 'moderation.review_report',
        target: { type: 'message', id: parsed.data.reportId },
        details: { status: 'action_taken', actionTaken: 'hidden', atomic: true },
      }),
      notifyReporterOfDecision({
        reportId: parsed.data.reportId,
        reporterId,
        status: 'action_taken',
        actionTaken: 'hidden',
      }),
    ]);

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('moderation', 'reviewAndHideReportAction', e);
    return { ok: false, error: 'Не удалось скрыть сообщение и обработать жалобу' };
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

    const reportRef = adminDb.collection('messageReports').doc(parsed.data.reportId);
    await reportRef.update({
      status: parsed.data.status,
      actionTaken: parsed.data.actionTaken ?? 'none',
      reviewedBy: actor.uid,
      reviewedAt: new Date().toISOString(),
    });

    const reportSnap = await reportRef.get();
    const reporterId = reportSnap.exists ? String(reportSnap.data()?.reporterId ?? '') : '';

    await Promise.all([
      logAdminAction({
        actorId: actor.uid,
        actorName: actor.name,
        action: 'moderation.review_report',
        target: { type: 'message', id: parsed.data.reportId },
        details: { status: parsed.data.status, actionTaken: parsed.data.actionTaken },
      }),
      notifyReporterOfDecision({
        reportId: parsed.data.reportId,
        reporterId,
        status: parsed.data.status,
        actionTaken: parsed.data.actionTaken ?? 'none',
      }),
    ]);

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('moderation', 'reviewReportAction', e);
    return { ok: false, error: 'Ошибка обработки жалобы' };
  }
}
