# 01: Codebase Map

## Frontend (Next.js)

- `src/app` - маршруты App Router, page/layout, route handlers.
  - `dashboard/*` - основная защищённая зона (chat/meetings/calls/admin/settings/contacts).
  - `meetings/[meetingId]` - вход в комнату встречи.
  - `api/tenor/search/route.ts` - серверный прокси к Tenor API.
- `src/components` - UI-компоненты по доменам.
  - `chat/*` - окно чата, ввод, контекстные действия, медиа, 1:1 call overlay.
  - `meetings/*` - комната, сайдбар, controls, чат и опросы встречи.
  - `dashboard/*`, `admin/*`, `auth/*`, `contacts/*`, `settings/*`, `ui/*`.
- `src/hooks` - клиентские хуки приложения (`use-auth`, `use-settings`, `use-meeting-webrtc`, `use-chat-main-draft-preview` для метки черновика в списке чатов, и т.д.).
- `src/contexts` - локальные React contexts для feature-state.

## Firebase integration layer

- `src/firebase/index.ts` - инициализация SDK, fallback-логика, экспорт firebase-хуков.
- `src/firebase/provider.tsx`, `client-provider.tsx` - провайдеры для React.
- `src/firebase/firestore/*` - generic/use-doc/use-collection и id-based подписки.
- `src/firebase/firestore-transport.ts` - транспорт Firestore (включая long polling policy).

## Server-side logic

- `src/actions/*` - Next server actions (админка, уведомления, link preview, storage stats).
- `functions/src/index.ts` - экспорт триггеров Cloud Functions.
- `functions/src/lib/apns-voip.ts` - HTTP/2 sender для APNs VoIP (JWT ES256 по `.p8` key) для входящих 1:1 звонков на iOS.
- `functions/src/triggers/auth/*` - auth lifecycle.
- `functions/src/triggers/http/*` - callable endpoints.
- `functions/src/triggers/firestore/*` - реакция на изменения коллекций.
- `functions/src/triggers/scheduler/*` - периодические задачи.

## Rules and infra files

- `firestore.rules` - основные Firestore rules.
- `src/firestore.rules` - дублирующая копия rules (должна совпадать с корнем).
- `storage.rules` - Firebase Storage rules.
- `firestore.indexes.json` - Firestore composite/collection-group индексы.
- `firebase.json`, `.firebaserc` - конфиг Firebase deploy/runtime.

## Desktop and tooling

- `electron/main.js`, `electron/preload.js` - desktop shell.
- `scripts/*` - утилиты генерации иконок/брендинга.
- `public/*` - статика и PWA-ассеты.

## Mobile (Flutter)

- `mobile/app` - Flutter приложение (iOS/Android) — новый клиент для стора.
  - `lib/features/chat/ui/chat_list_screen.dart` - список чатов, папки, поиск, empty-state, запуск нового чата.
  - `lib/features/chat/ui/chat_contacts_screen.dart` - отдельная страница контактов (`/contacts`), список контактов и синхронизация телефонной книги по phone/email.
  - `lib/features/chat/ui/new_chat_screen.dart`, `lib/features/chat/ui/new_group_chat_screen.dart` - новый личный чат (поиск с секциями «контакты / все пользователи») и создание группы; маршруты `/chats/new`, `/chats/new/group` в `lib/app_router.dart`.
  - `lib/features/chat/ui/conversation_threads_screen.dart`, `lib/features/chat/ui/thread_screen.dart` - список обсуждений (веток) и экран ветки; маршруты `/chats/:id/threads`, `/chats/:id/thread/:parentMessageId` в `lib/app_router.dart`; `chat_wallpaper_background.dart` — общий фон (обои/градиент) для основного чата и экрана ветки.
  - `lib/features/chat/data/new_chat_user_search.dart` - фильтр гостей (`guest_*@anonymous.com`), ru/latin-поиск и разбиение списка как на web (`splitUsersByContactsAndGlobalVisibility`).
  - `lib/features/chat/data/device_contact_lookup_keys.dart` - генерация lookup-ключей `registrationIndex` из контактов устройства (`p_*`, `e_*`).
  - `lib/features/chat/ui/chat_bottom_nav.dart`, `lib/features/chat/ui/chat_account_menu_sheet.dart` - нижняя навигация и аккаунт-меню по аватару.
  - `lib/features/chat/ui/chat_settings_screen.dart` - экран «Настройки чатов» (пресеты/превью/загрузка своих фонов).
  - `lib/features/chat/data/chat_settings_repository.dart` - чтение/запись `users.chatSettings` и `users.customBackgrounds`, upload фонов в Storage.
  - `lib/features/chat/ui/message_attachments.dart`, `lib/features/chat/data/chat_attachment_mosaic_layout.dart` - альбомные фото в сообщении (мозаика по числу и пропорциям).
  - `lib/features/chat/data/chat_media_gallery.dart`, `lib/features/chat/ui/chat_media_viewer_screen.dart` - полноэкранная галерея фото/видео из чата (фильтр как веб `isGridGalleryAttachment`, размытый фон, жесты, меню Ответить/Переслать/Сохранить/Удалить); зависимость `share_plus` для «Сохранить».
  - `lib/features/chat/ui/composer_sticker_gif_sheet.dart`, `lib/features/chat/data/user_sticker_packs_repository.dart` - стикеры/GIF в композере (паки `users/*/stickerPacks`, каталог `publicStickerPacks`, Tenor через `TENOR_PROXY_BASE_URL`).
  - `lib/features/chat/ui/composer_formatting_toolbar.dart`, `lib/features/chat/data/composer_html_editing.dart`, `lib/features/chat/data/sanitize_message_html.dart` - форматирование сообщений (HTML как на веб TipTap).
  - `lib/features/chat/ui/chat_incoming_call_entry_screen.dart` - route `/calls/incoming/:callId` для входа из системного incoming-call UI: загружает `calls/{id}` и открывает `ChatAudioCallScreen`/`ChatVideoCallScreen` с `existingCallId`.
  - `lib/features/push/push_native_call_service.dart` - интеграция native incoming-call UI (`flutter_callkit_incoming`), события `Accept/Decline/Timeout`, навигация в `/calls/incoming/:callId`, синхронизация iOS VoIP токена в `users/{uid}.voipTokens`.
  - `ios/Runner/AppDelegate.swift` - PushKit delegate для iOS VoIP push (`didUpdate credentials`, `didReceiveIncomingPushWith`), bridge в CallKit.
  - `lib/features/auth/ui/profile_screen.dart` - страница «Мой профиль» (редактирование базовых полей пользователя).
- `mobile/packages/lighchat_models` - доменные модели/DTO и мапперы (контракты Firestore на стороне Flutter).
- `mobile/packages/lighchat_firebase` - слой доступа к Firebase (Auth/Firestore/FCM/Functions) для Flutter-клиента; `ChatRepository.createGroupChat` + callable `checkGroupInvitesAllowed` (паритет с web). На iOS вызов `checkGroupInvitesAllowed` идёт в обход плагина `cloud_functions` через `firebase_callable_http.dart` (прямой HTTPS-POST), т.к. SDK `FirebaseFunctions 12.9.0` крашит Release-сборку в `_swift_task_dealloc_specific (.cold.2)` на параллельных `async let` внутри `FunctionsContext`.
- `mobile/packages/lighchat_ui` - дизайн-система Flutter (темы/типографика/общие виджеты).
