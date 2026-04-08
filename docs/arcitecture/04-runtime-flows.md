# 04: Runtime Flows

Краткая карта основных пользовательских и системных потоков.

## 1) Auth и профиль

1. Пользователь входит через Firebase Auth (`src/hooks/use-auth.tsx`).
2. Регистрация с фото: исходный кадр после выбора файла сохраняется в Storage как полноразмерный JPEG (до 2048 px по длинной стороне, см. [`uploadUserAvatarPair`](../src/lib/upload-user-avatar-pair.ts)) → `users.avatar`. [`RegisterAvatarCropOverlay`](../src/components/auth/register-avatar-crop-overlay.tsx) дополнительно экспортирует круг ([`getCircularCroppedImageBlob`](../src/lib/circular-crop-to-blob.ts), 512×512) → `users.avatarThumb`. В списках и миниатюрах UI берёт URL из [`userAvatarListUrl`](../src/lib/user-avatar-display.ts) (`avatarThumb` с fallback на `avatar`). Рендер **внутри** `DialogContent`, плюс `showCloseButton={!cropOpen}` и `onOpenChange`, чтобы не закрыть анкету при открытой обрезке.
3. Страница «Мой профиль» ([`dashboard/profile/page.tsx`](../src/app/dashboard/profile/page.tsx), форма [`UserForm`](../src/components/admin/user-form.tsx) с `isProfilePage`): телефон из Firestore нормализуется через [`phoneFormValueFromStored`](../src/lib/phone-utils.ts) и показывается в [`PhoneInput`](../src/components/ui/phone-input.tsx) с той же маской, что при регистрации; аватар — круг + [`RegisterAvatarCropOverlay`](../src/components/auth/register-avatar-crop-overlay.tsx) с `variant="compact"` и [`scopeWithinElement`](../src/contexts/dashboard-main-column-scope.tsx) (размытие и модалка только над правой колонкой [`DashboardMainAndChatRail`](../src/components/dashboard/DashboardMainAndChatRail.tsx), список чатов не затемняется). Контент без обёртки `Card`. Под полями и под аватаром — `FormDescription` / короткий текст как в регистрации.
4. Дубликаты email / телефона / логина: [`register` в use-auth](../src/hooks/use-auth.tsx) возвращает `RegisterResult` с `conflictField`; [`page.tsx`](../src/app/page.tsx) выставляет `react-hook-form` `setError` на поле и красную рамку [`AUTH_GLASS_INPUT_ERROR_CLASS`](../src/components/auth/auth-glass-classes.ts). Ошибка проверки `registrationIndex` без поля — по-прежнему общий баннер.
5. Google: после первого входа профиль считается неполным, пока не заполнены те же поля, что и при email-регистрации (имя ≥2 символов после trim, логин, телефон 11 цифр, email). Критерии — [`isRegistrationProfileComplete`](../src/lib/registration-profile-complete.ts). Форма без пароля — [`completeGoogleProfile`](../src/hooks/use-auth.tsx) и UI-блок [`RegisterDialogFormBlock`](../src/components/auth/register-dialog-form-block.tsx); редирект в [`dashboard/layout`](../src/app/dashboard/layout.tsx) только при полном профиле. Проверки `registrationIndex` с `{ exceptUid }`, чтобы не конфликтовать с собственной записью пользователя. После `setDoc`/`updateDoc` профиля `register` и `completeGoogleProfile` делают `getDoc` и [`setAppUser` в use-auth](../src/hooks/use-auth.tsx), плюс синхронный `appUserRef`. Слушатель `onSnapshot(users/{uid})` **игнорирует снимки из локального кэша** (`metadata.fromCache`), если они откатывают уже полный профиль к неполному — иначе после сохранения анкеты кэш присылал старый документ и снова открывал форму. Режим модалки (Google без пароля / email с паролем) задаётся флагом `googleProfileCompletionFlow` в контексте. Сразу после `signInWithPopup` / `getRedirectResult` [`finalizeGoogleCredential`](../src/hooks/use-auth.tsx) оборачивает первый `getDoc`/`setDoc` на `users/{uid}` в повторные попытки: `reload` + `getIdToken(true)`, чередование `getDocFromServer` / `getDoc` и пауза при `permission-denied` — стабилизует связку Auth ↔ persistent local cache Firestore.
6. Профиль читается из `users/{uid}`; при отсутствии формируется fallback.
7. Проверяются ограничения (`deletedAt`, `accountBlock`).
8. Обновляются `online/lastSeen` и фоновые presence-сценарии.
9. Смена email в профиле ([`updateUser`](../src/hooks/use-auth.tsx)): сначала вызывается `updateEmail` (Firebase Auth). Если в проекте включена политика «сначала подтвердить новый адрес», API возвращает `auth/operation-not-allowed` с текстом про verify — тогда клиент вызывает `verifyBeforeUpdateEmail` с `continueUrl` на `/dashboard/profile`; в Firestore новый email **не** пишется до подтверждения. После перехода по ссылке из письма email в Auth обновляется; [`use-auth`](../src/hooks/use-auth.tsx) при расхождении Auth vs `users/{uid}.email` делает неблокирующий `updateDoc`, чтобы профиль и [`registrationIndex`](../src/lib/registrationIndexKeys.ts) соответствовали Auth.

