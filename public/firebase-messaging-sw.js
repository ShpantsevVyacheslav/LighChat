importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE",
  projectId: "project-72b24",
  messagingSenderId: "262148817877",
  appId: "1:262148817877:web:d4191fc34eca6977f0335c"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  if (payload.data && !payload.notification) {
    const notificationTitle = payload.data.title || 'Новое сообщение';
    const notificationOptions = {
      body: payload.data.body || '',
      icon: payload.data.icon || '/pwa/icon-192.png',
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
