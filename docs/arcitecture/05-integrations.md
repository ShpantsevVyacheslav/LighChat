# 05: Integrations

## Firebase (основная платформа)

- Auth: login/register/social auth, соответствие `users/{uid}`.
- Firestore: realtime-данные (чаты, звонки, встречи, индексы).
  - **TTL исчезающих сообщений:** после деплоя CF включите в консоли Firestore (или gcloud) политику TTL на поле **`expireAt`** для групп коллекций:
    - `conversations/{conversationId}/messages/{messageId}`
    - `conversations/{conversationId}/messages/{messageId}/thread/{threadMessageId}`  
    Имя поля должно совпадать с тем, что пишут функции (`expireAt`, тип Timestamp). Legacy/ошибочное `expired_at` не используется. Без политики TTL документы с `expireAt` не удаляются автоматически; дополнительно Cloud Scheduler `cleanupExpiredDisappearingMessages` удаляет истёкшие сообщения раз в минуту как bounded fallback, потому что Firestore TTL может срабатывать с задержкой.
- Storage: медиа/вложения/аватары/фоновые ресурсы.
- Cloud Functions (v2): auth/firestore/http/scheduler automation.
- FCM: data-push для уведомлений и входящих звонков (Android/Web и fallback).
  - Call payload (trigger `oncallcreated`) включает `callId`, `callerId`, `callerName`, `isVideo` (в `data`) и используется mobile-клиентом для native incoming-call UX.
- APNs VoIP (iOS): trigger `oncallcreated` отправляет VoIP push напрямую в APNs HTTP/2 (`api.push.apple.com` / `api.sandbox.push.apple.com`) с JWT ES256 (`.p8`), `apns-topic: <bundleId>.voip` и payload для `flutter_callkit_incoming`.
- Web push подписка на клиентах зависит от корректных ограничений Browser API key (referrer + API restrictions) и контекста запуска (на iOS — установленное Home Screen PWA).
- Hosting: публикация web-приложения.

### Cloud Functions surface (ключевые вызовы)

- Callable HTTP: `createNewUser`, `updateUserAdmin`, `backfillConversationMembers`, `backfillRegistrationIndex`, `requestMeetingAccess`, `respondToMeetingRequest`, `checkGroupInvitesAllowed`, `retryChatMediaTranscode`.
  - **Secret chat:** `setSecretChatPin` (установить/сменить PIN), `hasSecretVaultPin` / `verifySecretVaultPin` (gate для списка секретных чатов), `unlockSecretChat` (выдать временный unlock‑grant `secretAccess/{uid}`), `updateSecretChatSettings` (server-only настройки), `deleteSecretChat`, scheduler `cleanupExpiredSecretChats` (каждые 5 минут удаляет истёкшие секретные чаты и связанные файлы в Storage).
  - **Secret chat hard media views:** `requestSecretMediaView` (получатель запрашивает просмотр → атомарно учитывается лимит и создаётся request), `fulfillSecretMediaViewRequest` (issuer/key-holder выдаёт короткий per-file grant), `consumeSecretMediaKeyGrant` (одноразово “съедает” grant), scheduler `cleanupSecretMediaRequests` (чистит просроченные requests/grants).
  - **iOS-обход для callable:** мобильный клиент (`mobile/packages/lighchat_firebase/lib/src/firebase_callable_http.dart`) на iOS вызывает часть функций прямым `POST https://us-central1-{projectId}.cloudfunctions.net/{name}` с `Authorization: Bearer <idToken>`, минуя плагин `cloud_functions`. Причина — SDK `FirebaseFunctions` 12.9.0 в `FunctionsContext.context(options:)` использует три параллельных `async let`, на которых Swift-рантайм iOS крашит Release-процесс в `_swift_task_dealloc_specific (.cold.2)` (SIGABRT, «freed pointer was not the last allocation»). Под обходом: `checkGroupInvitesAllowed`, secret-chat vault/unlock/media callables, игровые callables, `requestQrLogin`/`confirmQrLogin` и `updateDeviceLastLocation` (вызывается из `publishMobileDevice` на старте сессии и при открытии E2EE-чата через `MobileE2eeRuntime.ensureIdentity`). Контракт ответа (`{result: …}` / `{error: {status,message}}`) и семантика ошибок сохранены; Android/Web идут штатно через `cloud_functions`.
