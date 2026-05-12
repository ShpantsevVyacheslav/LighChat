'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken, verifyUserByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/lib/server/audit-log';
import type { SupportTicket, SupportTicketMessage, TicketStatus } from '@/lib/types';
import { logger } from '@/lib/logger';

/**
 * SECURITY: identity now comes from idToken, not client-supplied userId/
 * userName/userEmail. Without this, anyone could open tickets under any
 * other user's identity (e.g. for social-engineering attacks against
 * support staff or to flood the queue from spoofed accounts). Subject,
 * message, category, priority remain client-controlled and length-capped.
 */
const SUBJECT_MAX = 200;
const MESSAGE_MAX = 4000;

export async function createSupportTicketAction(input: {
  idToken: string;
  subject: string;
  category: SupportTicket['category'];
  priority: SupportTicket['priority'];
  message: string;
}): Promise<{ ok: true; ticketId: string } | { ok: false; error: string }> {
  try {
    const reporter = await verifyUserByIdToken(input.idToken);
    const subject = (input.subject ?? '').toString().trim().slice(0, SUBJECT_MAX);
    const message = (input.message ?? '').toString().trim().slice(0, MESSAGE_MAX);
    if (!subject || !message) return { ok: false, error: 'Заполните тему и сообщение' };

    const ref = adminDb.collection('supportTickets').doc();
    const now = new Date().toISOString();

    const ticket: SupportTicket = {
      id: ref.id,
      userId: reporter.uid,
      userName: reporter.name,
      userEmail: reporter.email,
      subject,
      status: 'open',
      priority: input.priority,
      category: input.category,
      createdAt: now,
      updatedAt: now,
    };
    await ref.set(ticket);

    const msgRef = ref.collection('messages').doc();
    const msg: SupportTicketMessage = {
      id: msgRef.id,
      senderId: reporter.uid,
      senderName: reporter.name,
      senderRole: 'user',
      text: message,
      createdAt: now,
    };
    await msgRef.set(msg);

    return { ok: true, ticketId: ref.id };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'UNAUTHORIZED') return { ok: false, error: 'Требуется вход' };
    if (msg === 'BLOCKED') return { ok: false, error: 'Аккаунт заблокирован' };
    logger.error('support', 'createSupportTicketAction', e);
    return { ok: false, error: 'Не удалось создать обращение' };
  }
}

const TICKET_PAGE_SIZE = 50;
const TICKET_PAGE_SIZE_MAX = 100;

export async function fetchSupportTicketsAction(input: {
  idToken: string;
  statusFilter?: TicketStatus;
  cursor?: string;
  pageSize?: number;
}): Promise<
  | { ok: true; tickets: SupportTicket[]; nextCursor: string | null }
  | { ok: false; error: string }
> {
  try {
    await assertAdminByIdToken(input.idToken);

    const size = Math.min(
      Math.max(1, Math.floor(input.pageSize ?? TICKET_PAGE_SIZE)),
      TICKET_PAGE_SIZE_MAX,
    );

    let query: FirebaseFirestore.Query = adminDb
      .collection('supportTickets')
      .orderBy('createdAt', 'desc');
    if (input.statusFilter) {
      query = query.where('status', '==', input.statusFilter);
    }
    query = query.limit(size);
    if (input.cursor) {
      const startSnap = await adminDb.collection('supportTickets').doc(input.cursor).get();
      if (startSnap.exists) {
        query = query.startAfter(startSnap);
      }
    }

    const snap = await query.get();
    const tickets = snap.docs.map((d) => d.data() as SupportTicket);
    const nextCursor =
      snap.docs.length === size ? snap.docs[snap.docs.length - 1].id : null;
    return { ok: true, tickets, nextCursor };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('support', 'fetchSupportTicketsAction', e);
    return { ok: false, error: 'Ошибка загрузки обращений' };
  }
}

export async function fetchTicketMessagesAction(input: {
  idToken: string;
  ticketId: string;
}): Promise<{ ok: true; messages: SupportTicketMessage[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const snap = await adminDb
      .collection('supportTickets')
      .doc(input.ticketId)
      .collection('messages')
      .orderBy('createdAt', 'asc')
      .get();
    const messages = snap.docs.map((d) => d.data() as SupportTicketMessage);
    return { ok: true, messages };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('support', 'fetchTicketMessagesAction', e);
    return { ok: false, error: 'Ошибка загрузки сообщений' };
  }
}

export async function replyToTicketAction(input: {
  idToken: string;
  ticketId: string;
  text: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);
    const now = new Date().toISOString();

    const msgRef = adminDb.collection('supportTickets').doc(input.ticketId).collection('messages').doc();
    const msg: SupportTicketMessage = {
      id: msgRef.id,
      senderId: actor.uid,
      senderName: actor.name,
      senderRole: 'admin',
      text: input.text,
      createdAt: now,
    };
    await msgRef.set(msg);

    await adminDb.collection('supportTickets').doc(input.ticketId).update({
      updatedAt: now,
      status: 'in_progress',
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('support', 'replyToTicketAction', e);
    return { ok: false, error: 'Ошибка отправки ответа' };
  }
}

export async function updateTicketStatusAction(input: {
  idToken: string;
  ticketId: string;
  status: TicketStatus;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);
    const now = new Date().toISOString();

    const update: Record<string, unknown> = { status: input.status, updatedAt: now };
    if (input.status === 'resolved' || input.status === 'closed') {
      update.resolvedAt = now;
    }
    await adminDb.collection('supportTickets').doc(input.ticketId).update(update);

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'ticket.status_change',
      target: { type: 'system', id: input.ticketId },
      details: { newStatus: input.status },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('support', 'updateTicketStatusAction', e);
    return { ok: false, error: 'Ошибка обновления статуса' };
  }
}
