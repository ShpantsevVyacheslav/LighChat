// Firebase Service Worker для LighChat
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Конфигурация для работы FCM в фоновом режиме
firebase.initializeApp({
  apiKey: "AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE",
  authDomain: "project-72b24.firebaseapp.com",
  projectId: "project-72b24",
  storageBucket: "project-72b24.firebasestorage.app",
  messagingSenderId: "262148817877",
  appId: "1:262148817877:web:d4191fc34eca6977f0335c"
});

const messaging = firebase.messaging();

/**
 * SECURITY: notification "link" arrives via FCM data and is passed to
 * clients.openWindow(). Without validation, anyone able to deliver a push
 * could open an arbitrary external URL on tap (phishing). Restrict to
 * same-origin internal paths only.
 */
function safeNotificationLink(raw) {
  const fallback = '/dashboard';
  if (typeof raw !== 'string') return fallback;
  const v = raw.trim();
  if (!v.startsWith('/')) return fallback;
  if (v.startsWith('//') || v.startsWith('/\\')) return fallback;
  if (v.indexOf('..') !== -1) return fallback;
  for (var i = 0; i < v.length; i++) {
    var c = v.charCodeAt(i);
    if (c < 0x20 || c === 0x7f) return fallback;
  }
  return v;
}

/** Абсолютный URL: Safari/macOS часто не подхватывает относительный icon для web-push. */
function pushIconUrl(payload) {
  const origin = self.location.origin;
  const fallback = origin + '/pwa/icon-192.png';
  const raw = payload.data && payload.data.icon;
  if (typeof raw === 'string' && raw.length > 0) {
    if (raw.startsWith('https://') || raw.startsWith('http://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return origin + raw;
    }
  }
  return fallback;
}

// Принудительная активация новой версии воркера
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});

// Обработка уведомлений, когда приложение закрыто или в фоне
messaging.onBackgroundMessage((payload) => {
  console.log('[sw.js] Received background message ', payload);
  
  const title = payload.data?.title || 'LighChat';
  const iconUrl = pushIconUrl(payload);
  const options = {
    body: payload.data?.body || 'Новое уведомление',
    icon: iconUrl,
    badge: iconUrl,
    data: {
      link: safeNotificationLink(payload.data?.link)
    }
  };

  self.registration.showNotification(title, options);
});

// Обработка клика по уведомлению
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  // SECURITY: re-validate even if the stored link was sanitized at receive
  // time — defends against stale notifications created before SW upgrade.
  const targetUrl = safeNotificationLink(event.notification.data?.link);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Если есть открытое окно с этим URL, фокусируемся на нем
      for (let client of windowClients) {
        if (client.url.includes(targetUrl) && 'focus' in client) {
          return client.focus();
        }
      }
      // Если нет, открываем новое (relative URL → same-origin guarantee)
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
