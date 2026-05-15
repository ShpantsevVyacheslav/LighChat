# AGENTS.md

Краткий входной файл для AI-агентов по проекту LighChat.

## Как работать с проектом

- Сначала прочитай `AGENTS.md`, затем `docs/arcitecture/00-project-overview.md`.
- Дальше открывай только профильные доки из `docs/arcitecture/*` под текущую задачу.
- Перед изменениями проверь актуальные типы в `src/lib/types.ts` и ограничения в `firestore.rules`.
- Для бэкенд-логики смотри `functions/src/index.ts` и соответствующие `functions/src/triggers/*`.

## Карта путей

- `src/app` - страницы Next.js App Router, layout-уровень, API route.
  - `src/app/u/[username]` - публичная SSR-страница контакта для внешних мессенджеров (Telegram/WhatsApp) с `og:*`-превью.
- `src/components` - UI и feature-компоненты (chat, meetings, admin, settings, contacts).
  - `src/components/chat/Secret*Dialog.tsx` + `src/components/dashboard/DashboardChatListColumn.tsx` - web-поток секретных чатов: создание, отдельный inbox, PIN-unlock, readonly-настройки и удаление.
- `src/hooks` - клиентские хуки состояния/поведения (auth, settings, notifications, webrtc).
  - `src/hooks/use-secret-chat-access-active.ts` - подписка на `conversations/{cid}/secretAccess/{uid}` для server-enforced unlock статуса в web.
- `src/firebase` - инициализация Firebase, провайдеры, Firestore-хуки, транспорт.
- `src/actions` - server actions (админ-операции, уведомления, статистика).
- `src/lib` - доменные типы, утилиты, policy/check helpers.
  - `src/lib/secret-chat/*` - web callable-клиент секретных чатов и создание `sdm_*` диалогов с серверно-совместимой конфигурацией.
