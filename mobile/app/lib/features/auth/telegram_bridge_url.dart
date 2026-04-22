/// Базовый URL сайта с маршрутом [`/auth/telegram`](/auth/telegram) для WebView (параметр `mobile=1`).
///
/// Сборка: `--dart-define=TELEGRAM_AUTH_BRIDGE_URL=https://ваш-домен.com`
/// (без завершающего `/`). Если не задано — используется production-домен по умолчанию.
String telegramAuthBridgePageUrl() {
  const fromEnv = String.fromEnvironment('TELEGRAM_AUTH_BRIDGE_URL');
  if (fromEnv.isNotEmpty) {
    final base = fromEnv.replaceAll(RegExp(r'/$'), '');
    return '$base/auth/telegram?mobile=1';
  }
  return 'https://lighchat.app/auth/telegram?mobile=1';
}
