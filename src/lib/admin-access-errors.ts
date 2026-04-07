/**
 * Расшифровка ошибок проверки админа (Firebase Admin verifyIdToken и т.д.).
 * Не в файле с «use server» — иначе Next требует async у всех экспортов.
 */
export function interpretAdminAccessError(e: unknown): string {
  if (e instanceof Error) {
    if (e.message === 'FORBIDDEN' || e.message === 'UNAUTHORIZED') {
      return 'Недостаточно прав';
    }
  }

  console.error('[Firebase Admin] проверка доступа:', e);

  const rec = e as { code?: string; message?: string };
  const code = String(rec?.code ?? '');
  const msg = (rec?.message ?? '').toLowerCase();

  if (
    code === 'auth/id-token-expired' ||
    code === 'auth/argument-error' ||
    code === 'auth/invalid-id-token' ||
    msg.includes('id token') ||
    msg.includes('token has expired')
  ) {
    return 'Сессия устарела. Обновите страницу или войдите снова.';
  }

  if (
    code.includes('credential') ||
    code === 'app/no-app' ||
    msg.includes('could not load the default credentials') ||
    msg.includes('application default credentials') ||
    msg.includes('credential implementation provided to initializeapp') ||
    msg.includes('service account')
  ) {
    return 'Сервер не может вызвать Firebase Admin (нет ключей). Локально: файл сервисного аккаунта и GOOGLE_APPLICATION_CREDENTIALS или gcloud auth application-default login. Детали ошибки — в терминале, где запущен Next.js.';
  }

  return 'Не удалось проверить права на сервере. Смотрите стек в терминале Next.js (npm run dev).';
}