- `functions/src` - Cloud Functions (auth/http/firestore/scheduler триггеры).
- `firestore.rules` - правила Firestore (deploy идёт отсюда, см. `firebase.json`).
- `storage.rules` - правила Firebase Storage.
- ~~`electron`~~ — **удалён**. Desktop теперь полностью на Flutter (`mobile/app` с таргетами macos/windows/linux). См. карту в разделе про `mobile/app/lib/features/desktop_shell/`. Stub `isElectron()` в `src/lib/utils.ts` возвращает `false` — dead-code call-sites постепенно удаляются.
- `mobile/app/lib/platform/platform_capabilities.dart` - единая точка ветвления платформо-зависимого поведения (вместо `Platform.isIOS`/`isAndroid` в коде). Riverpod-провайдер `platformCapabilitiesProvider`.
- `mobile/app/lib/features/desktop_shell/` - десктоп-оболочка Flutter: `DesktopShell` (window_manager init + persistence размера), `DesktopTray` (системный трей + dock badge), `DesktopDropTarget` (drag&drop файлов → /share), `DesktopDeepLinks` (схема `lighchat://`), `DesktopSingleInstance` (loopback-socket guard), `DesktopAutoUpdater` (Sparkle/Squirrel/AppImageUpdate).
- `mobile/app/lib/features/admin/` - админ-панель в Flutter (под role-gate `userRoleProvider`): `AdminShellScreen` + 9 экранов (overview, users, moderation, audit-log, announcements, storage stats, feature-flags, push, support — 9/9 реальные). Маршруты `/admin` и `/admin/:section`. Callable `adminRecomputeStorageStats` задеплоен и зовётся из storage stats screen.
- **Storage retention & quotas:** `platformSettings/main.storage.{mediaRetentionDays, totalQuotaGb, enforcementMode}` (см. `PlatformStoragePolicy` в `src/lib/types.ts`); per-chat/per-user квоты лежат в полях `conversations/{cid}.storageQuotaBytes` и `users/{uid}.storageQuotaBytes`. Применяются scheduled CF `mediaRetentionCleanupDaily` и `enforceStorageQuotasDaily` (см. `functions/src/triggers/scheduler/`). По умолчанию `enforcementMode=off` — функции ничего не удаляют; админ переключает в `dry_run` / `enforce` из `AdminStorageSettingsPanel`. Выселение оставляет `attachments[]` пустым с метками `mediaEvictedAt`/`mediaEvictedReason`.
- **Затраты GCP (BigQuery Billing Export):** админ-таб «Затраты» (`AdminCostsPanel` → callable `fetchBillingSummary`) показывает реальные суммы из Cloud Billing → BigQuery export. Конфиг — `platformSettings/main.billing.{projectId, dataset, tableId}` (см. `PlatformBillingConfig` в `src/lib/types.ts`). Включение требует ручных шагов в GCP Console: 1) Billing → Billing export → BigQuery (Standard usage cost), 2) выдать SA Cloud Functions роли `roles/bigquery.dataViewer` на dataset и `roles/bigquery.jobUser` на project. До настройки таб показывает форму конфигурации; ручная оценка `estimatedPricePerGbMonthUsd` в storage-stats остаётся как fallback на дни задержки экспорта (~24 ч).
- `mobile/app/lib/features/push/push_fallback_service.dart` - Firestore-listener fallback для Windows/Linux, где нет `firebase_messaging` SDK. Слушает `users/{uid}/incomingNotifications`. Серверная пара — `functions/src/lib/push-fallback.ts` + хуки в `onMessageCreated` и `onCallCreated` (deployed). Активируется для пользователей с `users/{uid}.devicePlatforms` содержащим `desktop` (см. `DesktopShell.markDesktopDevice()`).
- `mobile/app/lib/ui/responsive/` - адаптивный UI: `breakpoints.dart`, `adaptive_scaffold.dart` (NavigationBar↔NavigationRail), `two_pane_layout.dart` (master-detail), `desktop_shortcuts.dart` (Cmd/Ctrl+N → новый чат, Cmd/Ctrl+, → настройки, Cmd/Ctrl+K → search; no-op на mobile).
- `mobile/app/lib/features/chat/ui/workspace_shell_screen.dart` + `mobile/app/lib/features/chat/data/desktop_workspace_flag.dart` - **Stage 2 master-detail** для desktop. Параллельные маршруты `/workspace` и `/workspace/chats/:id` рендерят `ChatListPane` (master) + `ChatScreen` (detail) на ≥840dp. Mobile-маршруты `/chats` и `/chats/:id` не трогаются — feature flag `platformSettings/main.featureFlags.desktopWorkspaceLayout.enabled` контролирует появление пункта в меню (см. `chat_account_screen.dart`).
- `mobile/app/lib/features/welcome` - first-login welcome-анимация (per-uid флаг в SharedPreferences `first_login_animation_shown_<uid>`, redirect через `app_router.dart`).
- **AI / Apple Intelligence (iOS 26+):** [`mobile/app/lib/features/chat/data/apple_intelligence.dart`](mobile/app/lib/features/chat/data/apple_intelligence.dart) + native [`mobile/app/ios/Runner/Speech/AppleIntelligenceBridge.swift`](mobile/app/ios/Runner/Speech/AppleIntelligenceBridge.swift). Foundation Models bridge с streaming через `lighchat/apple_intelligence_stream`. UX: **Smart Compose** ([`smart_compose_strip.dart`](mobile/app/lib/features/chat/ui/smart_compose_strip.dart), 11 rewrite-стилей через long-press), **AI digest** ([`ai_catch_me_up_pill.dart`](mobile/app/lib/features/chat/ui/ai_catch_me_up_pill.dart) + [`ai_chat_digest.dart`](mobile/app/lib/features/chat/ui/ai_chat_digest.dart)), премиум rewrite-sheet ([`ai_text_action_sheet.dart`](mobile/app/lib/features/chat/ui/ai_text_action_sheet.dart)). Для не-нативных языков (ru/kk/uz/...) — bridge-translate через ML Kit (RU→EN→AI→EN→RU). Подробно: `docs/arcitecture/05-integrations.md` § Apple Intelligence.
- **Voice transcription:** [`local_voice_transcriber.dart`](mobile/app/lib/features/chat/data/local_voice_transcriber.dart) + native [`VoiceTranscriberBridge.swift`](mobile/app/ios/Runner/Speech/VoiceTranscriberBridge.swift) / [`.kt`](mobile/app/android/app/src/main/kotlin/com/lighchat/lighchat_mobile/VoiceTranscriberBridge.kt). On-device через SFSpeechRecognizer / Android SpeechRecognizer (без сети, в РФ работает). Sender-side preview ([`voice_message_preview_bar.dart`](mobile/app/lib/features/chat/ui/voice_message_preview_bar.dart)) распознаёт до отправки; для не-E2EE результат публикуется в Firestore `voiceTranscript` через `repo.sendTextMessage(voiceTranscript: ...)`. Cloud Function `transcribeVoiceMessage` (OpenAI Whisper) удалена 2026-05.
- **TTS (Read aloud):** [`local_text_to_speech.dart`](mobile/app/lib/features/chat/data/local_text_to_speech.dart) + [`TextToSpeechBridge.swift`](mobile/app/ios/Runner/Speech/TextToSpeechBridge.swift). `AVSpeechSynthesizer`, auto-best голос (premium > enhanced > default). User-picker ([`tts_voice_picker_sheet.dart`](mobile/app/lib/features/chat/ui/tts_voice_picker_sheet.dart)) с persistence per-language в SharedPreferences `chat.tts_voice.<lang>`.
- **iOS native chat bar:** при изменениях composer / select-mode / search-mode НЕ забывать про `NativeNavBarFacade.instance.setTopBar(...)` — `ChatHeader` сам перевыставляет конфиг native iOS bar (NavBarOverlayHost); если он unmount'ится (как в select-режиме) — конфиг остаётся stale → визуальное наложение. Явно гасить через `NavBarTopConfig.hidden()` (см. `_hideNativeBarForSelectionIfNeeded` в [`chat_screen.dart`](mobile/app/lib/features/chat/ui/chat_screen.dart)).
- **Composer footer/safe-area:** в [`chat_screen.dart`](mobile/app/lib/features/chat/ui/chat_screen.dart) и [`thread_screen.dart`](mobile/app/lib/features/chat/ui/thread_screen.dart) `footerHeight = max(panelH, kbInset, transitionFloor, viewPadding.bottom)` — добавление `viewPadding.bottom` в `reduce(max)` критично для отсутствия прыжка при закрытии клавиатуры. SafeArea bottom внутри `chat_composer.dart` НЕ переключать — footer уже покрывает safe-area. Default fallback высоты sticker-шторки `mq.size.height * 0.38` (≈ iOS keyboard с QuickType bar); персистентная замеренная клавиатура — [`keyboard_height_cache.dart`](mobile/app/lib/features/chat/data/keyboard_height_cache.dart) (`chat.last_keyboard_height_dp`).
- `docs/legal/{ru,en}/*.md` + `mobile/app/assets/legal/` - юридические документы (Privacy/ToS/Cookie/EULA/DPA/Children/Moderation/AUP). Web-роут `/legal/<slug>` (`src/app/legal/`), mobile-экран `/legal/:slug` (`mobile/app/lib/features/legal/`). См. `docs/legal/README.md`.
- `mobile/app/lib/features/settings/{ui/energy_saving_screen,data/energy_saving_preference}.dart` - экран «Энергосбережение» (Telegram-style); `EnergySavingNotifier` хранит флаги в SharedPreferences `energySaving.*`, слушает `battery_plus` (включая системный Low Power Mode), отдаёт `effective*`-геттеры. Маршрут `/settings/energy-saving`.
- `src/app/dashboard/features` + `src/components/features/*` - раздел «Возможности LighChat» (web): оглавление + 12 подстраниц `/dashboard/features/[topic]`, welcome-оверлей `FeaturesWelcomeOverlay` (флаг `lc_features_welcome_v1` в `localStorage`). Точка входа — пункт «Возможности» в `DashboardAccountMenuContent`.
- `mobile/app/lib/features/features_tour` - тот же раздел в mobile: маршруты `/features` и `/features/:topic`, per-uid флаг `features_tour_shown_<uid>` (`SharedPreferences`). После welcome-анимации `_exitToChats()` редиректит на `/features?source=welcome` при необходимости. Точка входа — пункт `account_menu_features` в `chat_account_screen.dart`.
- `scripts` - утилиты сборки/брендинга. `scripts/generate-chat-wallpapers.py` — генерация фирменных встроенных обоев чата (Pillow, использует геометрию `LighthousePainter`/`KeeperPainter`/`CrabPainter` из welcome-painters; выводит 16 WebP в `public/wallpapers/` и `mobile/app/assets/wallpapers/`).
- `public` - статика, PWA-иконки, манифест и `public/wallpapers/` — встроенные обои чата (8 концептов × light/dark). Каталог-источник — [`src/lib/builtinWallpapers.ts`](src/lib/builtinWallpapers.ts); параллельный manifest для Flutter — [`mobile/app/lib/features/chat/data/builtin_wallpapers.dart`](mobile/app/lib/features/chat/data/builtin_wallpapers.dart). Значение в Firestore: sentinel `builtin:<slug>` в `users.chatSettings.chatWallpaper` (рядом с URL и CSS-градиентами).

