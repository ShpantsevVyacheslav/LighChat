'use server';

import { adminAuth, adminDb } from '@/firebase/admin';

export async function assertAdminByIdToken(idToken: string): Promise<void> {
  if (!idToken?.trim()) throw new Error('UNAUTHORIZED');
  const decoded = await adminAuth.verifyIdToken(idToken);
  const snap = await adminDb.collection('users').doc(decoded.uid).get();
  if (snap.data()?.role !== 'admin') throw new Error('FORBIDDEN');
}

/**
 * Сброс пароля Firebase Auth для пользователя (только platform admin).
 * Клиент передаёт свежий ID token текущего администратора.
 */
export async function adminSetUserPasswordAction(input: {
  idToken: string;
  targetUserId: string;
  newPassword: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const pwd = input.newPassword?.trim() ?? '';
    if (pwd.length < 8) {
      return { ok: false, error: 'Пароль не короче 8 символов' };
    }
    await assertAdminByIdToken(input.idToken);
    await adminAuth.updateUser(input.targetUserId, { password: pwd });
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
