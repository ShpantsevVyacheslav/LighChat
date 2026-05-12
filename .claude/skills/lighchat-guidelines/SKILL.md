---
name: lighchat-guidelines
description: Enforces LighChat coding conventions, Firebase patterns, chat architecture, UI standards, change discipline (tests + commits, no auto-push), security checklist, cost discipline, and full multi-locale i18n coverage. Use when writing or modifying any code in this project — especially feature work, bug fixes, components under src/components/chat/, Firebase interactions, Firebase rules, Cloud Functions, UI/styling work with Tailwind/ShadCN, any change touching user-facing text, or preparing a git commit.
---

# LighChat Development Guidelines

## 1. Core Principles

- **Minimal Changes**: Only modify code directly related to the task. No unsolicited refactoring.
- **Feature Integrity**: NEVER delete existing business logic (Reactions, Threads, Calls, Pins, Bulk Actions, Gestures) unless explicitly asked.
- **TypeScript Strict**: Use strict typing everywhere. Avoid `any`; prefer explicit types or generics.

## 2. Firebase (CRITICAL)

### Client vs Admin
- Components use **`firebase`** (client SDK) only. Never import `firebase-admin` in UI code.
- Server-side logic (Cloud Functions) lives in `functions/`.

### Non-Blocking Writes
```typescript
// ❌ WRONG — blocks the UI
await setDoc(docRef, data);

// ✅ CORRECT — fire-and-forget via helper
import { nonBlockingSetDoc } from "@/firebase/non-blocking-updates";
nonBlockingSetDoc(docRef, data);
```
Helpers are in `src/firebase/non-blocking-updates.tsx`. Use them for `setDoc`, `updateDoc`, `addDoc`, `deleteDoc`.

### Memoize References & Queries
Stabilize all Firestore `DocumentReference` / `Query` objects with the project's `useMemoFirebase` hook to prevent infinite `useEffect` / `onSnapshot` loops.

```typescript
// ✅ Stable reference
const ref = useMemoFirebase(() => doc(db, "chats", chatId), [chatId]);
```

### Security
Always assume Firestore data is protected by user-level security rules. Never trust client-side checks alone.

## 3. Chat & Media Architecture

### Message Pagination
Hybrid **30 + 50** strategy (see `src/components/chat/chat-message-limits.ts`):
1. **Initial window**: `onSnapshot` with `limit(INITIAL_MESSAGE_LIMIT)` (30; снижено с 100 в audit M-002).
2. **Older history**: increase `limit` by `HISTORY_PAGE_SIZE` (50) on `startReached`; show header loader while `isLoadingOlder` until the next snapshot arrives.

### First paint (§5.1)
`ChatWindow` and `ThreadWindow` use `isFullyReady`: full-area overlay on the message list until the first thread/main `onSnapshot` settles (success or error).

### Scroll Stability
Use `react-virtuoso` with `firstItemIndex` to prevent layout jumps during history loading.

### CLS Protection (Layout Shift)
| Element | Rule |
|---|---|
| Images / Videos | Store `width`, `height`, `thumbHash` in Firestore. Use `aspect-ratio` CSS in `MessageMedia.tsx`. |
| Link Previews | Hard-coded height of **80px** in `LinkPreview.tsx`. |
| Videos | Append `#t=0.1` to source URL to show the first frame. |

### Caching
Use a global `Map` cache to store/restore messages for instant chat navigation.

## 4. UI & Styling

| Concern | Standard |
|---|---|
| Framework | Next.js App Router |
| Styling | Tailwind CSS |
| Components | ShadCN UI |
| Icons | `lucide-react` only — do not use icons that don't exist in the library |
| Approach | Mobile-first, handle `safe-area-insets` for PWA / iOS |

## 5. Coding Style

- Functional components + hooks only.
- `useCallback` for functions passed as props to children.
- `useMemo` for expensive computations or filtered lists.
- Keep `ChatWindow.tsx` logic modular — extract sub-hooks and sub-components.

## 6. Локализация (i18n) — полное покрытие всех локалей

Любые правки, добавляющие или меняющие пользовательские тексты (UI-строки, лейблы, тосты, плейсхолдеры, ошибки, email-/push-нотификации, метаданные), ОБЯЗАНЫ покрывать **все поддерживаемые локали** соответствующей платформы. Не «ru + en», не «дополним потом» — все локали в том же коммите.

