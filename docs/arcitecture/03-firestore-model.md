# 03: Firestore Model

Правила доступа: `firestore.rules` (и синхронная копия `src/firestore.rules`).

## Коллекции верхнего уровня

- `users/{userId}` - профиль, роль, presence, настройки; опционально `fcmTokens` (массив строк FCM), `voipTokens` (массив iOS PushKit token для нативного входящего звонка), `notificationSettings` (глобальная политика push), `profileQrLink` (персональная web-ссылка профиля для QR-кода/шаринга), `blockedUserIds` (массив uid заблокированных пользователей — см. правила и CF `onuserwriteblocksideeffects`).
  - `outgoingBlocks/{blockedUserId}` — зеркало `blockedUserIds` (пустой маркер-документ на каждого заблокированного). Пишет только Admin SDK (CF при изменении `blockedUserIds`); читать могут владелец `userId` и `blockedUserId` (нужно для правил `userBlocks` через `exists`, без `get(users/{blocker})`, который для заблокированного читателя запрещён правилом профиля).
  - `chatConversationPrefs/{conversationId}` - персональные настройки чата для аккаунта (`notificationsMuted`, `notificationShowPreview`, обои и т.д.).
  - `notifications/{notificationId}`
  - `stickerPacks/{packId}/items/{itemId}`
  - `e2eeDevices/{deviceId}` - публичные ключи устройств E2EE v2 (запись только владельцем; чтение — любой вошедший, для обёртки chat-key под каждое устройство собеседника). Legacy `e2ee/{docId}` v1 удалён в Phase 10 cleanup.
  - `e2eeBackups/{backupId}` - password-backup обёрнутого приватника v2 (read/write только владелец). См. RFC §5.2.
  - `e2eePairingSessions/{sessionId}` - эфемерные QR-pairing сессии v2 (TTL 10 мин, чистятся scheduled CF [`cleanupE2eePairingSessions`](../functions/src/triggers/scheduler/cleanupE2eePairingSessions.ts)). См. RFC §5.3, §6.7.
  - `devices/{deviceId}` - реестр клиентских устройств/сессий пользователя (`app`, `platform`, `isActive`, `lastSeenAt`, `lastLoginAt`), read/write только владельцем uid.
  - `secretChatLock/{docId}` - user‑scoped PIN‑lock для секретных чатов (например `users/{uid}/secretChatLock/main`): хранит `pinSaltB64`, `pinHashB64`, счётчик ошибок и `lockedUntil` (rate‑limit). Заполняется callable `setSecretChatPin`, проверяется callable `unlockSecretChat`.
- `registrationIndex/{docId}` - индекс уникальности (email/phone/username), только server-write; чтение для вошедших ограничено, если владелец индекса (`uid` в документе) заблокировал читателя.
- `publicStickerPacks/{packId}` - общие стикерпаки (read: авторизованные; write: admin).
  - `items/{itemId}` - стикеры/GIF (те же поля, что у `users/*/stickerPacks/*/items`).
