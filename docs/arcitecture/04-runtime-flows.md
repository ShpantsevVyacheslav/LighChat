# 04: Runtime Flows

Краткая карта основных пользовательских и системных потоков.

## 1) Auth и профиль

1. Пользователь входит через Firebase Auth (`src/hooks/use-auth.tsx`).
2. Профиль читается из `users/{uid}`; при отсутствии формируется fallback.
3. Проверяются ограничения (`deletedAt`, `accountBlock`).
4. Обновляются `online/lastSeen` и фоновые presence-сценарии.

## 2) Список чатов и чтение диалогов

1. UI берёт `userChats/{uid}.conversationIds`.
2. Документы чатов подписываются по id (`useConversationsByDocumentIds`), без общего list-query.
3. В `ChatWindow` читаются `conversations/{id}/messages` и связанные поддокументы.
4. Изменения обновляют метаданные чата (last message, unread, thread counters).

## 3) Отправка сообщений

1. Клиент пишет сообщение в `conversations/{id}/messages/{messageId}`.
2. Обновляет parent `conversations/{id}` (последнее сообщение/счётчики/реакции).
3. Firestore trigger `onmessagecreated` отправляет FCM другим участникам.
4. Для тредов trigger `onthreadmessagecreated` шлёт отдельные уведомления.

## 4) 1:1 звонки

1. Создаётся `calls/{callId}` с caller/receiver и offer.
2. Trigger `oncallcreated` обновляет `userCalls` и отправляет входящий push.
3. Клиенты обмениваются offer/answer/candidates через `calls/{id}` и `calls/{id}/candidates`.
4. Завершение звонка обновляет статус и timestamps в документе call.

## 5) Встречи (meetings)

1. Создаётся `meetings/{meetingId}`.
2. Участники входят в `participants`; trigger обновляет `userMeetings`.
3. Signaling: `meetings/{id}/signals`.
4. Встроенный чат: `meetings/{id}/messages`; опросы: `meetings/{id}/polls`.
5. Для приватных встреч запросы в `meetings/{id}/requests` через callable функции.

## 6) Админ и служебные потоки

- Callable admin endpoints (`createNewUser`, `updateUserAdmin`, backfill-операции).
- Периодический scheduler `checkUserPresence` чистит stale presence/meeting records.
- Server actions в `src/actions/*` выполняют read-heavy/privileged операции для UI-панелей.

## 7) iOS PWA performance guards

- Бейдж непрочитанных сообщений рассчитывается только в chat-маршрутах, чтобы не держать тяжёлые realtime-подписки на каждом экране dashboard.
- PWA onboarding выполняет длинные FCM-подписки в фоне и не блокирует UI длительным ожиданием.
- Overlay звонков подключается с небольшой отложенной инициализацией после входа в dashboard, чтобы разгрузить cold-start.
- В meetings ограничен объём realtime-данных на старте (лимиты истории чата и опросов).