## Известные ограничения macOS Debug (free Apple ID)

- **firebase_auth_macos** требует data-protection keychain, который доступен только с paid Apple Developer Program ($99/год). На free Apple ID + Personal Team email/password вход выдаёт `keychain-error`.
- **flutter_secure_storage** на macOS обходит ограничение через `MacOsOptions(useDataProtectionKeyChain: false)` → legacy keychain без entitlement. Применено в `device_identity.dart`, `secret_chat_pin_device_storage.dart`, `chat_message_draft_storage.dart`.
- **App-sandbox** отключён в `macos/Runner/DebugProfile.entitlements` для Debug — это даёт unsandboxed-приложению доступ к legacy keychain без entitlement.
- **OAuth (Google/Apple/Yandex/Telegram через `signInWithProvider`)** — `firebase_auth_macos` не имеет реализации. `oauthBlockedOnMacOSCheck()` в `auth_screen.dart` показывает понятный SnackBar вместо unhandled exception.
- **Release-сборка с notarization для macOS** требует paid Apple Developer Program (см. `keychain-access-groups` блок-комментарий в `DebugProfile.entitlements` для пошаговой инструкции).
- **Linux** не имеет официального Firebase SDK — `firebase_options.dart linux` использует web-credentials, Auth и Firestore через `firebase_auth_linux` / `cloud_firestore` community ports; Messaging заменён на `PushFallbackService`.

