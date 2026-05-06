'use server';

import { adminAuth, adminDb } from '@/firebase/admin';
import { logAdminAction } from '@/lib/server/audit-log';

export async function assertAdminByIdToken(idToken: string): Promise<{ uid: string; name: string }> {
  if (!idToken?.trim()) throw new Error('UNAUTHORIZED');
  const decoded = await adminAuth.verifyIdToken(idToken);
  const snap = await adminDb.collection('users').doc(decoded.uid).get();
  const data = snap.data();
  if (data?.role !== 'admin') throw new Error('FORBIDDEN');
  return { uid: decoded.uid, name: data?.name ?? 'Admin' };
}

/**
 * SECURITY: helper for non-admin server actions that need to know WHO the
 * caller is. Server actions previously took `userId`/`reporterId` as a plain
 * argument and trusted the client — anyone could submit a report or open a
 * support ticket *as someone else* (impersonation). This helper validates
 * a Firebase ID token and returns the trusted identity from server-side
 * profile data; the caller MUST use the returned values, not whatever the
 * client claimed.
 *
 * Throws 'UNAUTHORIZED' if the token is missing/invalid, 'BLOCKED' if the
 * account is soft-deleted or under accountBlock.
 */
export async function verifyUserByIdToken(idToken: string): Promise<{
  uid: string;
  name: string;
  email: string;
}> {
  if (!idToken?.trim()) throw new Error('UNAUTHORIZED');
  const decoded = await adminAuth.verifyIdToken(idToken);
  const snap = await adminDb.collection('users').doc(decoded.uid).get();
  const data = snap.data();
  if (!data) throw new Error('UNAUTHORIZED');
  if (data.deletedAt) throw new Error('BLOCKED');
  if (data.accountBlock && typeof data.accountBlock === 'object') throw new Error('BLOCKED');
  return {
    uid: decoded.uid,
    name: typeof data.name === 'string' && data.name ? data.name : 'User',
    email: typeof data.email === 'string' ? data.email : (decoded.email ?? ''),
  };
}

/**
 * Сброс пароля Firebase Auth для пользователя (только platform admin).
 * Клиент передаёт свежий ID token текущего администратора.
 */
export async function adminSetUserPasswordAction(input: {
  idToken: string;
  targetUserId: string;
  targetUserName?: string;
  newPassword: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const pwd = input.newPassword?.trim() ?? '';
    if (pwd.length < 8) {
      return { ok: false, error: 'Пароль не короче 8 символов' };
    }
    const actor = await assertAdminByIdToken(input.idToken);
    await adminAuth.updateUser(input.targetUserId, { password: pwd });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'user.password.reset',
      target: { type: 'user', id: input.targetUserId, name: input.targetUserName },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') {
      return { ok: false, error: 'Недостаточно прав' };
    }
    console.error('[adminSetUserPasswordAction]', e);
    return { ok: false, error: 'Не удалось сменить пароль' };
  }
}
