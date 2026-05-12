/**
 * [audit CR-002] Firebase App Check для web/electron клиента.
 *
 * App Check заставляет каждый запрос к Firebase (Firestore / Storage /
 * Functions / Auth) нести криптографически верифицируемый токен,
 * подтверждающий что запрос идёт из настоящего LighChat-приложения.
 * Заперивает DoS-вектор на 4 pre-auth callable (`requestQrLogin`,
 * `signInWithTelegram`, `confirmQrLogin`, `checkRegistrationKeyAvailable`)
 * и блокирует бот-абуз Firestore/Storage с украденным API key.
 *
 * Provider — **reCAPTCHA Enterprise** (invisible, без CAPTCHA для юзера).
 * SDK молча получает risk-score и обменивает его на App Check token,
 * который автоматически прикрепляется ко всем Firebase-запросам.
 *
 * Rollout стратегия:
 *  - Сейчас Firebase Console в **Monitor mode** — App Check логирует
 *    `verified` / `unverified` метрики, но **не блокирует**. Старые версии
 *    клиента (без этой инициализации) продолжают работать. Запускаем
 *    эту инициализацию в prod, наблюдаем неделю на App Check Metrics
 *    (target ≥95% verified), потом переключаем Console на Enforce.
 *  - Параллельно в `functions/` callable получат `enforceAppCheck: false`
 *    в options — Firebase будет логировать но не reject'ить запросы без
 *    App Check token. На неделе observation сменим на `true`.
 *
 * Debug-токены для local dev:
 *  - В dev SDK выставляет `FIREBASE_APPCHECK_DEBUG_TOKEN = true` —
 *    в DevTools console печатается debug-токен.
 *  - Сохрани токен в Firebase Console → App Check → Web app → ⋮ →
 *    «Manage debug tokens» → Add → вставь.
 *  - После этого dev-сборка получает заверенный токен без real reCAPTCHA.
 */

import { initializeAppCheck, ReCaptchaEnterpriseProvider, type AppCheck } from 'firebase/app-check';
import type { FirebaseApp } from 'firebase/app';
import { logger } from '@/lib/logger';

const RECAPTCHA_ENTERPRISE_SITE_KEY = '6Lc9OuQsAAAAAGgdcyaGqJawglB5wylD0-uu1BH_';

let cached: AppCheck | null = null;

/**
 * Идемпотентная инициализация. На SSR / Node возвращает null. При повторном
 * вызове на том же `app` отдаёт уже созданный экземпляр (Firebase SDK
 * сам бросает ошибку при двойном `initializeAppCheck`).
 */
export function initLighChatAppCheck(app: FirebaseApp): AppCheck | null {
  if (typeof window === 'undefined') return null;
  if (cached) return cached;

  try {
    // Debug-token для NODE_ENV=development. Production билд (App Hosting,
    // electron prod) — не активирует, иначе real reCAPTCHA сработает.
    if (process.env.NODE_ENV === 'development') {
      (self as unknown as { FIREBASE_APPCHECK_DEBUG_TOKEN?: boolean }).FIREBASE_APPCHECK_DEBUG_TOKEN = true;
    }
    cached = initializeAppCheck(app, {
      provider: new ReCaptchaEnterpriseProvider(RECAPTCHA_ENTERPRISE_SITE_KEY),
      // Auto-refresh: SDK сам обновляет токен до истечения 30-минутного TTL.
      // Без него запросы после 30 мин начнут получать deny (после Enforce).
      isTokenAutoRefreshEnabled: true,
    });
    return cached;
  } catch (e) {
    // Не валим инициализацию Firebase если App Check не стартанул —
    // Monitor mode не блокирует, прод не упадёт. Но логируем — заметим
    // регрессию по метрикам в Console.
    logger.warn('app-check', 'init failed', e);
    return null;
  }
}
