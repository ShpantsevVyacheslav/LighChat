/// URL **`GET /api/auth/yandex`** на сайте (редирект на Яндекс OAuth).
///
/// Сборка: `--dart-define=YANDEX_OAUTH_START_URL=https://ваш-домен.com/api/auth/yandex`
/// (полный путь, без завершающего `/` в конце домена перед `/api` — можно с trail slash, он убирается).
/// Если не задано — прод `lighchat.online` (как у Telegram-моста).
String yandexOAuthStartUrl() {
  const fromEnv = String.fromEnvironment('YANDEX_OAUTH_START_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/$'), '');
  }
  return 'https://lighchat.online/api/auth/yandex';
}
