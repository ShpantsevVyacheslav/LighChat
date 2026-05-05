# Карта экранов мобильного приложения (Flutter)

Актуально для `mobile/app` на 2026-04-14.

## 1) Основные экраны по маршрутам `GoRouter`

Источник: [`mobile/app/lib/app_router.dart`](../../mobile/app/lib/app_router.dart).

| Путь | Экран (Widget) | Файл |
|---|---|---|
| `/auth` | `AuthScreen` | [`auth_screen.dart`](../../mobile/app/lib/features/auth/ui/auth_screen.dart) |
| `/auth/google-complete` | `GoogleCompleteProfileScreen` | [`google_complete_profile_screen.dart`](../../mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart) |
| `/chats` | `ChatListScreen` | [`chat_list_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_list_screen.dart) |
| `/contacts` | `ChatContactsScreen` | [`chat_contacts_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_contacts_screen.dart) |
| `/calls` | `ChatCallsScreen` | [`chat_calls_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_calls_screen.dart) |
| `/calls/:callId` | `ChatCallDetailScreen` | [`chat_call_detail_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_call_detail_screen.dart) |
| `/meetings` | `ChatMeetingsScreen` | [`chat_meetings_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_meetings_screen.dart) |
| `/account` | `ChatAccountScreen` | [`chat_account_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_account_screen.dart) |
| `/profile` | `ProfileScreen` | [`profile_screen.dart`](../../mobile/app/lib/features/auth/ui/profile_screen.dart) |
| `/settings/chats` | `ChatSettingsScreen` | [`chat_settings_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_settings_screen.dart) |
| `/settings/notifications` | `ChatNotificationsScreen` | [`chat_notifications_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_notifications_screen.dart) |
| `/settings/privacy` | `ChatPrivacyScreen` | [`chat_privacy_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_privacy_screen.dart) |
| `/settings/energy-saving` | `EnergySavingScreen` | [`energy_saving_screen.dart`](../../mobile/app/lib/features/settings/ui/energy_saving_screen.dart) |
| `/chats/new` | `NewChatScreen` | [`new_chat_screen.dart`](../../mobile/app/lib/features/chat/ui/new_chat_screen.dart) |
| `/chats/new/group` | `NewGroupChatScreen` | [`new_group_chat_screen.dart`](../../mobile/app/lib/features/chat/ui/new_group_chat_screen.dart) |
| `/chats/forward` | `ChatForwardScreen` | [`chat_forward_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_forward_screen.dart) |
| `/chats/:conversationId` | `ChatScreen` | [`chat_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_screen.dart) |
| `/chats/:conversationId/threads` | `ConversationThreadsScreen` | [`conversation_threads_screen.dart`](../../mobile/app/lib/features/chat/ui/conversation_threads_screen.dart) |
| `/chats/:conversationId/thread/:parentMessageId` | `ThreadScreen` | [`thread_screen.dart`](../../mobile/app/lib/features/chat/ui/thread_screen.dart) |

### Примечания по UI

- 2026-04-22: экран `/settings/notifications` приведён к типографике `/settings/chats` (уменьшены размеры шрифтов), в блоке «Тихие часы» убран разделитель между тумблером и временем, подписи «С/До» удалены.
- 2026-04-22: экран `/profile` (и режим редактирования) — фон теперь заполняет шапку на iOS (без «чёрной» зоны), заголовок «Профиль» белый и выровнен влево, аватар в режиме редактирования клипуется строго в круг без белых краёв.
- 2026-04-22: экран `/settings/privacy` — типографика приведена к базовым размерам как на других настройках, убраны описания под заголовком и под блоком «Сквозное шифрование», обновлён текст переключателя E2E, тумблеры сделаны голубыми как на экране уведомлений, блок «Приглашения в группы» очищен от лишних описаний.
- 2026-04-22: экран “Медиа, ссылки и файлы” в профиле собеседника — вкладка «Кружки» теперь отображается сеткой как на вебе (круглые превью с play, inline-раскрытие выбранного кружка).
- 2026-04-22: после создания группового чата Back/свайп на iOS ведёт в список диалогов (экран создания группы не остаётся в истории).
- 2026-04-22: мобильный чат — добавлено превью ссылок (OG/title/description/image) внутри текстовых сообщений (с кешированием и безопасным фоллбеком).
- 2026-04-22: список диалогов — для новых чатов без сообщений показывается «Пока нет сообщений» (вместо «История очищена»).
- 2026-04-22: мобильный чат — inline-видео теперь автопроигрывается как в Telegram (старт/пауза по видимости, правильные пропорции, fullscreen опционален).
- 2026-04-22: мобильный групповой чат — добавлены @-упоминания участников с подсказками (вставка как `data-chat-mention`, паритет с веб).
- 2026-04-22: запись видеокружка (`_VideoCircleCapturePage`) — зеркало селфи в файле через FFmpeg с логами и fallback без аудио; превью задней камеры в круге с тем же `BoxFit.cover`, что и фронт (без скачка «зума» при первом переключении); во время записи доступны пауза/продолжение (`pauseVideoRecording` / `resumeVideoRecording`) и таймер учитывает паузы.
- 2026-04-22: тап по @-упоминанию в группе открывает профиль участника; в профиле есть пункт «Написать лично» (открывает личный чат).
- 2026-04-22: отправка видео — если исходник больше 720p, перед загрузкой автоматически сжимается до max 1280×720 (без апскейла); если уже ≤720p, отправляется оригинал.
- 2026-04-22: композер в групповых чатах — исправлено отображение HTML-тегов после @упоминаний (теги больше не «съедают» место и не скрывают часть текста); inline-видео увеличено (превью ×1.5), при автоплее показаны длительность (слева сверху) и кнопка звука (справа сверху).
- 2026-04-22: видео — вертикальные ролики в превью получают корректное соотношение сторон по фактическому размеру плеера; fullscreen видео стартует сразу (без ожидания полной докачки в кэш), а edge-навигация по краям не перехватывает клики по кнопкам управления; в превью убрана нижняя дублирующая кнопка звука.
- 2026-04-22: видео — кэш первого кадра для сетевых роликов стал memory+disk (меньше перезагрузок при скролле); в чат-превью первый кадр рисуется из кэша; таймер в превью показывает обратный отсчёт; горизонтальные видео превью в чате уменьшены на 25% относительно текущего увеличения; в fullscreen шапка скрывается вместе с контролами плеера.
- 2026-04-22: упоминания в групповом чате — композер больше не хранит HTML-теги в тексте: упоминания кодируются токенами и конвертируются в `<span data-chat-mention="...">` только при отправке; высота строки ввода и круглых кнопок уменьшена, текст вертикально центрирован.
- 2026-04-22: вставка из буфера — при вставке обычного текста/URL больше не создаётся псевдо-вложение `clipboard_*.txt`; plain-text URL в сообщениях авто-распознаётся и становится кликабельным, а превью ссылки не блокируется «лишним» вложением.
- 2026-04-22: голосовые — добавлена запись удержанием на иконке микрофона как в Telegram (удержал → запись, свайп влево → отмена, отпустил → отправка) поверх текущего режима записи через экран.
- 2026-04-22: нижнее меню — при перетаскивании «пилюля» теперь слегка выходит за границы рамки, по краям появляется более выраженный стеклянный blur/блик, а внутренняя рамка под формой немного сужается (поведение как на референсе).

## 1.1) Единый тёмный фон (backdrop)

В тёмной теме **фон страниц должен совпадать с экраном списка чатов**. Для экранов, которые “сидят на фоне”, используется `AuthBackground`, который теперь делегирует отрисовку фона в общий виджет `AppBackdrop`:

- `mobile/app/lib/features/auth/ui/auth_glass.dart` (`AuthBackground`)
- `mobile/app/lib/ui/app_backdrop.dart` (`AppBackdrop`)

## 2) Полноэкранные экраны, открываемые через `Navigator.push`

Эти экраны не имеют собственного URL, но являются отдельными страницами.

| Экран (Widget) | Где открывается | Файл |
|---|---|---|
| `ChatPartnerProfileSheet` (в режиме `fullScreen: true`) | из `ChatScreen` по тапу в шапке чата | [`chat_partner_profile_sheet.dart`](../../mobile/app/lib/features/chat/ui/chat_partner_profile_sheet.dart) |
| `ChatAudioCallScreen` | из `ChatScreen` (аудиокнопка/входящий баннер) | [`chat_audio_call_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_audio_call_screen.dart) |
| `ConversationStarredScreen` | из профиля собеседника (`Избранное`) | [`conversation_starred_screen.dart`](../../mobile/app/lib/features/chat/ui/conversation_starred_screen.dart) |
| `ConversationMediaLinksFilesScreen` | из профиля собеседника (`Медиа, ссылки и файлы`) | [`conversation_media_links_files_screen.dart`](../../mobile/app/lib/features/chat/ui/conversation_media_links_files_screen.dart) |
| `ChatConversationNotificationsScreen` | из профиля собеседника (`Уведомления`) | [`chat_conversation_notifications_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_conversation_notifications_screen.dart) |
| `ChatMediaViewerScreen` | из `ChatScreen` / `ThreadScreen` / `ConversationMediaLinksFilesScreen` | [`chat_media_viewer_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_media_viewer_screen.dart) |
| `SharedLocationMapScreen` | тап по карточке геолокации | [`shared_location_map_screen.dart`](../../mobile/app/lib/features/chat/ui/shared_location_map_screen.dart) |
| `ChatVlcFullscreenViewer` / `_ChatAvPlayerVideoScreen` | тап по видео-вложению | [`chat_vlc_network_media.dart`](../../mobile/app/lib/features/chat/ui/chat_vlc_network_media.dart), [`message_video_attachment.dart`](../../mobile/app/lib/features/chat/ui/message_video_attachment.dart) |
| `_VideoCircleCapturePage` | запись видеокружка (`pushVideoCircleCapturePage`) | [`video_circle_capture_page.dart`](../../mobile/app/lib/features/chat/ui/video_circle_capture_page.dart) |
| `_RegisterFullScreenPage` | из auth-экрана при регистрации email/password | [`auth_screen.dart`](../../mobile/app/lib/features/auth/ui/auth_screen.dart) |

