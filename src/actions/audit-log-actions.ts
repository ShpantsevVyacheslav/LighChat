'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import type { AuditAction, AuditLogEntry } from '@/lib/types';

// SECURITY: logAdminAction was previously exported from this 'use server' file,
// which made it a publicly-callable RPC endpoint. Any unauthenticated client
// could forge audit log entries (impersonate "admin X did Y" or flood the log
// to hide real admin actions). It now lives in '@/lib/server/audit-log' as an
// internal helper. Server actions must import it from there.

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