### 6.1 Полный список локалей

| Платформа | Локали | Расположение словарей |
|---|---|---|
| Web / Next.js | `en`, `ru`, `kk`, `uz`, `tr`, `id`, `pt-BR`, `es-MX` (8 шт., константа `SUPPORTED_LOCALES` в `src/lib/i18n/preference.ts`) | `src/lib/i18n/messages/<locale>.ts` |
| Mobile / Flutter | `ru`, `en`, `kk`, `uz`, `tr`, `id`, `pt`, `pt_BR`, `es`, `es_MX` (10 ARB-файлов) | `mobile/app/lib/l10n/app_<locale>.arb` |

### 6.2 Правила

- **Хардкод строк в JSX / Dart запрещён.** Использовать `useI18n().t('path.to.key')` (web, см. `src/lib/i18n/translate.ts`) или `AppLocalizations.of(context)!.key` (mobile).
- **При добавлении нового ключа** — завести значения **во всех** локалях. Не оставлять `TODO`, не дублировать английский в русское поле.
- **При изменении текста существующего ключа** — обновить **все** локали синхронно. Старый перевод других языков почти наверняка тоже устарел.
- **При удалении ключа** — удалить во всех словарях, чтобы не копился мёртвый код.
- **Скрипт** `scripts/translate-remaining-locales.mjs` умеет дотягивать дополнительные локали из основных (`ru`/`en` для web, `ru` для mobile). После добавления ключа в `ru.ts` + `en.ts` (web) или `app_ru.arb` (mobile) — прогнать скрипт; затем глазами проверить машинные переводы на здравый смысл, не коммитить «слепо».
- **Архитектура должна оставаться расширяемой** — никакого хардкода `['ru','en']`. Список локалей — единый источник истины (`SUPPORTED_LOCALES` / `l10n.yaml`).

### 6.3 Чек перед коммитом

Если diff содержит изменения в `src/lib/i18n/messages/*.ts` ИЛИ `mobile/app/lib/l10n/*.arb` ИЛИ новые литералы, обёрнутые в `t(...)` / `AppLocalizations`:

1. Сверить набор ключей по всем файлам: для web — `Object.keys` всех словарей должны совпадать; для mobile — `flutter gen-l10n` не должен ругаться на отсутствующие ключи.
2. Если какой-то локали не хватает — запустить `scripts/translate-remaining-locales.mjs`, либо вручную дополнить.
3. Включить i18n-правки в **тот же коммит**, что и фича/фикс. «Хвост» переводов отдельным коммитом — запрещено.

## 7. Communication

- Be concise.
- If a request is ambiguous, ask for clarification before coding.
- Explain **what**, **where**, and **why** before providing code.

## 8. Change Discipline (Tests + Commit)

Каждая фича или фикс проходит один и тот же цикл: реализация → тест → i18n-чек (если затронут текст) → локальный commit → ждать «ok» на push.

### 8.1 Обязательные тесты по типу правки

| Тип правки | Обязательный минимум |
|---|---|
| Чистая логика / утилита / hook (Dart или TS) | unit-тест |
| Flutter UI (`mobile/app/lib/features/**/ui/**`, виджеты) | unit + widget-тест (`flutter_test`) |
| Next.js / React-компонент (`src/components/**`) | unit/component-тест (Vitest + Testing Library; если файл-тестов нет — добавить smoke) |
| Firebase rules (`firestore.rules`, `storage.rules`) | integration: эмулятор + `@firebase/rules-unit-testing` ИЛИ Vitest-сценарий, фиксирующий **allow** и **deny** кейсы |
| Cloud Functions (`functions/src/**`) | unit-тест в `functions/src/**.spec.ts` или `functions/test/`, с моками Firestore/Auth |
| Поток данных Firestore (read/write через UI или функции) | integration: `fake_cloud_firestore` (mobile) или эмулятор (web) |
| Тривиальная правка (опечатка в строке, переименование локальной переменной, форматирование, правка docs/skills/config) | тест не обязателен — указать причину в commit body |

Правило: **минимально достаточный набор**. Не плодим лишние уровни, но любая изменённая *поведенческая* строка требует хотя бы один новый или обновлённый тест. Unit-тест — базовый уровень для любой логики; widget/integration — добавочные при правке UI / Firebase.

### 8.2 Команды запуска

