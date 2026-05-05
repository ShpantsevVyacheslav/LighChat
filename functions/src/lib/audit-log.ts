import * as admin from "firebase-admin";

export type AuditAction =
  | 'user.create'
  | 'user.delete'
  | 'user.block'
  | 'user.unblock'
  | 'user.role.change'
  | 'user.password.reset'
  | 'user.update'
  | 'storage.settings.update'
  | 'storage.quota.user'
  | 'storage.quota.conversation'
  | 'notification.broadcast'
  | 'backfill.run'
  | 'moderation.hide_message'
  | 'moderation.unhide_message'
  | 'moderation.review_report'
  | 'ticket.status_change'
  | 'feature_flag.update'
  | 'announcement.create'
  | 'announcement.update'
  | 'session.terminate';

export async function logAdminActionCF(params: {
  db: admin.firestore.Firestore;
  actorId: string;
  actorName: string;
  action: AuditAction;
  target: { type: 'user' | 'conversation' | 'message' | 'system'; id: string; name?: string };
  details?: Record<string, unknown>;
}): Promise<void> {
  const ref = params.db.collection('adminAuditLog').doc();
  await ref.set({
    id: ref.id,
    actorId: params.actorId,
    actorName: params.actorName,
    action: params.action,
    target: params.target,
    details: params.details ?? null,
    createdAt: new Date().toISOString(),
  });
}
