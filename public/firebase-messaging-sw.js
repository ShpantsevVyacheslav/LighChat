importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE",
  projectId: "project-72b24",
  messagingSenderId: "262148817877",
  appId: "1:262148817877:web:d4191fc34eca6977f0335c"
});

const messaging = firebase.messaging();

/**
 * SECURITY: notification "link" arrives via FCM data and is passed to
 * clients.openWindow(). Without validation, anyone able to deliver a push
 * (including via a server action that misses an auth check) could open an
 * arbitrary external URL on tap — phishing vector. Restrict to internal,
 * absolute paths only.
 */
function safeNotificationLink(raw) {
  const fallback = '/dashboard';
  if (typeof raw !== 'string') return fallback;
  const v = raw.trim();
  if (!v.startsWith('/')) return fallback;
  if (v.startsWith('//') || v.startsWith('/\\')) return fallback;
  if (v.indexOf('..') !== -1) return fallback;
  // Reject control characters and DEL — defense in depth against URL smuggling.
  for (var i = 0; i < v.length; i++) {
    var c = v.charCodeAt(i);
    if (c < 0x20 || c === 0x7f) return fallback;
  }
  return v;
}

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

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  if (payload.data && !payload.notification) {
    const notificationTitle = payload.data.title || 'Новое сообщение';
    const iconUrl = pushIconUrl(payload);
    const silent = payload.data.silent === '1' || payload.data.silent === 'true';
    const notificationOptions = {
      body: payload.data.body || '',
      icon: iconUrl,
      badge: iconUrl,
      silent: silent === true,
      data: {
        link: safeNotificationLink(payload.data.link)
      }
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  // Re-validate at click time as well: even if a stale notification was created
  // before the SW upgrade, the open MUST be same-origin.
  const link = safeNotificationLink(event.notification.data?.link);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(link) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        // openWindow with a relative URL resolves against the SW scope,
        // guaranteeing same-origin navigation.
        return clients.openWindow(link);
      }
    })
  );
});