## 2) Компоновка дашборда и список чатов

1. Во всех разделах дашборда ([`dashboard/layout.tsx`](../src/app/dashboard/layout.tsx) + [`DashboardMainAndChatRail`](../src/components/dashboard/DashboardMainAndChatRail.tsx)): на **md и шире** **слева** колонка [`DashboardChatListColumn`](../src/components/dashboard/DashboardChatListColumn.tsx) (папки, поиск, список диалогов) и под ней [`DashboardBottomNav`](../src/components/dashboard/DashboardBottomNav.tsx) (`variant="chatSidebar"`); **справа** основная область страницы (`children`). На **узком экране** (`max-width: 767px`, см. [`useIsMobile`](../src/hooks/use-mobile.tsx) / брейкпоинт `md`) колонка списка скрыта (`hidden md:flex`), внизу рельса показывается [`DashboardBottomNav`](../src/components/dashboard/DashboardBottomNav.tsx) с `variant="fullWidth"` (иконки разделов + аватар). У рельса **две границы `<Suspense>`**: левая и правая ветки отдельно вызывают [`useDashboardConversationUrl`](../src/hooks/use-dashboard-conversation-url.ts) (`useSearchParams`), чтобы пауза/фолбэк одной колонки не размонтировал список чатов в другой. Левая ветка по-прежнему монтируется на мобильных (невидима), чтобы не менять подписки без отдельной задачи на ленивую загрузку списка.
2. Открытый чат: query [`conversationId`](../src/lib/dashboard-conversation-url.ts) в URL; **правая** колонка рендерит [`DashboardOpenChatView`](../src/components/dashboard/DashboardOpenChatView.tsx) вместо `children`. Маршруты утилит вроде `/dashboard/chat/forward` не используют этот query для колонки с контентом ([`isDashboardChatUtilityPath`](../src/lib/dashboard-conversation-url.ts)).
3. UI берёт `userChats/{uid}.conversationIds`.
4. Документы чатов подписываются по id (`useConversationsByDocumentIds`), без общего list-query.
5. В `ChatWindow` читаются `conversations/{id}/messages` и связанные поддокументы.
6. Изменения обновляют метаданные чата (last message, unread, thread counters).
7. Удалённые сообщения ([`ChatMessageItem`](../src/components/chat/ChatMessageItem.tsx)): при `isDeleted` сетка вложений в расчёте ширины не участвует (`hasGridVisualMedia` = false), плашка «Сообщение удалено» выравнивается `self-end` / `self-start` как исходящие/входящие. Геолокация: [`MessageLocationCard`](../src/components/chat/parts/MessageLocationCard.tsx) вне цветного пузыря; время — [`MessageStatus`](../src/components/chat/parts/MessageStatus.tsx) с `overlay` на превью карты; при истечении [`liveSession.expiresAt`](../src/lib/types.ts) действует [`isChatLiveLocationShareExpired`](../src/lib/live-location-utils.ts) — карта не рендерится (таймер `setTimeout` для перерисовки после дедлайна).

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
- В meetings listeners для опросов/зала ожидания активируются по соответствующей вкладке sidebar, чтобы не держать лишние realtime-подписки постоянно.
- В chat list typing-listener на `conversations/{id}/typing` включается всегда для выбранного чата и только для видимых карточек при активной вкладке для остальных, чтобы вернуть индикатор "Печатает..." без постоянной нагрузки.
- В fullscreen media viewer чата на iOS touch-жесты разделены по зонам: media-зона отдаёт pinch/pan в `react-zoom-pan-pinch`, а swipe-down закрытия обрабатывается только из overlay-зоны.
- В ChatWindow/ThreadWindow догрузка истории вверх фиксирует `scrollTop/scrollHeight` перед увеличением window-limit и компенсирует смещение после рендера, чтобы избежать прыжков верстки при prepend старых сообщений.
- В ChatWindow/ThreadWindow, помимо `startReached`, включён fallback-триггер по `scrollTop <= 40px` с cooldown, чтобы догрузка истории стабильно срабатывала на устройствах, где виртуализатор не всегда эмитит верхнее событие.
