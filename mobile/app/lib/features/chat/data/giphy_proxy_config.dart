/// Базовый URL веб-приложения LighChat (без завершающего `/`), где доступен
/// прокси `GET /api/giphy/search?q=…` (см. `src/app/api/giphy/search/route.ts`).
///
/// Прокси нужен, чтобы не хранить GIPHY API key на клиенте.
///
/// По умолчанию указывает на production-хост. Для локальной разработки
/// можно переопределить:
/// `--dart-define=GIPHY_PROXY_BASE_URL=http://192.168.X.X:9002`
const String kGiphyProxyBaseUrl = String.fromEnvironment(
  'GIPHY_PROXY_BASE_URL',
  defaultValue: 'https://lighchat.online',
);
