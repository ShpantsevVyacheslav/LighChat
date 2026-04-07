# 00: Project Overview

## Что это

LighChat - мессенджер и платформа видеоконференций на базе Next.js + Firebase с тремя клиентскими формами:

- Web (Next.js App Router)
- PWA (мобильная установка, offline/иконки/manifest)
- Desktop (Electron shell)

## Бизнес-возможности

- Личные и групповые чаты (сообщения, треды, реакции, вложения, опросы, поиск)
- 1:1 аудио/видеозвонки (WebRTC)
- Видеовстречи с участниками, чатом, сигналингом, запросами на вход и опросами
- Админ-функции (управление пользователями, статистика хранилища, служебные backfill-операции)

## Технологический стек

- Frontend: Next.js 14, React 18, TypeScript, Tailwind, shadcn/ui
- Backend-as-a-Service: Firebase Auth, Firestore, Storage, Cloud Functions, FCM, Hosting
- Realtime/media: Firestore listeners, WebRTC (`simple-peer`), MediaPipe
- Desktop: Electron + electron-builder

## Главные точки входа

- `src/app/layout.tsx` - корневой layout и глобальные провайдеры
- `src/app/page.tsx` - auth-экран
- `src/app/dashboard/layout.tsx` - защищённая оболочка приложения
- `functions/src/index.ts` - entrypoint всех Cloud Functions
- `firestore.rules`, `storage.rules` - политики доступа

## Базовая модель данных

Ключевые коллекции Firestore:

- `users`
- `conversations` (+ `messages`, `typing`, `polls`, `members`)
- `calls` (+ `candidates`)
- `meetings` (+ `participants`, `signals`, `requests`, `messages`, `polls`)
- `userChats`, `userCalls`, `userMeetings`, `userContacts`
- `registrationIndex`, `platformSettings`

Детально: `docs/arcitecture/03-firestore-model.md`.
