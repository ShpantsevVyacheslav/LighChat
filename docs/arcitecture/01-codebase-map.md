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
- `src/hooks` - клиентские хуки приложения (`use-auth`, `use-settings`, `use-meeting-webrtc`, и т.д.).
- `src/contexts` - локальные React contexts для feature-state.

## Firebase integration layer

- `src/firebase/index.ts` - инициализация SDK, fallback-логика, экспорт firebase-хуков.
- `src/firebase/provider.tsx`, `client-provider.tsx` - провайдеры для React.
- `src/firebase/firestore/*` - generic/use-doc/use-collection и id-based подписки.
- `src/firebase/firestore-transport.ts` - транспорт Firestore (включая long polling policy).

## Server-side logic

- `src/actions/*` - Next server actions (админка, уведомления, link preview, storage stats).
- `functions/src/index.ts` - экспорт триггеров Cloud Functions.
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
