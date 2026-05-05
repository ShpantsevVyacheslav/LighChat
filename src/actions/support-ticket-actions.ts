'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/actions/audit-log-actions';
import type { SupportTicket, SupportTicketMessage, TicketStatus } from '@/lib/types';

export async function createSupportTicketAction(input: {
  userId: string;
  userName: string;
  userEmail: string;
  subject: string;
  category: SupportTicket['category'];
  priority: SupportTicket['priority'];
  message: string;
}): Promise<{ ok: true; ticketId: string } | { ok: false; error: string }> {
  try {
    const ref = adminDb.collection('supportTickets').doc();
    const now = new Date().toISOString();

    const ticket: SupportTicket = {
      id: ref.id,
      userId: input.userId,
      userName: input.userName,
      userEmail: input.userEmail,
      subject: input.subject,
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
      senderId: input.userId,
      senderName: input.userName,
      senderRole: 'user',
      text: input.message,
      createdAt: now,
    };
    await msgRef.set(msg);

    return { ok: true, ticketId: ref.id };
  } catch (e) {
    console.error('[createSupportTicketAction]', e);
    return { ok: false, error: 'Не удалось создать обращение' };
  }
}

export async function fetchSupportTicketsAction(input: {
  idToken: string;
  statusFilter?: TicketStatus;
}): Promise<{ ok: true; tickets: SupportTicket[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    let query = adminDb.collection('supportTickets').orderBy('createdAt', 'desc').limit(100);
    if (input.statusFilter) {
      query = query.where('status', '==', input.statusFilter);
    }
    const snap = await query.get();
    const tickets = snap.docs.map((d) => d.data() as SupportTicket);
    return { ok: true, tickets };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[fetchSupportTicketsAction]', e);
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
    console.error('[fetchTicketMessagesAction]', e);
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
    console.error('[replyToTicketAction]', e);
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
    console.error('[updateTicketStatusAction]', e);
    return { ok: false, error: 'Ошибка обновления статуса' };
  }
}
