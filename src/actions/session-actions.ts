'use server';

import { adminAuth, adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/actions/audit-log-actions';

export type DeviceSession = {
  deviceId: string;
  platform?: string;
  app?: string;
  isActive?: boolean;
  lastSeenAt?: string;
  lastLoginAt?: string;
  userAgent?: string;
};

export async function fetchUserSessionsAction(input: {
  idToken: string;
  targetUserId: string;
}): Promise<{ ok: true; sessions: DeviceSession[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const snap = await adminDb
      .collection('users')
      .doc(input.targetUserId)
      .collection('devices')
      .get();
    const sessions = snap.docs.map((d) => ({ deviceId: d.id, ...d.data() }) as DeviceSession);
    return { ok: true, sessions };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[fetchUserSessionsAction]', e);
    return { ok: false, error: 'Ошибка загрузки сессий' };
  }
}

export async function terminateUserSessionsAction(input: {
  idToken: string;
  targetUserId: string;
  targetUserName?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    await adminAuth.revokeRefreshTokens(input.targetUserId);

    const devicesSnap = await adminDb
      .collection('users')
      .doc(input.targetUserId)
      .collection('devices')
      .get();
    const batch = adminDb.batch();
    devicesSnap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'session.terminate',
      target: { type: 'user', id: input.targetUserId, name: input.targetUserName },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[terminateUserSessionsAction]', e);
    return { ok: false, error: 'Ошибка завершения сессий' };
  }
}
