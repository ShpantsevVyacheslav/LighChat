# 02: Domain Entities

Источник типов: `src/lib/types.ts`.

## Пользователи

- `User` - профиль пользователя, роль, presence, настройки, ограничения аккаунта; push-токены `fcmTokens` (FCM) и `voipTokens` (iOS PushKit для нативного incoming-call UI), а также `profileQrLink` (персональная ссылка для QR/шаринга профиля).
- `UserAccountBlock` - флаг/срок/причина блокировки.
- `UserLiveLocationShare` - состояние активной трансляции геопозиции.

## Чаты

- `Conversation` - чат (личный/групповой), участники, last-message, unread, pinned/reactions; для reaction-навигации хранит `lastReactionEmoji`, `lastReactionTimestamp`, `lastReactionSenderId`, `lastReactionMessageId`, `lastReactionParentId`, `lastReactionSeenAt`; опционально `e2eeEnabled`, `e2eeKeyEpoch`, `e2eeEnabledAt`.
- `ChatMessage` - сообщение, вложения, reply context, тред-метаданные (`threadCount`, `lastThreadMessage*`, `threadParticipantIds` для аватаров ответивших), реакции, геолокация; опционально `e2ee` (ciphertext, без plaintext на сервере).
- `ChatEmojiBurstEvent` - одноразовое событие fullscreen-анимации для single-emoji сообщений (`eventId`, `emoji`, `by`, `at`), хранится в `ChatMessage.emojiBurst` и используется для синхронизации эффекта между клиентами.
- `ChatMediaNorm` - статус серверной нормализации медиа во вложениях сообщения: `pending | done | failed`, список `failedIndexes`, `updatedAt`.
- `ChatMessageE2eePayload`, `E2eeSessionDoc`, `E2eeKeyWrapEntry`, `UserE2eePublicDoc` — структуры E2E (см. `src/lib/e2ee/`).
- `ChatAttachment` - вложение (url/type/size + опциональная media metadata).
- `ReplyContext` — в E2E-режиме поле `text` может отсутствовать (превью из расшифровки на клиенте). `PinnedMessage`, `ReactionDetail` — вспомогательные структуры сообщений.
- `ChatFolder` - логическая папка в боковой панели.

## Звонки и встречи

- `Call` - 1:1 звонок (caller/receiver, offer/answer, timestamps). Статусы: `calling` (дозвон), `ongoing` (активный), `ended` (завершён после активной фазы), `cancelled` (отменён/отклонён до соединения), `missed` (непринятый; авто-таймаут 60с или отмена инициатором во время дозвона), `rejected` (legacy-значение для старых документов). Поле `endedBy` (uid) фиксирует, кто завершил/сбросил звонок, чтобы клиент корректно маппил `missed/cancelled` для разных ролей.
- `Meeting` - встреча (host/adminIds/status/privacy).
- `MeetingSignal` - signaling payload для WebRTC во встрече.
- `MeetingMessage` - чат-сообщение встречи.
- `MeetingPoll` - опрос встречи и **тот же тип документа** для опросов в чате (`conversations/{id}/polls/{pollId}`): поля `question`, `options`, `creatorId`, `status`, `isAnonymous`, `votes` (uid → один индекс или массив индексов при множественном выборе), опционально `description`, `allowMultipleAnswers`, `allowAddingOptions`, `allowRevoting`, `shuffleOptions`, `quizMode`, `correctOptionIndex`, `quizExplanation`, `closesAt` (ISO). Создание: веб `ChatAttachPollDialog` + `chatPollFirestoreFields`, мобильный `ChatPollCreatePayload` + `ChatRepository.sendChatPollMessage`. Подсчёт голосов и порядок строк при shuffle: `src/lib/chat-poll-votes.ts` / `mobile/.../chat_poll_vote_utils.dart`.
- `MeetingJoinRequest` - запрос доступа в приватную встречу.

## Уведомления и настройки

- `Notification` - in-app уведомление пользователя.
- `ChatSettings`, `NotificationSettings`, `PrivacySettings` - пользовательские настройки клиента (`PrivacySettings.e2eeForNewDirectChats` — авто-E2E для новых личных чатов). В `ChatSettings` добавлен `emojiBurstAnimationProfile: 'lite' | 'balanced' | 'cinematic'` для управления fullscreen single-emoji эффектом.
- `GroupInvitePolicy` - политика приглашения в групповые чаты.

## Индексы и служебные документы

- `UserChatIndex` - список чатов пользователя + конфигурация папок.
- `UserContactsIndex` - контакты пользователя и consent-флаги; включает `contactIds[]` и локальные представления `contactProfiles.{contactUserId}` (`firstName`, `lastName`, `displayName`, `updatedAt`), которые используются в UI как персональное имя контакта (видно только владельцу списка).
- `UserCallsIndex` - список call id пользователя.
- `UserMeetingsIndex` - список meeting id пользователя.
- `PlatformSettingsDoc`, `PlatformStoragePolicy` - платформенные настройки квот/retention.

## Mini apps / Игры

- `GameSession` - сессия мини-приложения внутри чата (напр. “Дурак”): хранится в `games/{gameId}` и создаётся сервером (Cloud Functions). Доступ на чтение — только участникам (uid ∈ `playerIds`).
  - Для “Дурака” игра имеет публичное представление `publicView` (фаза раунда, стол, счётчики рук, фактическая `trumpCard`, `currentThrowerUid`, `turnUid`, `turnKind`, `roundDefenderHandLimit`, `canFinishTurn`) и приватные документы рук `privateHands/{uid}`.
  - `privateHands/{uid}.legalMoves` — серверно рассчитанный список разрешённых действий игрока (`attackCardKeys`, `transferCardKeys`, `defenseTargets`, `canTake`, `canPass`, `canFinishTurn`) с `revision`; web/mobile используют его как основной источник правил, а локальные проверки оставляют только как fallback для старых партий.
  - Лобби “Дурака” работает как ready-room: `readyUids[]`, `readyDeadlineAt` и список `playerIds[]`. `startDurakGame` используется как действие Ready; когда все текущие игроки готовы, сервер стартует партию. Если `readyDeadlineAt` истёк, неготовые игроки удаляются из комнаты ожидания, и партия стартует без них при наличии минимум двух готовых.
  - Новые партии “Дурака” стартуют с 6 картами на игрока; добор после раунда также ведётся до 6.
  - Результат завершённой партии фиксируется в `result` + `finishedAt`. Ход `surrender` завершает активную партию немедленно: сдающийся становится `loserUid`, остальные игроки — `winners`, `placements` формируются как победители и затем сдающийся.

## Где смотреть серверные типы

- `functions/src/lib/types.ts` - укороченный набор типов для Cloud Functions.
- При несовпадении приоритет у клиентских доменных типов (`src/lib/types.ts`) и фактической схемы Firestore.