- `conversations/{conversationId}` - чат и метаданные участников (в т.ч. unread-счётчики и reaction-anchor поля `lastReaction*` + `lastReactionSeenAt`).
  - **Исчезающие сообщения:** `disappearingMessageTtlSec` (число секунд или `null` = выкл), опционально `disappearingMessagesUpdatedAt` (ISO), `disappearingMessagesUpdatedBy` (uid). В личном чате меняют оба участника; в группе — только создатель/админы (см. `firestore.rules`). На документы `messages/*` и `messages/*/thread/*` CF после создания пишет `expireAt` (Timestamp) для Firestore TTL и scheduled-cleanup fallback; клиент поле `expireAt` не задаёт.
  - **Секретный чат:** поле `secretChat` (map) включает флаги режима и срок жизни (ISO `expiresAt` + preset `ttlPresetSec`), ограничения (`noForward/noCopy/noSave/screenshotProtection`), опционально `mediaViewPolicy`, а также `lockPolicy.required`. Поля задаются **только при создании** чата (callable-клиенты не могут менять конфигурацию через `updateSecretChatSettings`). TTL действия unlock‑grant фиксирован на сервере (`unlockSecretChat`). В секретном чате чтение `messages/*`, `e2eeSessions/*` и медиа в Storage требует активного unlock‑grant (см. `secretAccess` ниже).
  - `members/{memberId}` - server-maintained индекс участников для правил.
  - `typing/{typingUserId}`
  - `messages/{messageId}` (+ вложенные thread-path документы; для медиа-нормализации используется поле `mediaNorm` со статусом `pending|done|failed` и `failedIndexes`; для синхронизации emoji-эффектов используется `emojiBurst: {eventId, emoji, by, at}`; при включённом таймере исчезновения — поле `expireAt` для TTL-удаления)
  - `polls/{pollId}`
  - `gameLobbies/{gameId}` - список лобби игр в рамках беседы (read: участники беседы; write: только server). Используется как “приглашение”/точка входа для присоединения к игре.
  - `tournaments/{tournamentId}` - индекс турниров в рамках беседы (server-write). Используется как список/точка входа в турнирный экран.
  - `secretAccess/{userId}` - unlock‑grant секретного чата (server‑write через callable `unlockSecretChat`, read: только владелец `userId`). Поле `expiresAtTs` (Timestamp) используется в правилах для server‑enforced доступа к сообщениям/вложениям.
  - **Secret Chat hard media view limits (server-enforced):**
    - `secretMediaViewState/{id}` — server‑controlled счётчик просмотров per `(recipientUid,messageId,fileId)` (`limit/used/locked`).
    - `secretMediaViewRequests/{id}` — короткоживущий запрос на просмотр (TTL ~60s) от получателя; любой online key‑holder может fulfill.
    - `secretMediaKeyGrants/{id}` — короткоживущий per‑file grant (TTL ~30s), который **разрешает Storage read** для `chat-attachments-enc/{cid}/{mid}/{fileId}/…`.
  - `e2eeSessions/{epoch}` - эпохи симметричного ключа чата в формате E2EE v2: вложенная мапа `wraps[userId][deviceId]` (ciphertext; сервер не знает plaintext). Единственная поддерживаемая версия — `protocolVersion: 'v2-p256-aesgcm-multi'`; документы с другими версиями клиенты молча ротируют через self-heal.
- `userChats/{userId}` - денормализованный индекс **обычных** чатов пользователя (`conversationIds[]`). Документы секретных личных чатов с префиксом id `sdm_*` сюда **не** добавляются.
- `userSecretChats/{userId}` - индекс только секретных DM (`conversationIds[]`, синхронизируется триггером при создании/удалении/миграции). Читает владелец; клиентская запись запрещена правилами.
- `secretChats/{conversationId}` - минимальный server-maintained маркер существования секретного чата (для правил и очистки), синхронизируется с `conversations/{id}` где `secretChat.enabled == true`.
- `userContacts/{userId}` - список контактов пользователя.
  - `contactIds[]` - id добавленных контактов.
  - `contactProfiles.{contactUserId}` - локальное имя контакта (firstName/lastName/displayName/updatedAt), используется только владельцем списка в списках чатов/поиске/карточках контакта.
  - `deviceSyncConsentAt`, `phoneBookOfferDismissedAt` - флаги согласия/онбординга для импорта телефонной книги.
  - `deviceLookup/{registrationIndexKey}` - ключи телефонной книги устройства (phone/email) для авто-сопоставления с `registrationIndex` и автодобавления новых зарегистрированных контактов.
- `calls/{callId}` - документ звонка (`status`: `calling|ongoing|ended|cancelled|missed`, legacy: `rejected`), `endedBy` (uid завершившего/сбросившего участника, если известен).
  - `candidates/{candidateId}` - ICE candidates.
- `userCalls/{userId}` - денормализованный индекс звонков.
- `meetings/{meetingId}` - документ встречи.
  - `participants/{participantId}`
  - `signals/{signalId}`
  - `requests/{userId}`
  - `messages/{messageId}`
  - `polls/{pollId}`
