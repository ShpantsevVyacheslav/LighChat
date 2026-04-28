# 05: Integrations

## Firebase (основная платформа)

- Auth: login/register/social auth, соответствие `users/{uid}`.
- Firestore: realtime-данные (чаты, звонки, встречи, индексы).
  - **TTL исчезающих сообщений:** после деплоя CF включите в консоли Firestore (или gcloud) политику TTL на поле **`expireAt`** для групп коллекций:
    - `conversations/{conversationId}/messages/{messageId}`
    - `conversations/{conversationId}/messages/{messageId}/thread/{threadMessageId}`  
    Имя поля должно совпадать с тем, что пишут функции (`expireAt`, тип Timestamp). Без политики TTL документы с `expireAt` не удаляются автоматически.
- Storage: медиа/вложения/аватары/фоновые ресурсы.
- Cloud Functions (v2): auth/firestore/http/scheduler automation.
- FCM: data-push для уведомлений и входящих звонков (Android/Web и fallback).
  - Call payload (trigger `oncallcreated`) включает `callId`, `callerId`, `callerName`, `isVideo` (в `data`) и используется mobile-клиентом для native incoming-call UX.
- APNs VoIP (iOS): trigger `oncallcreated` отправляет VoIP push напрямую в APNs HTTP/2 (`api.push.apple.com` / `api.sandbox.push.apple.com`) с JWT ES256 (`.p8`), `apns-topic: <bundleId>.voip` и payload для `flutter_callkit_incoming`.
- Web push подписка на клиентах зависит от корректных ограничений Browser API key (referrer + API restrictions) и контекста запуска (на iOS — установленное Home Screen PWA).
- Hosting: публикация web-приложения.

### Cloud Functions surface (ключевые вызовы)

- Callable HTTP: `createNewUser`, `updateUserAdmin`, `backfillConversationMembers`, `backfillRegistrationIndex`, `requestMeetingAccess`, `respondToMeetingRequest`, `checkGroupInvitesAllowed`, `retryChatMediaTranscode`, `transcribeVoiceMessage`.
  - **Secret chat:** `setSecretChatPin` (установить/сменить PIN), `unlockSecretChat` (выдать временный unlock‑grant `secretAccess/{uid}`), scheduler `cleanupExpiredSecretChats` (каждые 5 минут удаляет истёкшие секретные чаты и связанные файлы в Storage).
  - **iOS-обход для `checkGroupInvitesAllowed`:** мобильный клиент (`mobile/packages/lighchat_firebase/lib/src/firebase_callable_http.dart`) на iOS вызывает функцию прямым `POST https://us-central1-{projectId}.cloudfunctions.net/checkGroupInvitesAllowed` с `Authorization: Bearer <idToken>`, минуя плагин `cloud_functions`. Причина — SDK `FirebaseFunctions` 12.9.0 в `FunctionsContext.context(options:)` использует три параллельных `async let`, на которых Swift-рантайм iOS крашит Release-процесс в `_swift_task_dealloc_specific (.cold.2)` (SIGABRT, «freed pointer was not the last allocation»). Контракт ответа (`{result: …}` / `{error: {status,message}}`) и семантика ошибок сохранены; Android/Web идут штатно через `cloud_functions`.
- **Voice transcription (чат):** callable `transcribeVoiceMessage` (`region: us-central1`) делает on-demand транскрипцию голосового сообщения через OpenAI Whisper (`model: whisper-1`) и сохраняет результат в поле `voiceTranscript` документа сообщения.
  - Требования: пользователь **должен быть авторизован** (иначе `unauthenticated/AUTH_REQUIRED`) и **быть участником** разговора (`permission-denied/NOT_A_MEMBER`).
  - Ограничения: E2EE сообщения не поддерживаются (`failed-precondition/E2EE_UNSUPPORTED`), лимит размера ~12MB (`VOICE_TOO_LARGE`).
  - Секреты: ключ провайдера хранится **на сервере** как `OPENAI_API_KEY` (Cloud Functions env/secret). В мобильном клиенте API-ключ не задаётся.
