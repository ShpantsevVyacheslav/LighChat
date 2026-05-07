---
name: lighchat-guidelines
description: Enforces LighChat coding conventions, Firebase patterns, chat architecture, and UI standards. Use when writing or modifying any code in this project, especially components under src/components/chat/, Firebase interactions, or UI/styling work with Tailwind/ShadCN.
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

## 6. Communication

- Be concise.
- If a request is ambiguous, ask for clarification before coding.
- Explain **what**, **where**, and **why** before providing code.

## 7. Documentation Sync (MANDATORY)

После каждой задачи, изменившей архитектурно значимый код, ОБЯЗАТЕЛЬНО обнови документацию в том же коммите/PR. Правило закреплено в `AGENTS.md` (строки 38-49).

### Матрица обновления

| Что изменилось | Обновить |
|---|---|
| Пути / модули / ответственность директорий | `AGENTS.md` + `docs/arcitecture/01-codebase-map.md` |
| Типы / сущности / DTO (`src/lib/types.ts`) | `docs/arcitecture/02-domain-entities.md` |
| Коллекции / индексы / правила Firestore | `docs/arcitecture/03-firestore-model.md` (+ `05-integrations.md`) |
| Runtime-потоки (auth/chat/calls/meetings/notifications/games) | `docs/arcitecture/04-runtime-flows.md` |
| Внешние сервисы / env / деплой / рантайм | `docs/arcitecture/05-integrations.md` |
| Правила работы агентов | `AGENTS.md` + `docs/arcitecture/06-agent-change-policy.md` |

### Стиль записей

- `04-runtime-flows.md`: `   **Bold title (platform):** dense paragraph with [` + "`" + `relative links` + "`" + `](../../path).`
- `01-codebase-map.md`: `  - ` + "`" + `path/to/file` + "`" + ` - краткое описание ответственности.`
- `05-integrations.md`: секционные буллеты с техническими деталями (TTL, ENV, ключи кеша, лимиты).
- Вся документация на русском языке.

### Чеклист перед завершением задачи

- [ ] Все пути в `[ссылках](...)` реально существуют
- [ ] Нет незадокументированных архитектурных изменений
- [ ] Запустить `/sync-docs` для финальной проверки

## Key Project Files

For detailed file paths and extended references, see [reference.md](reference.md).
