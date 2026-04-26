# 03: Firestore Model

Правила доступа: `firestore.rules` (и синхронная копия `src/firestore.rules`).

## Коллекции верхнего уровня

- `users/{userId}` - профиль, роль, presence, настройки; опционально `fcmTokens` (массив строк FCM), `voipTokens` (массив iOS PushKit token для нативного входящего звонка), `notificationSettings` (глобальная политика push), `profileQrLink` (персональная web-ссылка профиля для QR-кода/шаринга).
  - `chatConversationPrefs/{conversationId}` - персональные настройки чата для аккаунта (`notificationsMuted`, `notificationShowPreview`, обои и т.д.).
  - `notifications/{notificationId}`
  - `stickerPacks/{packId}/items/{itemId}`
  - `e2eeDevices/{deviceId}` - публичные ключи устройств E2EE v2 (запись только владельцем; чтение — любой вошедший, для обёртки chat-key под каждое устройство собеседника). Legacy `e2ee/{docId}` v1 удалён в Phase 10 cleanup.
  - `e2eeBackups/{backupId}` - password-backup обёрнутого приватника v2 (read/write только владелец). См. RFC §5.2.
  - `e2eePairingSessions/{sessionId}` - эфемерные QR-pairing сессии v2 (TTL 10 мин, чистятся scheduled CF [`cleanupE2eePairingSessions`](../functions/src/triggers/scheduler/cleanupE2eePairingSessions.ts)). См. RFC §5.3, §6.7.
  - `devices/{deviceId}` - реестр клиентских устройств/сессий пользователя (`app`, `platform`, `isActive`, `lastSeenAt`, `lastLoginAt`), read/write только владельцем uid.
- `registrationIndex/{docId}` - индекс уникальности (email/phone/username), только server-write.
- `publicStickerPacks/{packId}` - общие стикерпаки (read: авторизованные; write: admin).
  - `items/{itemId}` - стикеры/GIF (те же поля, что у `users/*/stickerPacks/*/items`).
- `conversations/{conversationId}` - чат и метаданные участников (в т.ч. unread-счётчики и reaction-anchor поля `lastReaction*` + `lastReactionSeenAt`).
  - `members/{memberId}` - server-maintained индекс участников для правил.
  - `typing/{typingUserId}`
  - `messages/{messageId}` (+ вложенные thread-path документы; для медиа-нормализации используется поле `mediaNorm` со статусом `pending|done|failed` и `failedIndexes`; для синхронизации emoji-эффектов используется `emojiBurst: {eventId, emoji, by, at}`)
  - `polls/{pollId}`
  - `e2eeSessions/{epoch}` - эпохи симметричного ключа чата в формате E2EE v2: вложенная мапа `wraps[userId][deviceId]` (ciphertext; сервер не знает plaintext). Единственная поддерживаемая версия — `protocolVersion: 'v2-p256-aesgcm-multi'`; документы с другими версиями клиенты молча ротируют через self-heal.
- `userChats/{userId}` - денормализованный индекс чатов пользователя.
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
- Создание/обновление/удаление `conversations` синхронизирует `members` и `userChats`.
- Создание `calls` синхронизирует `userCalls` и отправляет call-push: FCM (`users.fcmTokens`) + APNs VoIP (`users.voipTokens`, iOS).
- Scheduler `checkUserPresence` дополнительно переводит `calls.status=calling` старше 60 секунд в `missed` и проставляет `endedAt`.
- Создание участника встречи синхронизирует `userMeetings`.
- Изменения `users` синхронизируют `registrationIndex`.
- Изменения `users` (phone/email) дополнительно проверяют совпадения в `userContacts/*/deviceLookup/*` (collectionGroup `deviceLookup`) и автоматически добавляют зарегистрировавшегося пользователя в `userContacts/{ownerId}.contactIds` у владельцев совпавших ключей.

## Критичные заметки для изменений

- Нельзя менять только одну из двух моделей membership (`participantIds`/`members`) без обновления trigger-логики и правил.
- При изменениях правил обновляй оба файла: `firestore.rules` и `src/firestore.rules`.
- В fallback-проверках membership в правилах используй `exists(path)` + `get(path).data`; не полагайся на `get(...).exists` в Firestore rules, иначе запись в `messages/*` и другие подколлекции может отвалиться на клиентах при отсутствии `members/{uid}`.
- Правила чтения `conversations` для saved-messages (`participantIds.size()==1`) должны оставаться owner-only даже при admin-доступе к обычным чатам.
- Для детерминированных id (`saved_*`, `dm_*`) правила допускают `get` несуществующего документа для авторизованного пользователя (по префиксу id), чтобы клиентские `ensure/createOrOpen` потоки могли делать preflight `get` перед `create` без `permission-denied/internal`.
- Проверяй релевантность `firestore.indexes.json` после добавления новых query-паттернов.