- `userMeetings/{userId}` - денормализованный индекс встреч.
- `platformSettings/{docId}` - платформенные настройки (admin-write). Ключевые поля E2EE: `e2eeDefaultForNewDirectChats` (попытка авто-E2E при создании нового личного чата, клиент) и `e2eeProtocolVersion` ∈ `{'v2','auto','off'}` (rollout-флаг; после Phase 10 cleanup поддержки v1 нет).
- `supportTickets/{ticketId}` - admin-read.
- `games/{gameId}` - сессии мини-приложений/игр внутри чата (например, “Дурак”).
  - Создание/обновление — **только Cloud Functions** (Admin SDK).
  - Чтение — только участникам игры (uid ∈ `playerIds`).
  - `privateHands/{uid}` — приватная рука игрока (read: только `uid`, write: только server). Помимо `cards[]` содержит `legalMoves` с серверно рассчитанными разрешёнными действиями для текущей `revision`.
  - `moves/{clientMoveId}` — журнал ходов (read: игроки, write: server).
  - Поля (минимум): `type`, `status`, `conversationId`, `isGroup`, `createdAt`, `createdBy`, `playerIds[]`, `settings`, `serverState`, `publicView`, `result`, `startedAt`, `finishedAt`, `lastUpdatedAt`.
  - Для `status='lobby'`: `readyUids[]`, `readyDeadlineAt` (ISO, 30 секунд на ready-room), `players[]`. Нажатие Ready идёт через callable `startDurakGame`; scheduler `cleanupDurakReadyRooms` удаляет неготовых после дедлайна и стартует партию, если осталось минимум 2 готовых игрока.
  - `publicView` (для UI): `phase` (`attack|defense|throwIn|resolution|finished`), `throwerUids[]`, `passedUids[]`, `currentThrowerUid|null`, `turnUid|null`, `turnKind`, `turnStartedAt|null`, `turnDeadlineAt|null`, `turnTimeSec|null`, `roundDefenderHandLimit|null`, `canFinishTurn`, `table`, `handCounts`, `trumpSuit`, фактическая `trumpCard|null`, `deckCount`, `discardCount`, `attackerUid`, `defenderUid`, `result`.
  - `privateHands/{uid}.legalMoves`: `revision`, `canTake`, `canPass`, `canFinishTurn`, `attackCardKeys[]`, `transferCardKeys[]`, `defenseTargets[]` (`attackIndex`, `cardKeys[]`). Клиенты не получают прав записи на эти поля.
  - `moves/*` (для истории/дебага): хранит исходный `payload` и нормализованный `payloadNormalized` (например `cardKey`, `attackIndex`, `loserUid` для `surrender`), а также `phase` и `result` на момент хода.

- `tournaments/{tournamentId}` - турнир (серия партий) для игр внутри чата (сейчас: Durak).
  - Создание/обновление — **только Cloud Functions** (Admin SDK).
  - Чтение — только участникам беседы `conversationId` (см. `firestore.rules`).
  - Поля (минимум): `type: 'durak'`, `status`, `title`, `conversationId`, `createdAt`, `createdBy`, `gameIds[]`,
    `pointsByUid{uid:number}`, `gamesPlayedByUid{uid:number}`, `lastUpdatedAt`.
  - `games/{gameId}` — подколлекция партий турнира: `status (lobby|active|finished)`, `playerIds[]`, `playerCount`,
    `placements` (группы мест), `winners[]`, `loserUid|null`, а также маркеры идемпотентности начисления (`applied`, `appliedAt`).

## Ключевые связи

