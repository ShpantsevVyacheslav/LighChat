'use server';

import { adminAuth, adminDb } from '@/firebase/admin';
import { logAdminAction } from '@/actions/audit-log-actions';

export async function assertAdminByIdToken(idToken: string): Promise<{ uid: string; name: string }> {
  if (!idToken?.trim()) throw new Error('UNAUTHORIZED');
  const decoded = await adminAuth.verifyIdToken(idToken);
  const snap = await adminDb.collection('users').doc(decoded.uid).get();
  const data = snap.data();
  if (data?.role !== 'admin') throw new Error('FORBIDDEN');
  return { uid: decoded.uid, name: data?.name ?? 'Admin' };
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
