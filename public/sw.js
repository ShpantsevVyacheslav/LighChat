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
  const options = {
    body: payload.data?.body || 'Новое уведомление',
    icon: '/pwa/icon-192.png',
    badge: '/pwa/icon-192.png',
    data: {
      link: payload.data?.link || '/dashboard'
    }
  };

  self.registration.showNotification(title, options);
});

// Обработка клика по уведомлению
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  const targetUrl = event.notification.data?.link || '/dashboard';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Если есть открытое окно с этим URL, фокусируемся на нем
      for (let client of windowClients) {
        if (client.url.includes(targetUrl) && 'focus' in client) {
          return client.focus();
        }
      }
      // Если нет, открываем новое
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