## Набор архитектурных доков

- `docs/arcitecture/00-project-overview.md` - назначение продукта и платформы.
- `docs/arcitecture/01-codebase-map.md` - где что лежит и зона ответственности модулей.
- `docs/arcitecture/02-domain-entities.md` - ключевые доменные сущности и индексы.
- `docs/arcitecture/03-firestore-model.md` - модель коллекций и связи Firestore.
- `docs/arcitecture/04-runtime-flows.md` - основные runtime-потоки.
- `docs/arcitecture/05-integrations.md` - внешние интеграции и окружение.
- `docs/arcitecture/06-agent-change-policy.md` - правила безопасных изменений для агентов.

## Обязательное правило синхронизации документации

Если после задачи изменился код, который влияет на архитектуру, структуру директорий, доменные сущности, модель данных, интеграции или runtime-потоки, агент ОБЯЗАН обновить соответствующие документы в `AGENTS.md` и/или `docs/arcitecture/*` в рамках той же задачи.

Минимальная матрица обновления:

- Изменены пути/модули/ответственность директорий -> обнови `AGENTS.md`, `docs/arcitecture/01-codebase-map.md`.
- Изменены типы/сущности (`src/lib/types.ts`, функции, DTO) -> обнови `docs/arcitecture/02-domain-entities.md`.
- Изменены коллекции, связи, индексы, правила -> обнови `docs/arcitecture/03-firestore-model.md` и при необходимости `docs/arcitecture/05-integrations.md`.
- Изменены пользовательские/системные потоки (auth/chat/calls/meetings/notifications) -> обнови `docs/arcitecture/04-runtime-flows.md`.
- Изменены внешние сервисы, env, деплой/рантайм -> обнови `docs/arcitecture/05-integrations.md`.
- Изменены инженерные правила работы агентов -> обнови `AGENTS.md`, `docs/arcitecture/06-agent-change-policy.md`.

## Чеклист перед завершением задачи

- Проверил, затронуты ли архитектурно значимые части.
- При необходимости обновил docs синхронно с кодом.
- Проверил, что ссылки на пути в документах валидны.
