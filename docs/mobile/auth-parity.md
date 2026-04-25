## Web ↔ Mobile Auth Parity Checklist

Цель: мобильное приложение (`mobile/app`) должно повторять веб-версию по функциональности auth/registration.

### 1) Providers
- [ ] Email/Password: login + register
- [ ] Google: login + обязательное дозаполнение профиля

### 2) Email/Password registration (full parity)
Источник: `src/lib/register-profile-schema.ts`
- [ ] Поля: `name`, `username`, `phone`, `email`, `password`, `confirmPassword`, `dateOfBirth?`, `bio?`
- [ ] Валидации совпадают (min/max/regex/подтверждение пароля)
- [ ] Phone: ровно 11 цифр после очистки

### 3) Registration availability checks
Источник: `src/lib/registration-field-availability.ts` + `src/lib/registration-index-keys.ts`
- [ ] Перед созданием Auth user проверяем `registrationIndex`:
  - `email` (кроме placeholder guest_*@anonymous.com)
  - `phone`
  - `username`
- [ ] Ключи совпадают (p_/e_/u_ + base64url для email)

### 4) Firestore writes
- [ ] Создаём/обновляем `users/{uid}` с обязательными полями:
  - `id`, `name`, `username`, `email`, `phone`, `avatar`, `avatarThumb?`, `createdAt`, `deletedAt`
  - `dateOfBirth?`, `bio?`
- [ ] Пишем `registrationIndex/{key}` для email/phone/username с `uid`

### 5) Google flow
Источник: `src/lib/registration-profile-complete.ts`
- [ ] После входа через Google проверяем `isRegistrationProfileComplete` по данным `users/{uid}`; при «неполном» снимке с **кэша** — повтор с **сервера** (`GetOptions(source: server)`), как web `getDocFromServer` (см. `mobile/app/lib/features/auth/registration_profile_gate.dart`, `registrationProfileCompleteProvider`). Каждый `get` ограничен `kFirestoreRegistrationGetTimeout` (15 с). Дополнительно `isFirestoreRegistrationProfileCompleteWithDeadline` (`Future.any` + ~10 с) — на iOS нативный Firestore иногда не завершает `Future` от `get()`, из‑за чего экран «Проверка регистрации…» не уходил.
- [ ] После `completeGoogleProfile` — `ref.invalidate(registrationProfileCompleteProvider(uid))`, чтобы список чатов не держал старый `false`.
- [ ] Если профиль неполный: экран completion **не обязателен**; при соц-входе недостающее заполняется автоматически (минимум: `username`, `email`). Телефон запрашивается только при действиях контактов по телефону.
- [ ] Completion пишет `users/{uid}` и обновляет `registrationIndex` (с exceptUid)

### 6) Avatar UX (web parity)
- [ ] Выбор изображения → crop → preview
- [ ] Генерация:
  - full (square, ~1024, jpeg)
  - thumb (circle, 512×512, png с alpha)
- [ ] Upload в Storage и запись URL в `users/{uid}`

### 7) Error mapping (user-friendly)
- [ ] `network-request-failed`, `too-many-requests`, `invalid-email`, `invalid-credential`, `email-already-in-use` отображаются пользователю понятными сообщениями

### 8) Список чатов / `userChats`
- [ ] `ChatRepository.watchUserChatIndex` сначала делает `get()` с таймаутом и отдаёт значение в поток, затем подписывается на `snapshots()`, чтобы `StreamProvider` не зависал в loading, если первый snapshot не приходит.
- [ ] `AuthRepository.watchUser` сразу `yield currentUser`, затем `authStateChanges()` — иначе `StreamProvider` (список чатов) может долго оставаться в loading до первого события Firebase Auth.
- [ ] `watchConversationsByIds` сразу публикует текущий список (часто пустой), не откладывая в microtask — первое событие для `conversationsProvider` приходит синхронно.

### Files (mobile)
- UI: `mobile/app/lib/features/auth/ui/*`
- Services: `mobile/packages/lighchat_firebase/lib/src/registration/*`, `mobile/packages/lighchat_firebase/lib/src/auth_repository.dart`
- Firebase options: `mobile/app/lib/firebase_options.dart`

