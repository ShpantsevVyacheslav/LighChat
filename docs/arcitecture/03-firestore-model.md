# 03: Firestore Model

Правила доступа: `firestore.rules` (и синхронная копия `src/firestore.rules`).

## Коллекции верхнего уровня

- `users/{userId}` - профиль, роль, presence, настройки.
  - `notifications/{notificationId}`
  - `stickerPacks/{packId}/items/{itemId}`
- `registrationIndex/{docId}` - индекс уникальности (email/phone/username), только server-write.
- `publicStickerPacks/{packId}` - общие стикерпаки (read: авторизованные; write: admin).
  - `items/{itemId}` - стикеры/GIF (те же поля, что у `users/*/stickerPacks/*/items`).
- `conversations/{conversationId}` - чат и метаданные участников.
  - `members/{memberId}` - server-maintained индекс участников для правил.
  - `typing/{typingUserId}`
  - `messages/{messageId}` (+ вложенные thread-path документы)
  - `polls/{pollId}`
- `userChats/{userId}` - денормализованный индекс чатов пользователя.
- `userContacts/{userId}` - список контактов пользователя.
- `calls/{callId}` - документ звонка.
  - `candidates/{candidateId}` - ICE candidates.
- `userCalls/{userId}` - денормализованный индекс звонков.
- `meetings/{meetingId}` - документ встречи.
  - `participants/{participantId}`
  - `signals/{signalId}`
  - `requests/{userId}`
  - `messages/{messageId}`
  - `polls/{pollId}`
- `userMeetings/{userId}` - денормализованный индекс встреч.
- `platformSettings/{docId}` - платформенные настройки (admin-write).
- `supportTickets/{ticketId}` - admin-read.

## Ключевые связи

- `users.id` == Firebase Auth uid.
- `conversations.participantIds` определяет состав чата; `conversations/*/members/*` - серверный индекс для правил.
- `userChats.conversationIds[]` ссылается на `conversations/{id}`.
- `calls.callerId/receiverId` ссылается на `users/{id}`; `userCalls.callIds[]` ссылается на `calls/{id}`.
- `meetings.hostId/adminIds` ссылается на `users/{id}`; `userMeetings.meetingIds[]` ссылается на `meetings/{id}`.

## Что поддерживают Cloud Functions

- Создание/обновление/удаление `conversations` синхронизирует `members` и `userChats`.
- Создание `calls` синхронизирует `userCalls`.
- Создание участника встречи синхронизирует `userMeetings`.
- Изменения `users` синхронизируют `registrationIndex`.

## Критичные заметки для изменений

- Нельзя менять только одну из двух моделей membership (`participantIds`/`members`) без обновления trigger-логики и правил.
- При изменениях правил обновляй оба файла: `firestore.rules` и `src/firestore.rules`.
- Проверяй релевантность `firestore.indexes.json` после добавления новых query-паттернов.
