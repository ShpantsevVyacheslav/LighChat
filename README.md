<h1 align="center">LighChat</h1>

<p align="center">
  <strong>Безопасный мессенджер с E2E-шифрованием, QR мульти-девайс и HD-видеозвонками</strong>
</p>

<p align="center">
  Альтернатива WhatsApp и Telegram для iOS, Android, Web (PWA), Windows, macOS и Linux.
</p>

<p align="center">
  <a href="https://github.com/ShpantsevVyacheslav/LighChat/stargazers">
    <img src="https://img.shields.io/github/stars/ShpantsevVyacheslav/LighChat?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/ShpantsevVyacheslav/LighChat/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/ShpantsevVyacheslav/LighChat" alt="License">
  </a>
  <a href="https://lighchat.online">
    <img src="https://img.shields.io/badge/website-lighchat.online-blue" alt="Website">
  </a>
  <img src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-brightgreen" alt="Platforms">
</p>

<p align="center">
  <a href="#возможности">Возможности</a> •
  <a href="#локальный-запуск">Запуск</a> •
  <a href="#mobile-flutter">Mobile</a> •
  <a href="docs/marketing/README.md">Маркетинг</a> •
  <a href="README.en.md">English</a>
</p>

---

**LighChat** — это open-source мессенджер с end-to-end шифрованием, мульти-девайс синхронизацией через QR-код, HD-видеозвонками и кастомными темами чатов. Безопасная альтернатива WhatsApp и Telegram для iOS, Android, Windows, macOS, Linux и веба.

⭐ Если проект полезен — поставьте звезду на GitHub, это помогает другим узнать о нём.

## Возможности

- **Чаты**: личные и групповые чаты, треды, реакции, пересылка, вложения (фото, видео, файлы, аудио, видео-кружки), rich-текст, папки, поиск
- **Видеоконференции**: многопользовательские конференции через WebRTC, демонстрация экрана, виртуальные фоны, опросы, чат внутри конференции
- **1:1 звонки**: аудио- и видеозвонки между пользователями
- **PWA**: установка как приложение на мобильные устройства; иконки и фавикон — `public/pwa/icon-192.png` / `icon-512.png` (растр из `public/brand/lighchat-mark.png`), favicon App Router — `src/app/icon.png`, манифест `public/manifest.json`
- **Desktop**: нативное приложение через Electron (Windows, macOS)

## Локальный запуск

