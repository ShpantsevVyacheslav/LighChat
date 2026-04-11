# 02: Domain Entities

Источник типов: `src/lib/types.ts`.

## Пользователи

- `User` - профиль пользователя, роль, presence, настройки, ограничения аккаунта.
- `UserAccountBlock` - флаг/срок/причина блокировки.
- `UserLiveLocationShare` - состояние активной трансляции геопозиции.

## Чаты

- `Conversation` - чат (личный/групповой), участники, last-message, unread, pinned/reactions; опционально `e2eeEnabled`, `e2eeKeyEpoch`, `e2eeEnabledAt`.
- `ChatMessage` - сообщение, вложения, reply context, тред-метаданные, реакции, геолокация; опционально `e2ee` (ciphertext, без plaintext на сервере).
- `ChatMessageE2eePayload`, `E2eeSessionDoc`, `E2eeKeyWrapEntry`, `UserE2eePublicDoc` — структуры E2E (см. `src/lib/e2ee/`).
- `ChatAttachment` - вложение (url/type/size + опциональная media metadata).
- `ReplyContext` — в E2E-режиме поле `text` может отсутствовать (превью из расшифровки на клиенте). `PinnedMessage`, `ReactionDetail` — вспомогательные структуры сообщений.
- `ChatFolder` - логическая папка в боковой панели.

## Звонки и встречи

- `Call` - 1:1 звонок (caller/receiver, статус, offer/answer, timestamps).
- `Meeting` - встреча (host/adminIds/status/privacy).
- `MeetingSignal` - signaling payload для WebRTC во встрече.
- `MeetingMessage` - чат-сообщение встречи.
- `MeetingPoll` - опрос встречи.
- `MeetingJoinRequest` - запрос доступа в приватную встречу.

## Уведомления и настройки

- `Notification` - in-app уведомление пользователя.
- `ChatSettings`, `NotificationSettings`, `PrivacySettings` - пользовательские настройки клиента (`PrivacySettings.e2eeForNewDirectChats` — авто-E2E для новых личных чатов).
- `GroupInvitePolicy` - политика приглашения в групповые чаты.

## Индексы и служебные документы

- `UserChatIndex` - список чатов пользователя + конфигурация папок.
- `UserContactsIndex` - контакты пользователя и consent-флаги.
- `UserCallsIndex` - список call id пользователя.
- `UserMeetingsIndex` - список meeting id пользователя.
- `PlatformSettingsDoc`, `PlatformStoragePolicy` - платформенные настройки квот/retention.

## Где смотреть серверные типы

- `functions/src/lib/types.ts` - укороченный набор типов для Cloud Functions.
- При несовпадении приоритет у клиентских доменных типов (`src/lib/types.ts`) и фактической схемы Firestore.
