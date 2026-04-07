/**
 * Нужно ли принудительно использовать long polling вместо WebChannel/Fetch-стриминга к Firestore.
 *
 * **Почему:** WebKit (Safari на macOS и iOS, PWA, все браузеры на iOS) нередко рвёт или блокирует
 * соединения Firestore (`…/Write/channel`, `Listen/channel`) с сообщением в консоли вроде
 * «Fetch API cannot load … due to **access control checks**». Это не ваши Firestore rules и не CORS
 * на вашем домене — ограничения/баги цепочки Fetch + стриминг + cross-origin к `googleapis.com`.
 * Long polling идёт короткими запросами и обычно стабилен на WebKit.
 *
 * @see https://github.com/firebase/firebase-js-sdk/issues/1674
 * @see https://firebase.google.com/docs/firestore/manage-databases#safari_and_firestore
 */
export function shouldForceFirestoreLongPolling(): boolean {
  if (typeof navigator === 'undefined') return false;
  const ua = navigator.userAgent || '';

  /** Нативный WebKit на телефонах/планшетах Apple */
  if (/iPad|iPhone|iPod/i.test(ua)) return true;

  /** iPadOS 13+ может идентифицироваться как Mac + touch */
  if (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1) return true;

  /**
   * Добавлено на «Домой» (PWA) в iOS: всегда WebKit, иногда UA бывает урезанным.
   * @see https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariHTMLScripting/Tasks/ManagingstanDBrowserBehavior.html
   */
  const nav = navigator as Navigator & { standalone?: boolean };
  if (nav.standalone === true) return true;

  /**
   * Chrome / Edge / Firefox / Opera на iOS — тот же WebKit; редкий UA без подстроки «iPhone».
   */
  if (/CriOS|FxiOS|EdgiOS|OPiOS/i.test(ua)) return true;

  /**
   * Safari на macOS (и в целом движок Safari, а не Chromium).
   * В UA есть «Safari»; у Chrome/Edge/Brave/Vivaldi тоже есть «Safari» как подстрока WebKit,
   * поэтому отсекаем типичные Chromium-браузеры.
   */
  const isLikelyDesktopSafari =
    /Safari/i.test(ua) &&
    !/Chrome|Chromium|CriOS|Edg|EdgiOS|OPR|OPiOS|Brave|Vivaldi|FxiOS/i.test(ua);

  if (isLikelyDesktopSafari) return true;

  return false;
}