## 3) Модальные экраны/шторки (`BottomSheet` / `Dialog`)

### 3.1 Bottom sheets

| API / контент | Назначение | Файл |
|---|---|---|
| `showComposerAttachmentOverlay(...)` (`ComposerAttachmentMenuPanel`) | меню скрепки в чате | [`composer_attachment_menu.dart`](../../mobile/app/lib/features/chat/ui/composer_attachment_menu.dart) |
| `showPhotoVideoSourceSheet(...)` | выбор источника фото/видео | [`photo_video_source_sheet.dart`](../../mobile/app/lib/features/chat/ui/photo_video_source_sheet.dart) |
| `showShareLocationSettingsSheet(...)` | выбор длительности шаринга локации | [`share_location_sheet.dart`](../../mobile/app/lib/features/chat/ui/share_location_sheet.dart) |
| `showLocationSendPreviewSheet(...)` | превью и подтверждение отправки локации | [`location_send_preview_sheet.dart`](../../mobile/app/lib/features/chat/ui/location_send_preview_sheet.dart) |
| `showChatPollCreateSheet(...)` | создание опроса | [`chat_poll_create_sheet.dart`](../../mobile/app/lib/features/chat/ui/chat_poll_create_sheet.dart) |
| `showComposerStickerGifSheet(...)` | стикеры/GIF | [`composer_sticker_gif_sheet.dart`](../../mobile/app/lib/features/chat/ui/composer_sticker_gif_sheet.dart) |
| `showComposerLinkSheet(...)` | ввод ссылки при форматировании | [`composer_link_sheet.dart`](../../mobile/app/lib/features/chat/ui/composer_link_sheet.dart) |
| `_openNewSheet()` в `ChatListScreen` | шторка «Новая папка / Новый чат» | [`chat_list_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_list_screen.dart) |

### 3.2 Dialog/GeneralDialog

| API / контент | Назначение | Файл |
|---|---|---|
| `showMessageContextMenu(...)` | контекстное меню сообщения + реакции | [`message_context_menu.dart`](../../mobile/app/lib/features/chat/ui/message_context_menu.dart) |
| `showGeneralDialog` в `MessageReactionsRow` | мини-модалка со списком пользователей реакции | [`message_reactions_row.dart`](../../mobile/app/lib/features/chat/ui/message_reactions_row.dart) |
| `showDialog` в `ThreadScreen` | подтверждения удаления/действий в треде | [`thread_screen.dart`](../../mobile/app/lib/features/chat/ui/thread_screen.dart) |
| `showDialog` в `ChatScreen` | подтверждения удаления/действий | [`chat_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_screen.dart) |
| `_promptFolderName()` | диалог ввода имени папки | [`chat_list_screen.dart`](../../mobile/app/lib/features/chat/ui/chat_list_screen.dart) |

## 4) Экраны/файлы, которые есть в проекте, но не являются маршрутами

| Файл | Статус |
|---|---|
| [`sign_in_screen.dart`](../../mobile/app/lib/features/auth/ui/sign_in_screen.dart) | отдельный auth-экран, не подключён в `app_router.dart` |
| [`chat_account_menu_sheet.dart`](../../mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart) | меню-виджет, отдельным роутом не открывается |
| [`message_action_sheet.dart`](../../mobile/app/lib/features/chat/ui/message_action_sheet.dart) | helper-файл шторки действий сообщения (не основной вход) |

## 5) Краткая навигационная схема

1. Авторизация: `/auth` -> (при Google и неполном профиле) `/auth/google-complete` -> `/chats`.
2. Основной контур: `/chats` <-> `/contacts` <-> `/account` (нижняя навигация).
3. Из `/account`: `/profile`, `/settings/chats`, `/settings/notifications`, `/settings/privacy`.
4. Из `/chats`: `/chats/new`, `/chats/new/group`, `/chats/:conversationId`.
5. Из чата: `threads`, `thread/:parentMessageId`, `forward`, fullscreen-профиль, аудиозвонок, медиа/карты/модалки.