- **Voice transcription (чат):** транскрипция голосовых сообщений выполняется **локально на устройстве** через нативные движки (iOS: `SFSpeechRecognizer` / Apple Speech Framework, Android 13+: `SpeechRecognizer.createOnDeviceSpeechRecognizer` с PCM-источником через `EXTRA_AUDIO_SOURCE`). Реализация в [`mobile/app/lib/features/chat/data/local_voice_transcriber.dart`](../../mobile/app/lib/features/chat/data/local_voice_transcriber.dart), нативные модули — `mobile/app/ios/Runner/Speech/VoiceTranscriberBridge.swift` и `mobile/app/android/app/src/main/kotlin/com/lighchat/lighchat_mobile/VoiceTranscriberBridge.kt`, общий `MethodChannel` — `lighchat/voice_transcribe`.
  - **Зачем локально:** OpenAI Whisper API недоступен пользователям из РФ и требует биллинга; on-device движки работают без интернета, без VPN и не зависят от внешних API. E2EE-чаты теперь тоже поддерживаются — расшифровка и распознавание происходят локально.
  - **Хранение:** transcript кэшируется в памяти процесса (in-memory cache в `LocalVoiceTranscriber`) на время жизни приложения. Firestore-поле `voiceTranscript` mobile-клиент больше не пишет — оно остаётся только для совместимости со старыми сообщениями. Legacy серверная транскрипция (Cloud Function `transcribeVoiceMessage` через OpenAI Whisper) полностью удалена в 2026-05.
  - **Языки:** поддерживается полный список локалей, доступных на устройстве (на iOS ~50+, включая ru/en/es/pt/tr/id/kk/uz и др.). Выбор языка по `Localizations.localeOf(context)` с маппингом в BCP-47 и fallback на `en-US`.
  - **Permissions:** iOS требует `NSSpeechRecognitionUsageDescription` (Info.plist + локализованные `InfoPlist.strings`); запрос идёт через `SFSpeechRecognizer.requestAuthorization`. Android использует уже выданное `RECORD_AUDIO` и системный on-device пакет распознавания.
  - **Авто-детект языка:** после первого прогона распознавания текст пропускается через `NLLanguageRecognizer` (iOS); если определённый язык расходится с локалью рекогнайзера с уверенностью ≥ 0.75 — делается повторный прогон с правильной локалью. Это покрывает «UI на en, голосовое на ru». Если первый прогон возвращает пусто — Dart перебирает fallback-локали (для UI=en → `ru-RU`, для UI=ru → `en-US`, для прочих — обе пары).
