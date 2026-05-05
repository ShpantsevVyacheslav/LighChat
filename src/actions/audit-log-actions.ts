'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import type { AuditAction, AuditLogEntry } from '@/lib/types';

export async function logAdminAction(params: {
  actorId: string;
  actorName: string;
  action: AuditAction;
  target: AuditLogEntry['target'];
  details?: Record<string, unknown>;
}): Promise<void> {
  const ref = adminDb.collection('adminAuditLog').doc();
  const entry: AuditLogEntry = {
    id: ref.id,
    actorId: params.actorId,
    actorName: params.actorName,
    action: params.action,
    target: params.target,
    details: params.details,
    createdAt: new Date().toISOString(),
  };
  await ref.set(entry);
}

export async function fetchAuditLogAction(input: {
  idToken: string;
  limit?: number;
  startAfter?: string;
  actionFilter?: AuditAction;
  actorFilter?: string;
}): Promise<{ ok: true; entries: AuditLogEntry[]; hasMore: boolean } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    const pageSize = input.limit ?? 25;
    let query = adminDb
      .collection('adminAuditLog')
      .orderBy('createdAt', 'desc')
      .limit(pageSize + 1);

    if (input.actionFilter) {
      query = query.where('action', '==', input.actionFilter);
    }
    if (input.actorFilter) {
      query = query.where('actorId', '==', input.actorFilter);
    }
    if (input.startAfter) {
      query = query.startAfter(input.startAfter);
    }

    const snapshot = await query.get();
    const entries: AuditLogEntry[] = [];
    snapshot.docs.slice(0, pageSize).forEach((doc) => {
      entries.push(doc.data() as AuditLogEntry);
    });

    return { ok: true, entries, hasMore: snapshot.docs.length > pageSize };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') {
      return { ok: false, error: 'Недостаточно прав' };
    }
    console.error('[fetchAuditLogAction]', e);
    return { ok: false, error: 'Ошибка загрузки журнала' };
  }
}
