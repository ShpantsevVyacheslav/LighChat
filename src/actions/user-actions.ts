'use server';

import { adminAuth } from '@/firebase/admin';

export async function createUserAction(_data: { email: string; password: string; displayName: string; }) {
    // Эта серверная функция устарела и заменена облачной функцией 'createuser'.
    // Она оставлена, чтобы избежать ошибок импорта, но больше не должна использоваться.
    void _data;
    console.error("DEPRECATED: createUserAction is deprecated. Use the 'createuser' Cloud Function instead.");
    return { uid: null, error: "This server action is deprecated and should not be used." };
}

export async function updateUserPasswordAction(userId: string, newPassword: string): Promise<{ error: string | null }> {
    try {
        await adminAuth.updateUser(userId, {
            password: newPassword,
        });
        return { error: null };
    } catch (error: unknown) {
        console.error("Error updating user password in admin action:", error);
        const message =
          typeof error === 'object' &&
          error != null &&
          'message' in error &&
          typeof (error as { message?: unknown }).message === 'string'
            ? (error as { message: string }).message
            : 'Unknown error';
        return { error: message };
    }
}
