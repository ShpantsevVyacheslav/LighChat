# 01: Codebase Map

## Frontend (Next.js)

- `src/app` - маршруты App Router, page/layout, route handlers.
  - `dashboard/*` - основная защищённая зона (chat/meetings/calls/admin/settings/contacts).
  - `u/[username]` - публичный SSR-route профиля контакта для внешних preview (Telegram/WhatsApp) с `generateMetadata` (`og:*`, `twitter:*`) и кнопкой перехода в LighChat.
  - `dashboard/features` - раздел «Возможности LighChat» (оглавление + 12 подстраниц `/dashboard/features/[topic]`); welcome-оверлей `FeaturesWelcomeOverlay` показывается один раз после регистрации (флаг `lc_features_welcome_v1` в `localStorage`, не пересекается с `PwaOnboarding`).
  - `page.tsx` (корень `/`) - публичный маркетинговый лендинг для сторов: hero + бейджи App Store / Google Play (заглушки), подробное описание всех 12 фич с переиспользуемыми мокапами `components/features/*`, кнопка «Войти» ведёт на `/auth`. Билингв через `components/landing/landing-content.ts`.
  - `auth/` - страница авторизации/регистрации (`/auth`): QR-вход, email+пароль, Google/Apple/Telegram/Yandex; OAuth-подпути `auth/yandex` и `auth/telegram`. Логаут и dashboard-guard ведут сюда; неавторизованные пользователи на закрытых маршрутах редиректятся на `/auth`.
  - `meetings/[meetingId]` - вход в комнату встречи.
  - `api/giphy/search/route.ts` - серверный прокси к GIPHY API (gifs + animated stickers; ENV `GIPHY_API_KEY`).
- `src/components` - UI-компоненты по доменам.
  - `features/*` - модуль раздела «Возможности»: манифест тем (`features-data.ts`), билингвальный контент (`features-content.ts`), мини-мокапы интерфейса (`mocks/*`, `illustrations/*`, всего 12 тем + hero-композит), оглавление, страница темы, welcome-оверлей. Мокапы собраны из тех же дизайн-токенов и компонентов, что боевой UI (Card, Switch, glass-классы из `auth-glass-classes.ts`).
  - `chat/*` - окно чата, ввод, контекстные действия, медиа, 1:1 call overlay.
  - `chat/conversation-pages/ConversationGamesPanel.tsx`, `chat/games/durak/*` - web-вход в игры из профиля беседы и responsive-стол “Дурака”.
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
- `functions/src/triggers/scheduler/*` - периодические задачи (в т.ч. `cleanupDurakReadyRooms`, `cleanupDurakTurnTimeouts` для game-lobby/turn-timeout жизненного цикла “Дурака”).

## Rules and infra files

- `firestore.rules` - основные Firestore rules.
- `src/firestore.rules` - дублирующая копия rules (должна совпадать с корнем).
- `storage.rules` - Firebase Storage rules.
- `firestore.indexes.json` - Firestore composite/collection-group индексы.
- `firebase.json`, `.firebaserc` - конфиг Firebase deploy/runtime.

## Legal documentation

