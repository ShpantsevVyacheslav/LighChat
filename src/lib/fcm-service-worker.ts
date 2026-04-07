'use client';

/**
 * Один и тот же URL, что в `FirebaseClientProvider`: FCM ожидает SW с инициализацией `firebase-messaging`.
 * См. `public/sw.js`.
 */
export const FCM_SERVICE_WORKER_PATH = '/sw.js';

function isLikelyIosPwa(): boolean {
  if (typeof navigator === 'undefined') return false;
  const ua = navigator.userAgent || '';
  if (/iPad|iPhone|iPod/i.test(ua)) return true;
  const nav = navigator as Navigator & { standalone?: boolean };
  if (nav.standalone === true) return true;
  return false;
}

/** iOS PWA медленно активирует SW; на десктопе достаточно короче. */
export function fcmServiceWorkerReadyTimeoutMs(): number {
  return isLikelyIosPwa() ? 60_000 : 25_000;
}

/**
 * Гарантирует вызов `register` до ожидания `ready`.
 * Раньше SW регистрировался только на `window.load` — онбординг мог жать «разрешить»
 * раньше `load`, и `navigator.serviceWorker.ready` зависал навсегда.
 */
export function isLocalDevHostname(): boolean {
  if (typeof window === 'undefined') return false;
  const host = window.location.hostname;
  return host === 'localhost' || host === '127.0.0.1' || host === '0.0.0.0';
}

export async function ensureFcmServiceWorkerRegistered(): Promise<ServiceWorkerRegistration> {
  if (!('serviceWorker' in navigator)) {
    throw new Error('Service Worker не поддерживается вашим браузером.');
  }
  if (isLocalDevHostname()) {
    throw new Error(
      'Push-уведомления на localhost не включаются (отключена регистрация service worker). Проверьте на HTTPS и в приложении с экрана «Домой».'
    );
  }
  const registration = await navigator.serviceWorker.register(FCM_SERVICE_WORKER_PATH, {
    scope: '/',
  });
  await navigator.serviceWorker.ready;
  return registration;
}
