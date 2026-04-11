## Mobile chat rendering parity (Flutter)

### What is implemented
- **Message actions (long-press)**: bottom sheet — ответить, переслать, закрепить, выбрать (bulk), изменить (только свой текст), удалить (мягкое `isDeleted`, только свои). Реализация: `message_action_sheet.dart`, вызовы из `chat_screen.dart` в `ChatRepository` (`updateMessageText`, `softDeleteMessage`, `setPinnedMessages`, навигация на `/chats/forward`).
- **Bulk selection**: после «Выбрать» или из режима выбора — тап по пузырьку переключает выделение; верхняя панель — переслать выбранные или массовое удаление (только свои неудалённые). `chat_selection_app_bar.dart`.
- **Forward**: `ChatForwardScreen` (`/chats/forward`, `extra: List<ChatMessage>`) — предпросмотр текста, поиск; получатели: **группы** из индекса и **личные чаты только с контактами** (`userContacts.contactIds`), строка «в контактах без чата» открывает DM через `createOrOpenDirectChat`; чат «Избранное» (один участник — вы) **исключён**; имена/аватары из `users/*` и `Conversation.participantInfo` / `photoUrl` для групп.
- **Pins**: до 20 закреплённых, список как на веб (`pinnedMessages` + legacy `pinnedMessage` в модели); полоса превью `chat_pinned_strip.dart`, логика списка — `pinned_messages_helper.dart`.
- **Edited / forwarded UI**: у пузырька показывается «изм.» при непустом `updatedAt`; пересланные — строка «Переслано от …» по `forwardedFrom`.
- **Reply flow (send)**: long-press a message → «Ответить» → preview bar above composer → new message is written with `replyTo` in Firestore (same shape as web).
- **Message order / scrolling**: сортировка по `createdAt` + `id`, отображение через `ListView(reverse: true)` (новые у композера); после отправки — `animateTo(0)`; подгрузка истории у **верхнего** края списка; под шапку зарезервировано `MediaQuery.padding.top` + высота бара.
- **Date separators**: “СЕГОДНЯ / ВЧЕРА / dd.mm.yyyy”.
- **Reply preview**: renders `replyTo.senderName`, preview text, optional `mediaPreviewUrl`.
- **Deleted messages**: renders “Сообщение удалено” (no text/attachments/reactions).
- **Reactions**: renders chips from `reactions` map (emoji + count), highlights when the current user reacted.
- **Partner profile**: тап по аватару/заголовку в шапке → bottom sheet как на веб `ChatParticipantProfile` (упрощённо): строка статуса / `~username`, сворачиваемый блок «Контакты и данные» (email, телефон, день рождения, о себе, роль — с учётом `privacySettings` как на веб), «Добавить в контакты» (`userContacts` + `arrayUnion`), для групп — участники / редактирование (пока «скоро»), меню медиа/избранное/обсуждения/уведомления/тема/приватность/шифрование (большинство — «скоро»; счётчик «Медиа» из последних 100 сообщений), «Создать группу с…», «Покинуть группу» (скоро). Кнопка «Поделиться» копирует `conversationId` в буфер. Данные собеседника: расширенный `UserProfile` из `users/*`; шапка чата подтягивает онлайн/`lastSeen` и корректные заголовки для «Избранное».

### Files
- `mobile/app/lib/features/chat/data/reply_preview_builder.dart`: builds `ReplyContext` like web `getReplyPreview`; `buildPinnedMessageFromChatMessage` для закрепления.
- `mobile/app/lib/features/chat/data/pinned_messages_helper.dart`: лимит и сортировка закреплённых.
- `mobile/packages/lighchat_firebase/lib/src/chat_repository.dart`: `sendTextMessage(..., replyTo?)`, `updateMessageText`, `softDeleteMessage`, `setPinnedMessages`, `forwardMessagesToChats`.
- `mobile/app/lib/features/chat/ui/message_action_sheet.dart`, `chat_selection_app_bar.dart`, `chat_pinned_strip.dart`, `chat_forward_screen.dart`, `forward_message_preview.dart`.
- `mobile/app/lib/features/chat/data/forward_recipients.dart`, `user_contacts_repository.dart`, `saved_messages_chat.dart`.
- `mobile/app/lib/app_router.dart`: маршрут `/chats/forward`.
- `mobile/app/lib/features/chat/ui/composer_reply_banner.dart`: reply draft above input.
- `mobile/app/lib/features/chat/ui/chat_message_list.dart`: list layout + date separators + bubble composition.
- `mobile/app/lib/features/chat/ui/message_reply_preview.dart`: reply UI.
- `mobile/app/lib/features/chat/ui/message_deleted_stub.dart`: deleted UI.
- `mobile/app/lib/features/chat/ui/message_reactions_row.dart`: reactions UI.
- `mobile/app/lib/features/chat/ui/chat_partner_profile_sheet.dart`: профиль чата / собеседника.
- `mobile/app/lib/features/chat/data/user_profile.dart`, `profile_field_visibility.dart`, `user_chat_policy.dart`, `partner_presence_line.dart`, `phone_display.dart`, `relative_time_ru.dart`, `profile_attachment_stats.dart`.

### Data model notes
Flutter model `ChatMessage` is extended to parse:
- `replyTo` (ReplyContext)
- `isDeleted`
- `reactions` (legacy `string[]` or `{ userId, timestamp }[]`)

See: `mobile/packages/lighchat_models/lib/lighchat_models.dart` (в т.ч. опциональные поля `Conversation`: `description`, `adminIds`, `createdByUserId`, `e2eeEnabled`, `e2eeKeyEpoch` для сводки шифрования в профиле).

### Timestamp policy (IMPORTANT)
Mobile currently writes `createdAt` using **device time** (`Timestamp.now()` on the client) to match “time of sender device”.
This can drift if a device clock is wrong; if you later need canonical time, switch back to `serverTimestamp` and render a separate `clientCreatedAt`.

### How to test quickly
1. Open any chat with existing `replyTo`, `reactions`, `isDeleted` data.
2. Verify:
   - deleted messages show stub only
   - reply preview shows sender name + text
   - reactions chips show correct emoji counts
   - newest messages appear near the composer
3. Long-press: редактирование своего текста, удаление своего, закрепление, пересылка, вход в режим выбора.
4. В режиме выбора: переслать несколько сообщений; удалить только если все выбранные — ваши и не удалённые.
5. Закрепление: полоса сверху, снятие крестиком; не более 20 закреплённых.

