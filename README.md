
# LighChat

Мессенджер и платформа видеоконференций с поддержкой веб, десктоп (Electron) и PWA.

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

## Сборка десктоп-приложения

```bash
npm run build
npm run dist
```

Готовые файлы появятся в папке `dist_desktop`.

## Деплой Firebase (Hosting / правила)

CLI входит в проект как **devDependency** (`firebase-tools`), чтобы не требовалась глобальная установка и не было конфликтов с правами на `~/.npm` или `/usr/local`.

После `npm install` и `firebase login`:

- **Один раз на машине** (Next из корня в `firebase.json`): `npx firebase experiments:enable webframeworks`.
- **Только Hosting:** `npm run deploy:hosting` (перед этим обычно `npm run build`, если нужна свежая сборка).
- **Только правила Firestore:** `npm run deploy:firestore`.
- **Уникальность телефона/email при регистрации:** в Firestore добавлена коллекция `registrationIndex` (правила: публичное чтение, запись только с сервера). После деплоя Cloud Function `onuserwritesyncregistrationindex` и правил один раз вызовите из-под админа callable `backfillRegistrationIndex`, чтобы проиндексировать уже существующих пользователей в `users/*`.

Команды используют бинарник из `node_modules/.bin`. Если когда‑нибудь снова понадобится глобальный CLI и падает `EACCES` на кэше npm, почините владельца каталога: `sudo chown -R "$(id -u):$(id -g)" ~/.npm` (один раз на машине).

## Технологии

- **Frontend**: Next.js 14, React, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Real-time**: Firestore listeners, Firebase Cloud Messaging
- **Video/Audio**: WebRTC (simple-peer), MediaPipe (виртуальные фоны)
- **Desktop**: Electron + electron-builder