- `users.id` == Firebase Auth uid.
- `users/{uid}/devices/{deviceId}` хранит состояние конкретного клиента (web/mobile): при входе клиент помечает `isActive=true`, при выходе/скрытии — `isActive=false`.
- `conversations.participantIds` определяет состав чата; `conversations/*/members/*` - серверный индекс для правил.
- Для личных 1:1 чатов `conversationId` детерминирован по паре uid (`dm_{lenA}:{uidA}_{lenB}:{uidB}`, uid в лексикографическом порядке), чтобы не появлялись дубликаты диалогов между одной парой пользователей.
- Личный чат «Избранное» хранится как `conversations` с `isGroup=false` и ровно одним `participantIds` (uid владельца).
- Для «Избранного» используется детерминированный `conversationId` по uid владельца (`saved_{len}:{uid}`); web/mobile при входе делают идемпотентный ensure и очищают лишние `saved`-id из `userChats/{uid}.conversationIds`, чтобы в списке оставался один активный чат.
- `userChats.conversationIds[]` ссылается на `conversations/{id}`.
- `calls.callerId/receiverId` ссылается на `users/{id}`; `userCalls.callIds[]` ссылается на `calls/{id}`.
- `meetings.hostId/adminIds` ссылается на `users/{id}`; `userMeetings.meetingIds[]` ссылается на `meetings/{id}`.

## Что поддерживают Cloud Functions

- Push по новым сообщениям: при наличии `e2ee` на документе сообщения текст в FCM не передаётся (только нейтральная подпись).
- Исчезающие сообщения: триггеры `onmessagecreated` / `onthreadmessagecreated` выставляют `expireAt` по `conversations.disappearingMessageTtlSec` до push-веток; scheduler `cleanupExpiredDisappearingMessages` раз в минуту удаляет уже истёкшие main/thread сообщения как bounded fallback к Firestore TTL. `onchatmessagedeleted` / `onchatthreadmessagedeleted` чистят закрепы и при необходимости пересчитывают `lastMessage*` на `conversations/{id}`. Перед этим те же триггеры вызывают удаление объектов в **Storage** по разрешённым префиксам `chat-attachments/{cid}/…` и `chat-attachments-enc/{cid}/…` (вложения plaintext, каталог `norm/{messageId}/`, зашифрованные чанки E2EE v2 по `fileId`).
- Создание/обновление/удаление `conversations` синхронизирует `members` и `userChats`.
- Создание `calls` синхронизирует `userCalls` и отправляет call-push: FCM (`users.fcmTokens`) + APNs VoIP (`users.voipTokens`, iOS).
- Scheduler `checkUserPresence` дополнительно переводит `calls.status=calling` старше 60 секунд в `missed` и проставляет `endedAt`.
- Создание участника встречи синхронизирует `userMeetings`.
- Изменения `users` синхронизируют `registrationIndex`.
- Изменения `users` (phone/email) дополнительно проверяют совпадения в `userContacts/*/deviceLookup/*` (collectionGroup `deviceLookup`) и автоматически добавляют зарегистрировавшегося пользователя в `userContacts/{ownerId}.contactIds` у владельцев совпавших ключей.
- Callable `deleteAccount` удаляет все user-scoped документы (`users/{uid}` рекурсивно + `userChats/userContacts/userCalls/userMeetings`), hosted `meetings` (по `hostId`) и `registrationIndex` записи для uid, затем удаляет пользователя из Firebase Auth (irreversible).

## Критичные заметки для изменений

- Нельзя менять только одну из двух моделей membership (`participantIds`/`members`) без обновления trigger-логики и правил.
- При изменениях правил обновляй оба файла: `firestore.rules` и `src/firestore.rules`.
- В fallback-проверках membership в правилах используй `exists(path)` + `get(path).data`; не полагайся на `get(...).exists` в Firestore rules, иначе запись в `messages/*` и другие подколлекции может отвалиться на клиентах при отсутствии `members/{uid}`.
- Правила чтения `conversations` для saved-messages (`participantIds.size()==1`) должны оставаться owner-only даже при admin-доступе к обычным чатам.
- Для детерминированных id (`saved_*`, `dm_*`) правила допускают `get` несуществующего документа для авторизованного пользователя (по префиксу id), чтобы клиентские `ensure/createOrOpen` потоки могли делать preflight `get` перед `create` без `permission-denied/internal`.
- Проверяй релевантность `firestore.indexes.json` после добавления новых query-паттернов.
