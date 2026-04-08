/**
 * Текст ошибки подписки FCM (getToken) для UI и логов.
 * @see docs/troubleshooting-fcm-web.md
 */
export function fcmSubscribeUserMessage(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err);
  const code =
    err && typeof err === 'object' && 'code' in err
      ? String((err as { code: unknown }).code)
      : '';

  if (/Can't find variable: Notification|Notification is not defined/i.test(raw)) {
    return (
      'Push в этом окне недоступен. На iPhone откройте установленное приложение с экрана «Домой». ' +
      'В обычной вкладке Safari web-push может быть недоступен.'
    );
  }

  if (code === 'messaging/unsupported-browser') {
    return (
      'Push не поддерживается в текущем окружении браузера. ' +
      'Используйте актуальный браузер или установленное PWA-приложение на iPhone.'
    );
  }

  const credentialHint =
    /Expected OAuth 2 access token|missing required authentication credential|Request is missing required authentication credential/i.test(
      raw
    );

  if (
    credentialHint ||
    (code === 'messaging/token-subscribe-failed' && /credential|OAuth|UNAUTHENTICATED/i.test(raw))
  ) {
    return (
      'FCM: Google отклонил запрос (нет действующих учётных данных для API-ключа в браузере). ' +
      'Чаще всего у Browser API key в Google Cloud не указан referrer для вашего домена или жёстко ограничены API. ' +
      'Настройте ключ по инструкции в docs/troubleshooting-fcm-web.md'
    );
  }

  return raw;
}
