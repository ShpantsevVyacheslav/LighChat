/// Базовый URL веб-приложения LighChat (без завершающего `/`), где доступен прокси
/// `GET /api/tenor/search?q=…` (см. `src/app/api/tenor/search/route.ts`).
///
/// Сборка: `--dart-define=TENOR_PROXY_BASE_URL=https://your-lighchat-host`
const String kTenorProxyBaseUrl = String.fromEnvironment(
  'TENOR_PROXY_BASE_URL',
  defaultValue: '',
);