- **On-device перевод (ML Kit Translation):** для транскриптов голосовых и текстовых сообщений в чате используется [`google_mlkit_translation`](https://pub.dev/packages/google_mlkit_translation) (~6 МБ к билду + ~30 МБ на каждую языковую пару, скачиваемую с `mlkit.gstatic.com` один раз и далее работающую офлайн).
  - **Сервис:** [`mobile/app/lib/features/chat/data/local_message_translator.dart`](../../mobile/app/lib/features/chat/data/local_message_translator.dart) — Singleton с менеджером моделей, in-memory кэшем и персистентным SQLite-кэшем (`getApplicationSupportDirectory()/lighchat_translations.db`, таблица `translations(cache_key PK, from_lang, to_lang, translated_text, created_at)`). Переживает рестарт приложения.
  - **Детектор языка для текста:** [`local_text_language_detector.dart`](../../mobile/app/lib/features/chat/data/local_text_language_detector.dart) — общий `MethodChannel` `lighchat/voice_transcribe`, метод `detectLanguage`. iOS — `NLLanguageRecognizer`; Android — эвристика по Unicode-блокам (Cyrillic→ru, Latin→en, Arabic→ar, Hangul→ko, CJK→zh, Hiragana/Katakana→ja, Devanagari→hi, Thai→th, Hebrew→he, Greek→el).
  - **UX:** в пузыре голосового — кнопка `🌐 Translate` рядом с Copy, появляется только если детект ≠ UI и пара поддерживается; для текстовых — пункт `Translate` в long-press меню (`MessageMenuActionType.translate`), результат показывается в bottom-sheet (`MessageTranslationSheet`).
  - **Не поддерживаются** kk и uz — UI скрывает кнопку при таких языках.
  - **iOS:** требует `IPHONEOS_DEPLOYMENT_TARGET = 15.5` (бамп с 15.0). `GTMSessionFetcher/Core` принудительно зафиксирован в Podfile на `~> 3.5` — иначе конфликт между Firebase Functions (хочет < 5.0) и MLKitCommon (хочет < 4.0).
- Firestore triggers: `onconversationcreated`, `onconversationupdated`, `onconversationdeleted`, `onmessagecreated`, `onthreadmessagecreated`, `onchatmessagedeleted`, `onchatthreadmessagedeleted`, `onchatmessagemediatranscode`, `onchatthreadmessagemediatranscode`, `oncallcreated`, `onmeetingparticipantcreated`, `onuserwritesyncregistrationindex`.
- `oncallcreated` для APNs VoIP использует **один** secret `APNS_VOIP_CONFIG` (JSON): `keyId`, `teamId`, `bundleId`, `privateKeyPem` (содержимое `.p8`, в JSON можно экранировать переводы строк как `\\n`), `useSandbox` (`true`/`false`). Пустой JSON или пустые поля — VoIP пропускается. См. [`apns-voip-secrets.md`](../integrations/apns-voip-secrets.md).
- **Медиа в чате (нормализация):** после создания документа сообщения (основной ленты или треда) функции `onchatmessagemediatranscode` / `onchatthreadmessagemediatranscode` скачивают вложения по публичному URL, при необходимости перекодируют **FFmpeg** (видео → **MP4 H.264 + AAC**, прочее аудио → **M4A AAC**), загружают в Storage по пути `chat-attachments/{conversationId}/norm/{messageId}/…_lcnorm.{mp4|m4a}`, **обновляют** `attachments` на новый URL и **удаляют исходный объект** в `chat-attachments/{conversationId}/…` (если путь распознан из старого URL), чтобы не хранить два файла. Уже `video/mp4` и `audio/mp4` / `audio/mpeg` не перекодируются — оригинал не трогается. В документ сообщения пишется `mediaNorm` (`pending|done|failed`, `failedIndexes`, `updatedAt`) для UI-статуса и ручного retry. Для ручного перезапуска используется callable `retryChatMediaTranscode` (main/thread). Лимит входного размера ~220 МБ; требуются **2 GiB RAM**, до **540 s** таймаут.
- Auth trigger: `onUserCreated`.
- Scheduler: `checkUserPresence`, `cleanupExpiredDisappearingMessages`, `mediaRetentionCleanupDaily`, `enforceStorageQuotasDaily`, `evidenceCleanupDaily`.
- **Storage retention & quota enforcement:** scheduled CF [`mediaRetentionCleanupDaily`](../functions/src/triggers/scheduler/mediaRetentionCleanupDaily.ts) (04:00 Europe/Moscow) и [`enforceStorageQuotasDaily`](../functions/src/triggers/scheduler/enforceStorageQuotasDaily.ts) (04:30) применяют параметры из `platformSettings/main.storage`. Гейтятся `enforcementMode`: `off` (default) — функции ничего не делают, `dry_run` — пишут «что бы удалили» в логи, `enforce` — удаляют объекты GCS (`chat-attachments/*` и `chat-attachments-enc/*`) и зачищают `attachments[]` в Firestore с метками `mediaEvictedAt`/`mediaEvictedReason` (`retention | quota_conversation | quota_total`). Сообщение остаётся в истории; счётчик `conversations/{cid}.storage.totalBytes` декрементируется. Общая логика и хелперы — [`functions/src/lib/storage-quota-enforcement.ts`](../functions/src/lib/storage-quota-enforcement.ts). Per-user квота (`users/{uid}.storageQuotaBytes`) пока не enforce'ится — требуется отдельный счётчик usage.
- **GCP Billing Export → BigQuery:** callable [`fetchBillingSummary`](../functions/src/triggers/http/fetchBillingSummary.ts) (region `us-central1`, admin-only) читает таблицу экспорта через `@google-cloud/bigquery@7`. Конфиг — `platformSettings/main.billing.{projectId, dataset, tableId}`, заполняется админом в [`AdminCostsPanel`](../src/components/admin/admin-costs-panel.tsx). Identifiers валидируются регексом `[A-Za-z][A-Za-z0-9_-]*` перед подстановкой в backticked SQL (anti-injection). **Ручная настройка GCP** (один раз на billing account): включить Billing export → BigQuery (Standard daily cost), затем выдать SA Cloud Functions `roles/bigquery.dataViewer` на dataset и `roles/bigquery.jobUser` на project. До настройки CF возвращает `{ ok:false, error:'not_configured' }`, и UI открывает форму ввода projectId/dataset/tableId. Cloud Billing REST API мы не вызываем — он не даёт SKU-разбивку.

## Games / Durak / Tournaments

- **Durak lobby/game:** callables `createGameLobby`, `joinGameLobby`, `startDurakGame`, `makeDurakMove`.
- **Tournaments (Durak):**
  - callable `createDurakTournament` создаёт:
    - `tournaments/{tournamentId}` — корневой документ турнира (server-write)
    - `conversations/{conversationId}/tournaments/{tournamentId}` — индекс для списка в UI
  - callable `createTournamentGameLobby` создаёт новую партию “Дурака” внутри турнира:
    - `games/{gameId}` с полем `tournamentId`
    - `conversations/{conversationId}/gameLobbies/{gameId}` с полем `tournamentId`
    - `tournaments/{tournamentId}/games/{gameId}` — ссылка/статус партии в турнире
  - начисление очков: при завершении игры (в `makeDurakMove`) турнир обновляет
    `pointsByUid` и `gamesPlayedByUid` по “sport” схеме \(N..1\) с делением очков при ничьих.

## GIPHY API

- Точка: `src/app/api/giphy/search/route.ts`.
- Назначение: серверный прокси к GIPHY API v1 (gifs/stickers), скрывает API key от клиента.
- ENV: `GIPHY_API_KEY` (получить на https://developers.giphy.com → создать API key).
- Параметры запроса: `q` (текст; пусто → trending), `type=stickers` (анимированные эмодзи) или `type=gifs` (по умолчанию).
- Формат ответа: `{ ok, items: [{ id, url, width?, height? }], error? }`.
- Используется веб-панелью `ChatStickerGifPanel.tsx` и мобильным `composer_sticker_gif_sheet.dart`.
- Историческая заметка: ранее использовался Tenor API (Google), но он перестал быть доступен в Google Cloud Console — мигрировали на GIPHY с сохранением формата ответа.
- **Animated emoji permanent cache (mobile):** [`GiphyCacheStore`](../../mobile/app/lib/features/chat/data/giphy_cache_store.dart) хранит GIPHY-выдачи в `SharedPreferences`. Ключи: `gifs:<query>`, `stickers:<query>`, `emoji:<query>`. Для `GiphyType.emoji` (анимированные эмодзи) **TTL не применяется** — каталог стабильный, новые позиции добираются только через пагинацию `_loadMoreAnimEmojis`, а уже загруженные остаются навсегда (permanent cache). Для `gifs`/`stickers` TTL = 24h, LRU-лимит 20 ключей. Emoji-ключи (`emoji:*`) **защищены от LRU-вытеснения** — при eviction удаляются только `gifs:`/`stickers:`-записи. Пагинация: при скролле догружаются следующие порции с дедупликацией по `id` **и** `url` (защита от дублей GIPHY API); накопленный merged-список перезаписывается в кеш под исходным ключом. Ключи trending: `gifs:''`, `stickers:''`, `emoji:''` (пустой query). Recent: отдельный список последних 30 отправленных GIF (dedup по `url`/`id`).

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

- Desktop теперь полностью на Flutter (см. секцию ниже про Mobile (Flutter) — те же таргеты + macOS/Windows/Linux). Electron-shell и весь связанный код (`electron/`, `.next-desktop/`, `dist_desktop/`, `LIGHCHAT_DESKTOP_BUILD`, `lighchat-media://` протокол) удалены. Stub `isElectron()` в `src/lib/utils.ts` возвращает `false` для обратной совместимости старых call-sites — их можно постепенно удалить.
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
- **Durak / «Шулер» (anti-cheat-игромеханика)**:
  - Сервер может принять “неканоничный” ход и помечает его как чит (`serverState.lastCheat`).
  - **«Фолл!» доступен только после «Бито»**: при `finishTurn` (когда на столе всё отбито) в шулер-режиме выставляется `serverState.pendingResolution`, и раунд ждёт подтверждения.
  - Если кто-то нажимает **«Фолл!»** до подтверждения, сервер откатывает последний чит и применяет штраф; `foulEvent.missedUids` используется клиентом для показа “кто не заметил” поимённо/с аватарками.
  - Если фолла нет, атакующий нажимает **подтверждение «Бито»** (`makeDurakMove` с `actionType="resolve"`) и раунд резолвится как обычно.

- **Durak / UX (mobile)**:
  - Экран игры показывает “ленту игроков” (порядок по кругу, роли, PASS), явную фазу и подсказки.
  - Рука отображается как веер с overlap и сортировкой; при доборе/раздаче используется анимация “колода → рука”.
  - При ходе есть анимация “рука → стол” (визуальный полёт карты), а стол уплотнён и пары атака/защита визуально связаны.

## Конфиги и деплой

- `firebase.json`, `.firebaserc` - окружение и deploy-таргеты.
- `firestore.indexes.json` - индексы запросов Firestore.
- `firestore.rules` + `src/firestore.rules` - единая модель безопасности.
- `storage.rules` - правила доступа к файлам.