- Firestore triggers: `onconversationcreated`, `onconversationupdated`, `onconversationdeleted`, `onmessagecreated`, `onthreadmessagecreated`, `onchatmessagedeleted`, `onchatthreadmessagedeleted`, `onchatmessagemediatranscode`, `onchatthreadmessagemediatranscode`, `oncallcreated`, `onmeetingparticipantcreated`, `onuserwritesyncregistrationindex`.
- `oncallcreated` для APNs VoIP использует **один** secret `APNS_VOIP_CONFIG` (JSON): `keyId`, `teamId`, `bundleId`, `privateKeyPem` (содержимое `.p8`, в JSON можно экранировать переводы строк как `\\n`), `useSandbox` (`true`/`false`). Пустой JSON или пустые поля — VoIP пропускается. См. [`apns-voip-secrets.md`](../integrations/apns-voip-secrets.md).
- **Медиа в чате (нормализация):** после создания документа сообщения (основной ленты или треда) функции `onchatmessagemediatranscode` / `onchatthreadmessagemediatranscode` скачивают вложения по публичному URL, при необходимости перекодируют **FFmpeg** (видео → **MP4 H.264 + AAC**, прочее аудио → **M4A AAC**), загружают в Storage по пути `chat-attachments/{conversationId}/norm/{messageId}/…_lcnorm.{mp4|m4a}`, **обновляют** `attachments` на новый URL и **удаляют исходный объект** в `chat-attachments/{conversationId}/…` (если путь распознан из старого URL), чтобы не хранить два файла. Уже `video/mp4` и `audio/mp4` / `audio/mpeg` не перекодируются — оригинал не трогается. В документ сообщения пишется `mediaNorm` (`pending|done|failed`, `failedIndexes`, `updatedAt`) для UI-статуса и ручного retry. Для ручного перезапуска используется callable `retryChatMediaTranscode` (main/thread). Лимит входного размера ~220 МБ; требуются **2 GiB RAM**, до **540 s** таймаут.
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
- ICE-конфиг общий для calls/meetings: `src/lib/webrtc-ice-servers.ts`.
- По умолчанию используются публичные STUN Google; для стабильной связи за NAT/CGNAT добавляется TURN через ENV:
  - Рекомендуемый путь: серверный прокси `src/app/api/webrtc/ice/route.ts` с приватными ENV `METERED_DOMAIN`, `METERED_API_KEY`.
  - Временный fallback (без серверного прокси): `NEXT_PUBLIC_WEBRTC_TURN_URLS` (или `NEXT_PUBLIC_WEBRTC_TURN_URL`), `NEXT_PUBLIC_WEBRTC_TURN_USERNAME`, `NEXT_PUBLIC_WEBRTC_TURN_CREDENTIAL`.
- Диагностика: `GET /api/webrtc/ice/health` возвращает источник ICE (`metered` или `fallback-stun`) и причину fallback; клиент также пишет источник в browser console (`[WebRTC] ICE source: ...`).

## Google Maps (геолокация в чате)

- Превью в ленте: Static Maps API при наличии `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` (`src/lib/google-maps.ts`).
- Полная карта **внутри приложения**: iframe по `buildGoogleMapsEmbedUrl` в `SharedLocationMapDialog` и в `LiveLocationMapDialog` (без ухода со страницы). Внешний браузер — опционально через кнопку «Открыть в браузере».

## Media/UX вспомогательные интеграции

- MediaPipe selfie segmentation - виртуальные фоны/обработка видео.
- Open Graph scraper - server-side превью ссылок.

## Desktop and PWA