- `docs/legal/ru/*.md`, `docs/legal/en/*.md` - **источник правды** для всех юридических документов (Privacy Policy, Terms of Service, Cookie Policy, EULA, DPA, Children Policy, Content Moderation Policy, Acceptable Use Policy). Версионируется в репо. См. `docs/legal/README.md` для матрицы применимости и плейсхолдеров для юриста.
- `src/app/legal/[slug]/page.tsx`, `src/app/legal/page.tsx`, `src/app/legal/legal-document-view.tsx`, `src/app/legal/legal-index-view.tsx` - web-роуты `/legal` и `/legal/<slug>` (server component читает MD из `docs/legal/<lang>/<slug>.md`, клиентская обёртка переключает язык через `useI18n()`).
- `src/lib/legal/{slugs,load,render}.tsx` - список slug'ов, `server-only` загрузчик MD и минималистичный MD-рендерер (без новых deps).
- `src/components/landing/cookie-banner.tsx`, `src/components/landing/legal-footer-links.tsx` - cookie banner на лендинге (`localStorage` ключ `lc_cookie_consent_v1`) и блок ссылок на юр.документы в футере.
- `src/app/page.tsx` - в registration-диалоге над кнопкой submit подпись «By signing up you agree to ToS / Privacy» со ссылками на `/legal/*`.
- `mobile/app/assets/legal/{ru,en}/*.md` - те же документы, забандлены как Flutter-ассеты (см. `pubspec.yaml`).
- `mobile/app/lib/features/legal/data/legal_documents.dart` - список slug'ов и загрузка MD из ассетов с fallback'ом на другой язык.
- `mobile/app/lib/features/legal/ui/{markdown_view,legal_document_screen}.dart` - lightweight MD-рендерер (поддерживает headings/lists/blockquotes/tables/links) и экраны `/legal` (индекс) и `/legal/:slug` (документ). Routes регистрируются в `app_router.dart` и проп welcome-redirect-а пускает их без авторизации.
- `mobile/app/lib/features/auth/ui/register_form.dart`, `mobile/app/lib/features/auth/ui/auth_screen.dart` - чекбокс согласия на регистрации и кнопка «Privacy policy» открывают in-app экран `/legal/<slug>` через `GoRouter.push` (раньше — `launchUrl` на отсутствующий `lighchat.app/privacy`).
- `mobile/app/lib/features/chat/ui/chat_account_screen.dart` - пункт меню «Правовая информация» (`legal_settings_section_title`) ведёт на `/legal`.

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
  - `lib/features/settings/ui/storage_settings_screen.dart`, `lib/features/settings/data/storage_cache_manager.dart` - экран «Хранилище» с разбивкой кэша по чатам/файлам, очисткой (весь кэш/по чату/по файлу), лимитом объёма и политиками локального хранения.
  - `lib/features/settings/ui/energy_saving_screen.dart`, `lib/features/settings/data/energy_saving_preference.dart` - экран «Энергосбережение» (паритет с Telegram): слайдер порога заряда (Off/5/10/15/20/25/Always) + 7 тумблеров ресурсоёмких процессов (autoplay video/GIF, animated stickers/emoji, interface animations, media preload, background update). `EnergySavingNotifier` (riverpod) персистит флаги в `SharedPreferences` под ключами `energySaving.*`, слушает `battery_plus.onBatteryStateChanged` и `isInBatterySaveMode` (Android Power Save / iOS Low Power Mode). Геттер `isLowPowerActive` = (системный saver) ИЛИ (порог достигнут) ИЛИ (`always`); `effective*`-геттеры возвращают `false`, когда `isLowPowerActive`. Точки интеграции в feature-коде: `MessageVideoAttachment._maybeAutoPlay` (пауза autoplay), `_ChatMessageListState._triggerEmojiBurst` (пропуск анимации). Точка входа в меню — `chat_account_screen.dart`, пункт `account_menu_energy_saving`. Маршрут `/settings/energy-saving` в `app_router.dart`.
  - `lib/features/chat/data/local_storage_preferences.dart` - централизованные флаги того, какие типы данных можно сохранять локально (E2EE media/text, черновики, офлайн-снимки, видеокэш и т.д.).
  - `lib/features/chat/data/local_cache_entry_registry.dart` - локальный реестр соответствий `cache-file -> conversationId/messageId` для корректной привязки video/thumbnail кэша к чатам в экране «Хранилище».
  - `lib/features/chat/ui/conversation_games_screen.dart`, `conversation_durak_entry_screen.dart`, `conversation_durak_*`, `durak_*` - mobile-вход `Игры -> Дурак`, лобби/турниры и игровой стол “Дурака”.
  - `lib/features/chat/data/chat_settings_repository.dart` - чтение/запись `users.chatSettings` и `users.customBackgrounds`, upload фонов в Storage.
  - `lib/features/chat/data/secret_chat_callables.dart` - mobile callable-клиент секретных чатов; на iOS использует прямой HTTPS-POST через `firebase_callable_http.dart`, чтобы не вызывать `cloud_functions` SDK в Release-сборке.
  - `lib/features/chat/ui/message_attachments.dart`, `lib/features/chat/data/chat_attachment_mosaic_layout.dart` - альбомные фото в сообщении (мозаика по числу и пропорциям).
  - `lib/features/chat/data/chat_media_gallery.dart`, `lib/features/chat/ui/chat_media_viewer_screen.dart` - полноэкранная галерея фото/видео из чата (фильтр как веб `isGridGalleryAttachment`, размытый фон, жесты, меню Ответить/Переслать/Сохранить/Удалить); зависимость `share_plus` для «Сохранить».
  - `lib/features/chat/ui/composer_sticker_gif_sheet.dart`, `lib/features/chat/data/user_sticker_packs_repository.dart`, `lib/features/chat/data/giphy_gif_search.dart`, `lib/features/chat/data/giphy_cache_store.dart`, `lib/features/chat/data/giphy_proxy_config.dart`, `lib/features/chat/data/recent_stickers_store.dart` - стикеры/GIF/эмодзи в композере: 3 вкладки (Эмодзи / Стикеры / GIF), паки `users/*/stickerPacks` и `publicStickerPacks`, GIPHY-прокси через `GIPHY_PROXY_BASE_URL` (по умолчанию `https://lighchat.online`), trending-кеш 24h, последние 30 GIF, эмодзи-фильтры, unicode-пикер `emoji_picker_flutter`, анимированные эмодзи через GIPHY stickers.
  - `lib/features/chat/data/link_preview_metadata.dart`, `lib/features/chat/data/link_preview_url_extractor.dart`, `lib/features/chat/data/link_preview_diagnostics.dart` - OG-скрейпинг ссылок (Future-identity cache, facebookexternalhit UA, поддержка og:video) и детектор мерцания skeleton↔content для отлова scroll-регрессий.
  - `lib/features/chat/data/video_attachment_diagnostics.dart` - диагностика стабильности aspect ratio для inline-видео (детектор AR-скачков, summary в dispose чата).
  - `lib/features/chat/ui/message_link_preview_card.dart`, `lib/features/chat/ui/composer_link_preview.dart` - UI карточки link preview в ленте сообщений и предпросмотр в композере; inline video player для og:video mp4/webm с poster из og:image.
  - `lib/features/chat/ui/composer_formatting_toolbar.dart`, `lib/features/chat/data/composer_html_editing.dart`, `lib/features/chat/data/sanitize_message_html.dart` - форматирование сообщений (HTML как на веб TipTap).
  - `lib/features/chat/ui/chat_incoming_call_entry_screen.dart` - route `/calls/incoming/:callId` для входа из системного incoming-call UI: загружает `calls/{id}` и открывает `ChatAudioCallScreen`/`ChatVideoCallScreen` с `existingCallId`.
  - `lib/features/push/push_native_call_service.dart` - интеграция native incoming-call UI (`flutter_callkit_incoming`), события `Accept/Decline/Timeout`, навигация в `/calls/incoming/:callId`, синхронизация iOS VoIP токена в `users/{uid}.voipTokens`.
  - `ios/Runner/AppDelegate.swift` - PushKit delegate для iOS VoIP push (`didUpdate credentials`, `didReceiveIncomingPushWith`), bridge в CallKit.
  - `lib/features/auth/ui/profile_screen.dart` - страница «Мой профиль» (редактирование базовых полей пользователя).
  - `lib/features/features_tour/*` - раздел «Возможности LighChat» в mobile: 12 подстраниц на маршруте `/features` и `/features/:topic` (паритет с web `dashboard/features`); 12 мини-мокапов в `ui/feature_mocks.dart` повторяют визуал mobile-UI; `data/features_tour_storage.dart` хранит per-uid флаг `features_tour_shown_<uid>` в `SharedPreferences`. После welcome-анимации `_exitToChats()` редиректит на `/features?source=welcome` при `!FeaturesTourStorage.isShownFor(uid)`, иначе на `/chats`. Точка входа из меню аккаунта (`chat_account_screen.dart`, пункт `account_menu_features`).
- `mobile/packages/lighchat_models` - доменные модели/DTO и мапперы (контракты Firestore на стороне Flutter).
- `mobile/packages/lighchat_firebase` - слой доступа к Firebase (Auth/Firestore/FCM/Functions) для Flutter-клиента; `ChatRepository.createGroupChat` + callable `checkGroupInvitesAllowed` (паритет с web). На iOS часть callable-вызовов (`checkGroupInvitesAllowed`, secret-chat vault/unlock/media callables, игровые callables, voice transcription) идёт в обход плагина `cloud_functions` через `firebase_callable_http.dart` (прямой HTTPS-POST), т.к. SDK `FirebaseFunctions 12.9.0` крашит Release-сборку в `_swift_task_dealloc_specific (.cold.2)` на параллельных `async let` внутри `FunctionsContext`.
- `mobile/packages/lighchat_ui` - дизайн-система Flutter (темы/типографика/общие виджеты).
