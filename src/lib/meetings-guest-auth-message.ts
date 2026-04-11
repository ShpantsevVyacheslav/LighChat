/**
 * Тексты для гостевого входа на `/meetings/[id]` (signInAnonymously).
 */

export function guestMeetingAuthToastDescription(err: { code?: string; message?: string }): string {
  const code = err.code ?? '';
  if (code === 'auth/operation-not-allowed' || code === 'auth/admin-restricted-operation') {
    return 'Включите Anonymous в Firebase и проверьте App Check (см. подсказки на экране).';
  }
  return err.message || 'Проверьте сеть и попробуйте снова.';
}

export function guestMeetingAuthScreenBullets(code: string | null): string[] {
  if (code === 'auth/operation-not-allowed' || code === 'auth/admin-restricted-operation') {
    return [
      'Firebase Console → Authentication → Sign-in method → включите «Anonymous» и сохраните.',
      'Authentication → Settings → Authorized domains: добавьте ваш домен (например lighchat.online).',
      'Если в проекте включён App Check с enforcement для Identity / Auth: добавьте веб-приложение в App Check или временно отключите enforcement для отладки.',
      'Google Cloud → APIs: должен быть включён Identity Toolkit API; Browser API key не должен блокировать identitytoolkit (см. docs/troubleshooting-firebase-web-api-key.md).',
    ];
  }
  return [
    'Проверьте соединение и откройте ссылку снова.',
    'Если ошибка повторяется — смотрите код в консоли разработчика и docs/troubleshooting-meetings-guest-auth.md.',
  ];
}