- Electron: `electron/main.js` (в проде — локальный Next из **`.next-desktop/standalone`**), `electron/preload.js`, кэш вложений `electron/media-cache.js`.
- Electron media delivery: локальный кэш из `electron/media-cache.js` публикуется в renderer через кастомный протокол `lighchat-media://` (хэндлер в `electron/main.js`), а не через прямые `file://` ссылки.
- Сборка десктопа: `npm run dist` (чистый **`build:clean`**, затем **`icons:mac`** → `build/icon-mac.png` из `public/icon.png`, затем `electron-builder`); артефакты в `dist_desktop/`. Обычный `next build` для web/hosting использует каталог **`.next`** без standalone. В **`package.json` → `build.files`** отдельным entry копируется **`.next-desktop/standalone/node_modules`** (корень проекта по-прежнему исключает `!**/node_modules`). Дополнительно **`"includeSubNodeModules": true`** в **`build`**: обходчик `app-builder-lib` иначе не спускается в **вложенные** каталоги `node_modules` внутри уже разрешённого пути, из-за чего часть зависимостей пакета `next` (и др.) не копируется. Без полного `standalone/node_modules` в **`app.asar.unpacked`** встроенный сервер может упасть с `Cannot find module 'next'` — после смены упаковки нужно пересобрать DMG и заново поставить приложение (проверка: есть ли **`…/app.asar.unpacked/.next-desktop/standalone/node_modules/next/package.json`**).
- Иконка macOS для DMG/Dock: `build/icon-mac.png` (1024×1024, генерируется скриптом; исходник — `public/icon.png`).
- Отладка чёрного экрана / сети UI: запуск из терминала с **`LIGHCHAT_ELECTRON_DEBUG=1`** — откроются DevTools (отдельное окно), в **Application Support** пишутся **`electron-debug.log`** (консоль рендера) и **`next-embedded.log`** (stdout/stderr встроенного Next). Путь к каталогу: `~/Library/Application Support/lighchat/` (имя из `package.json`).
- PWA: `public/manifest.json`, иконки в `public/pwa/*`, app icon в `src/app/icon.png`.

## Mobile (Flutter)

- Flutter клиент находится в `mobile/app`.
- Для Firebase в Flutter используются плагины `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`.
- Синхронизация контактов устройства: `flutter_contacts` + платформенные permissions (`NSContactsUsageDescription` в iOS `Info.plist`, `READ_CONTACTS` в Android `AndroidManifest.xml`); lookup строится через `registrationIndex` ключи `p_*`/`e_*`.
- `mobile/app/lib/firebase_options.dart` синхронизирован с веб-конфигом `src/firebase/config.ts` (тот же проект Firebase). После добавления отдельных приложений iOS/Android/macOS в консоли Firebase обновите `appId` через FlutterFire CLI (`flutterfire configure`), иначе нативная инициализация может отказать.
- Auth parity: чеклист соответствия web↔mobile — `docs/mobile/auth-parity.md`. Требования к полям/валидациям — `docs/mobile/auth-requirements.md`.
- Push: Android — FCM из коробки; iOS — связка FCM + APNS (настраивается в Apple Developer + Firebase console).
- Native incoming call (mobile): `flutter_callkit_incoming` как bridge к Android full-screen incoming UI / iOS CallKit wrapper; обработка событий `Accept/Decline/Timeout` + синхронизация iOS VoIP token реализованы в `mobile/app/lib/features/push/push_native_call_service.dart`, а PushKit delegate — в `mobile/app/ios/Runner/AppDelegate.swift`.

### In-chat mini apps (Games)

В мобильном клиенте внутри профиля беседы (DM/группа) предусмотрен отдельный раздел **«Игры»**.
Это точка входа для будущих мини-игр (например, «Дурак») и других “мини‑приложений” поверх чата.

На текущем этапе реализован **скелет**:

- **Cloud Functions (authoritative server)**: `createGameLobby`, `joinGameLobby`, `startDurakGame`, `makeDurakMove`.
- **Firestore**:
  - `games/{gameId}` — server-write, read только участникам игры.
  - `conversations/{conversationId}/gameLobbies/{gameId}` — server-write, read всем участникам беседы (используется как “приглашение”/листинг лобби в чате).

## Конфиги и деплой

- `firebase.json`, `.firebaserc` - окружение и deploy-таргеты.
- `firestore.indexes.json` - индексы запросов Firestore.
- `firestore.rules` + `src/firestore.rules` - единая модель безопасности.
- `storage.rules` - правила доступа к файлам.
