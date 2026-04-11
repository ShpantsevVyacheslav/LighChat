importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE",
  projectId: "project-72b24",
  messagingSenderId: "262148817877",
  appId: "1:262148817877:web:d4191fc34eca6977f0335c"
});

const messaging = firebase.messaging();

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
        link: payload.data.link || '/dashboard'
      }
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const link = event.notification.data?.link || '/dashboard';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(link) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(link);
      }
    })
  );
});
