// SECURITY: server-only helper. NEVER add 'use server' here — this file is an
// internal implementation detail used by server actions/route handlers. If it
// were exported from a 'use server' file, Next.js would generate a public RPC
// endpoint, allowing any unauthenticated client to write arbitrary entries
// into adminAuditLog and forge "admin actions" attribution.
//
// Callers must already have authenticated/authorized the request before
// invoking logAdminAction. This helper does not perform any auth checks.

import { adminDb } from '@/firebase/admin';
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