Требуется [Node.js](https://nodejs.org/) v20+.

1. Установите зависимости:
   ```bash
   npm install
   ```

2. Настройте переменные окружения:
   Создайте файл `.env.local` с ключами Firebase.

3. Запустите веб-версию:
   ```bash
   npm run dev
   ```

4. Запустите десктоп-версию (Electron):
   ```bash
   npm run desktop
   ```

## Mobile (Flutter)

Flutter-клиент находится в `mobile/app` (iOS/Android).

- Статус паритета чата (рендер reply/deleted/reactions, порядок/скролл, профиль собеседника): `docs/mobile/chat-rendering-parity.md`

1. Установите Flutter (macOS):
   ```bash
   brew install --cask flutter
   ```

2. Установите зависимости Flutter-приложения:
   ```bash
   cd mobile/app
   flutter pub get
   ```

3. Запуск (потребуется установленный Xcode для iOS/macOS и Android Studio/SDK для Android):
   ```bash
   flutter doctor -v
   flutter run
   ```

## Сборка десктоп-приложения

LighChat desktop собирается из единой Flutter-кодовой базы вместе с мобильным клиентом (`mobile/app`). Поддерживаются **macOS / Windows / Linux**.

```bash
cd mobile/app

# macOS (DMG)
flutter build macos --release
brew install create-dmg
create-dmg --app-drop-link 425 185 LighChat.dmg build/macos/Build/Products/Release/lighchat_mobile.app

# Windows (MSIX)
flutter build windows --release
flutter pub run msix:create

# Linux (AppImage)
flutter build linux --release
# далее appimagetool из .github/workflows/desktop.yml
```

В CI (`.github/workflows/desktop.yml`) собирается matrix-build на macOS-14 / windows-latest / ubuntu-22.04 и публикуются артефакты в GitHub Release на теге `v*`. Подписи (Apple Developer ID, Windows EV cert) подключаются через GitHub Secrets — пока что артефакты идут без подписи.

> **Electron-сборка (`npm run dist`, папка `dist_desktop`) — deprecated.** Заменяется на Flutter desktop; будет удалена после стабилизации Flutter v1 в проде.

## Деплой Firebase (Hosting / правила)

CLI входит в проект как **devDependency** (`firebase-tools`), чтобы не требовалась глобальная установка и не было конфликтов с правами на `~/.npm` или `/usr/local`.

После `npm install` и `firebase login`:

- **Один раз на машине** (Next из корня в `firebase.json`): `npx firebase experiments:enable webframeworks`.
- **Только Hosting:** `npm run deploy:hosting` (перед этим обычно `npm run build`, если нужна свежая сборка).
- **Только правила Firestore:** `npm run deploy:firestore`.
- **Сборка падает с `Cannot find module '.../.next/server/next-font-manifest.json'`** — обычно битый или недособранный кэш `.next` (прерванный `next build`, одновременный `next dev`, копирование папки). Закройте dev-сервер и выполните **`npm run deploy:hosting:clean`** или **`npm run deploy:functions-hosting:clean`** (скрипты удаляют `.next` и затем деплоят). При необходимости дополнительно: `rm -rf node_modules/.cache`.
- **Уникальность телефона/email при регистрации:** в Firestore добавлена коллекция `registrationIndex` (правила: публичное чтение, запись только с сервера). После деплоя Cloud Function `onuserwritesyncregistrationindex` и правил один раз вызовите из-под админа callable `backfillRegistrationIndex`, чтобы проиндексировать уже существующих пользователей в `users/*`.

Команды используют бинарник из `node_modules/.bin`. Если когда‑нибудь снова понадобится глобальный CLI и падает `EACCES` на кэше npm, почините владельца каталога: `sudo chown -R "$(id -u):$(id -g)" ~/.npm` (один раз на машине).

## Устранение неполадок

- **Вход через Google: нужно заполнить телефон и логин** — пока не выполнены те же требования, что при регистрации по email (имя, логин, телефон в формате 11 цифр), приложение остаётся на странице входа с формой «Завершите регистрацию» (email из Google подставляется и заблокирован для редактирования, поля пароля нет). Логика: `src/lib/registration-profile-complete.ts`, `completeGoogleProfile` в `src/hooks/use-auth.tsx`.
- **После регистрации в профиле только email, нет имени/телефона/логина** — клиент сохраняет полный `users/{uid}`, а Cloud Function `onUserCreated` могла позже делать merge с пустыми полями. Исправлено в [functions/src/triggers/auth/onUserCreated.ts](functions/src/triggers/auth/onUserCreated.ts) (транзакция «создать дефолт только если документа ещё нет»). Нужен деплой функций: `npx firebase deploy --only functions:onUserCreated` (или полный деплой functions).
- **Регистрация: `FirebaseError: Missing or insufficient permissions` при чтении `registrationIndex`** — в [firestore.rules](firestore.rules) для этой коллекции разрешено публичное чтение (`allow read: if true`). Если ошибка всё равно есть, правила в консоли Firebase не совпадают с репозиторием: выполните `npm run deploy:firestore` (или `npx firebase deploy --only firestore:rules`) для того же проекта, что и в `.env.local` / `NEXT_PUBLIC_*`, и проверьте в консоли **Firestore → Rules**, что блок `match /registrationIndex/{docId}` на месте.
- **Safari, Firestore «due to access control checks»** — пошаговый чеклист: [docs/troubleshooting-safari-firestore.md](docs/troubleshooting-safari-firestore.md).
- **Регистрация / вход: `API_KEY_HTTP_REFERRER_BLOCKED`, referer `http://localhost:3000` (identitytoolkit)** — у Browser API key в Google Cloud в списке HTTP referrer нет вашего origin или не разрешён **Identity Toolkit API**: [docs/troubleshooting-firebase-web-api-key.md](docs/troubleshooting-firebase-web-api-key.md).
- **FCM / пуши: «missing required authentication credential», token-subscribe-failed** — настройка Browser API key в Google Cloud (referrer + API): [docs/troubleshooting-fcm-web.md](docs/troubleshooting-fcm-web.md).
- **Гость, видеоконференция: `auth/admin-restricted-operation` / не открывается встреча** — включите **Anonymous** в Firebase Authentication; проверьте App Check и домены: [docs/troubleshooting-meetings-guest-auth.md](docs/troubleshooting-meetings-guest-auth.md).
- **Картинки Storage (обои): Origin не разрешён / access control checks** — на бакете нужен CORS: [docs/firebase-storage-cors.md](docs/firebase-storage-cors.md) и шаблон [scripts/firebase-storage-cors.json](scripts/firebase-storage-cors.json).
- **Стикеры: диалог создания пака под меню вложений** — исправлено: модальные окна (`Dialog` / `AlertDialog`) рендерятся с `z-index` выше всплывающего меню вложений (`Popover`, `z-[100]`). Логика: [src/components/ui/dialog.tsx](src/components/ui/dialog.tsx), [src/components/ui/popover.tsx](src/components/ui/popover.tsx).
- **Стикеры: удалить целиком стикерпак** — во вкладке «Стикеры» в меню вложений кнопка «Удалить пак» (с подтверждением). Удаляются документы пака и вложений в Firestore; из Storage удаляются только файлы, на которые больше нет ссылок в других паках (чтобы копии после «Дублировать» не ломались). Код: [src/lib/user-sticker-packs-client.ts](src/lib/user-sticker-packs-client.ts) (`deleteUserStickerPack`), [src/components/chat/UserStickersTab.tsx](src/components/chat/UserStickersTab.tsx).
- **Стикеры: общие паки для всех пользователей** — коллекция `publicStickerPacks`, файлы в Storage по префиксу `public/sticker-packs/`. Настройка и наполнение: [docs/public-sticker-packs.md](docs/public-sticker-packs.md). После правок [storage.rules](storage.rules) выполните `firebase deploy --only storage`.
- **Новый личный чат: `setDoc() ... Unsupported field value: undefined` в `participantInfo.*.avatarThumb`** — Firestore не сохраняет `undefined`. Снимок участников при создании чата собирается в [src/lib/conversation-participant-info-firestore.ts](src/lib/conversation-participant-info-firestore.ts): превью аватара не записывается, если его нет.

## Технологии

- **Frontend**: Next.js 14, React, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Real-time**: Firestore listeners, Firebase Cloud Messaging
- **Video/Audio**: WebRTC (simple-peer), MediaPipe (виртуальные фоны)
- **Desktop**: Electron + electron-builder
