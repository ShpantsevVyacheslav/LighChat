'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/actions/audit-log-actions';
import type { MessageReport, ReportStatus, ModerationAction, MessageHiddenByAdmin } from '@/lib/types';

export async function createMessageReportAction(input: {
  reporterId: string;
  reporterName: string;
  conversationId: string;
  messageId: string;
  messageSenderId: string;
  messageSenderName?: string;
  messageText?: string;
  reason: MessageReport['reason'];
  description?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const ref = adminDb.collection('messageReports').doc();
    const report: MessageReport = {
      id: ref.id,
      reporterId: input.reporterId,
      reporterName: input.reporterName,
      conversationId: input.conversationId,
      messageId: input.messageId,
      messageSenderId: input.messageSenderId,
      messageSenderName: input.messageSenderName,
      messageText: input.messageText?.slice(0, 500),
      reason: input.reason,
      description: input.description?.slice(0, 1000),
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    await ref.set(report);
    return { ok: true };
  } catch (e) {
    console.error('[createMessageReportAction]', e);
    return { ok: false, error: 'Не удалось отправить жалобу' };
  }
}

export async function fetchPendingReportsAction(input: {
  idToken: string;
  statusFilter?: ReportStatus;
}): Promise<{ ok: true; reports: MessageReport[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    let query = adminDb.collection('messageReports').orderBy('createdAt', 'desc').limit(50);
    if (input.statusFilter) {
      query = query.where('status', '==', input.statusFilter);
    }
    const snap = await query.get();
    const reports = snap.docs.map((d) => d.data() as MessageReport);
    return { ok: true, reports };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[fetchPendingReportsAction]', e);
    return { ok: false, error: 'Ошибка загрузки жалоб' };
  }
}

export async function hideMessageAction(input: {
  idToken: string;
  conversationId: string;
  messageId: string;
  reason?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    const hiddenByAdmin: MessageHiddenByAdmin = {
      at: new Date().toISOString(),
      by: actor.uid,
      reason: input.reason,
    };

    await adminDb
      .collection('conversations')
      .doc(input.conversationId)
      .collection('messages')
      .doc(input.messageId)
      .update({ hiddenByAdmin });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.hide_message',
      target: { type: 'message', id: input.messageId },
      details: { conversationId: input.conversationId, reason: input.reason },
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
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    const { FieldValue } = await import('firebase-admin/firestore');
    await adminDb
      .collection('conversations')
      .doc(input.conversationId)
      .collection('messages')
      .doc(input.messageId)
      .update({ hiddenByAdmin: FieldValue.delete() });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.unhide_message',
      target: { type: 'message', id: input.messageId },
      details: { conversationId: input.conversationId },
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
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    await adminDb.collection('messageReports').doc(input.reportId).update({
      status: input.status,
      actionTaken: input.actionTaken ?? 'none',
      reviewedBy: actor.uid,
      reviewedAt: new Date().toISOString(),
    });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'moderation.review_report',
      target: { type: 'message', id: input.reportId },
      details: { status: input.status, actionTaken: input.actionTaken },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[reviewReportAction]', e);
    return { ok: false, error: 'Ошибка обработки жалобы' };
  }
}
