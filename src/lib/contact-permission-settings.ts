/**
 * Открытие системных настроек для доступа к контактам из веб-приложения.
 *
 * - **iOS / Safari / PWA «На экран Домой»:** прямой deep link в «Настройки» для сторонних сайтов
 *   недоступен (Apple не разрешает). Пользователю показывают пошаговую инструкцию.
 * - **Android (Chrome и др.):** часто срабатывает intent на карточку приложения браузера,
 *   где можно открыть «Разрешения» → «Контакты».
 */

function isAndroid(): boolean {
  if (typeof navigator === 'undefined') return false;
  return /Android/i.test(navigator.userAgent);
}

/** Пакет браузера для экрана «О приложении» в настройках Android. */
function resolveAndroidBrowserPackage(): string {
  if (typeof navigator === 'undefined') return 'com.android.chrome';
  const ua = navigator.userAgent;
  if (/SamsungBrowser/i.test(ua)) return 'com.sec.android.app.sbrowser';
  if (/Firefox/i.test(ua)) return 'org.mozilla.firefox';
  if (/EdgA/i.test(ua)) return 'com.microsoft.emmx';
  return 'com.android.chrome';
}

/**
 * Пытается открыть системный экран сведений о приложении браузера (дальше: Разрешения → Контакты).
 * @returns true, если выполнен переход intent (на iOS всегда false).
 */
export function tryOpenAndroidBrowserApplicationSettings(): boolean {
  if (typeof window === 'undefined' || !isAndroid()) return false;
  const pkg = resolveAndroidBrowserPackage();
  try {
    const url = `intent://#Intent;action=android.settings.APPLICATION_DETAILS_SETTINGS;data=package:${pkg};end`;
    window.location.href = url;
    return true;
  } catch {
    return false;
  }
}

export function shouldOfferAndroidSettingsButton(): boolean {
  return isAndroid();
}
