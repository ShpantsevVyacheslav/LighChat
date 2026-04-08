# 05: Integrations

## Firebase (основная платформа)

- Auth: login/register/social auth, соответствие `users/{uid}`.
- Firestore: realtime-данные (чаты, звонки, встречи, индексы).
- Storage: медиа/вложения/аватары/фоновые ресурсы.
- Cloud Functions (v2): auth/firestore/http/scheduler automation.
- FCM: data-push для уведомлений и входящих звонков.
- Web push подписка на клиентах зависит от корректных ограничений Browser API key (referrer + API restrictions) и контекста запуска (на iOS — установленное Home Screen PWA).
- Hosting: публикация web-приложения.

### Cloud Functions surface (ключевые вызовы)

- Callable HTTP: `createNewUser`, `updateUserAdmin`, `backfillConversationMembers`, `backfillRegistrationIndex`, `requestMeetingAccess`, `respondToMeetingRequest`, `checkGroupInvitesAllowed`.
- Firestore triggers: `onconversationcreated`, `onconversationupdated`, `onconversationdeleted`, `onmessagecreated`, `onthreadmessagecreated`, `oncallcreated`, `onmeetingparticipantcreated`, `onuserwritesyncregistrationindex`.
- Auth trigger: `onUserCreated`.
- Scheduler: `checkUserPresence`.

## Tenor API

- Точка: `src/app/api/tenor/search/route.ts`.
- Назначение: серверный прокси к Tenor search API v2.
- ENV: `TENOR_API_KEY`.

## WebRTC stack

- Библиотека: `simple-peer`.
- Канал сигналинга: Firestore (`calls/*`, `meetings/*/signals`).
- Контексты использования: 1:1 calls и meetings.

## Google Maps (геолокация в чате)

- Превью в ленте: Static Maps API при наличии `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` (`src/lib/google-maps.ts`).
- Полная карта **внутри приложения**: iframe по `buildGoogleMapsEmbedUrl` в `SharedLocationMapDialog` и в `LiveLocationMapDialog` (без ухода со страницы). Внешний браузер — опционально через кнопку «Открыть в браузере».

## Media/UX вспомогательные интеграции

- MediaPipe selfie segmentation - виртуальные фоны/обработка видео.
- Open Graph scraper - server-side превью ссылок.

## Desktop and PWA

- Electron: `electron/main.js`, `electron/preload.js`.
- PWA: `public/manifest.json`, иконки в `public/pwa/*`, app icon в `src/app/icon.png`.

## Конфиги и деплой

- `firebase.json`, `.firebaserc` - окружение и deploy-таргеты.
- `firestore.indexes.json` - индексы запросов Firestore.
- `firestore.rules` + `src/firestore.rules` - единая модель безопасности.
- `storage.rules` - правила доступа к файлам.