- Mobile: `cd mobile/app && flutter test`
- Web (корень репо): `npm test` (Vitest)
- Cloud Functions: `cd functions && npm test`

Перед коммитом запускать **только релевантные** наборы — экономия времени и денег (см. § 10).

### 8.3 Дисциплина коммитов и push

1. Если правка затрагивает пользовательский текст — **прогнать i18n-чек из § 6.3.** Не хватает перевода → доделать ДО коммита.
2. Запустить релевантные тесты (§ 8.2). Все зелёные → переходить к коммиту.
3. `git add` **именованных** файлов (не `git add .` и не `git add -A`) — чтобы случайно не утянуть `.env` или артефакты.
4. `git commit` с осмысленным сообщением (см. § 8.4).
5. **НЕ делать `git push` автоматически.** Дождаться явного «ok / запушь» от пользователя. После push — `git status` для верификации.
6. `git push --force`, `--no-verify`, `git reset --hard`, `git clean -f` — только по прямому подтверждению.

### 8.4 Формат commit message

- Subject: `<type>(<scope>): <imperative summary>` (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
- Body: 1–2 строки про *зачем* (не *что*). Если в правке нет нового теста — явное обоснование («typo only / no behavior change / docs-only»).
- Footer: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` (через HEREDOC).

## 9. Security Checklist

Прогонять мысленно перед каждым коммитом. Каждый пункт — повод подумать, не открыта ли дыра.

- **Firestore / Storage rules** (`firestore.rules`, `storage.rules`): любая правка rules требует integration-теста, который фиксирует **allow** И **deny** кейсы. Не доверять «должно работать».
- **Клиент vs Admin SDK** (повтор § 2.1): никогда не импортировать `firebase-admin` в UI. Серверная логика — только в `functions/`.
- **Двойная проверка прав**: любая проверка на клиенте дублируется на сервере (в Cloud Functions) и/или в rules.
- **Секреты**: не коммитить `.env`, ключи, `serviceAccount.json`, `google-services.json` с реальными значениями. Перед `git add` проверять глазами состав файлов.
- **OWASP базис**: input sanitization, отсутствие `dangerouslySetInnerHTML` без `DOMPurify`, безопасность составных Firestore-запросов (`where(...).where(...)` с пользовательским input).
- **E2EE**: изменения, затрагивающие шифрование, сверять с `docs/arcitecture/07-e2ee-v2-protocol.md`.
- **Auth-флоу и роли**: сверять с `docs/arcitecture/02-domain-entities.md` и `docs/arcitecture/04-runtime-flows.md`.
- **Agent change policy**: соблюдать ограничения из `docs/arcitecture/06-agent-change-policy.md`.

## 10. Cost Discipline (Firebase / GCP)

LighChat работает на Firebase pay-as-you-go. Каждая лишняя подписка, write или Function invocation — это деньги.

- **Firestore reads**: гибрид 30 + 50 (§ 3) — обязательный паттерн для чатов. `onSnapshot` без `limit(...)` на большой коллекции запрещён. Все `DocumentReference` / `Query` — через `useMemoFirebase`, иначе listener пересоздаётся на каждый рендер и тарифицируется заново.
- **Firestore writes**: батчить (`writeBatch`) там, где это естественно. Избегать «toggle»-паттернов, шлющих write на каждый клик/тик; использовать debouncing / optimistic UI с финальным write.
- **Cloud Functions**: не вешать `onWrite` на «горячие» документы (presence, typing, счётчики). Для триггеров — `onCreate` / `onUpdate` с diff-фильтрацией; никаких циклов запись→триггер→запись.
- **Storage**: большие медиа — всегда через thumbnail + lazy load; `width` / `height` / `thumbHash` обязательны (§ 3) — без них клиенты тянут полный файл для CLS.
- **Analytics / BigQuery**: события — только те, что описаны в `docs/arcitecture/06-analytics.md`. Не плодить новые без необходимости (каждое событие = строка в BQ = $).
- **CI / локальные тесты**: гонять **только релевантные** наборы перед коммитом (см. § 8.2). Полный `flutter test && npm test && functions test` — только перед релизом или если правка кросс-платформенная.
- **Integrations**: перед добавлением новой внешней зависимости / SaaS — свериться с `docs/arcitecture/05-integrations.md`. Каждая новая интеграция = потенциальный платный SLA + точка отказа.

## Key Project Files

For detailed file paths and extended references, see [reference.md](reference.md).
