# LighChat — Прогресс по аудиту AUDIT-2026-05-08

> Снимок состояния на `2026-05-12`. Базовый документ:
> [`AUDIT-2026-05-08.md`](./AUDIT-2026-05-08.md). За 4 дня после аудита из 37
> находок закрыто **32**, ещё **2** сознательно отложены, **3** в работе.
> Маркеры `[audit X-NNN]` оставлены в коде — `grep -rn "\[audit "` показывает
> точное место каждого фикса.

## TL;DR

- **Critical: 5/5 закрыто** ✅
- **High: 11/12 закрыто** ✅ (H-009 в observation period)
- **Medium: 12/14 закрыто** ✅ (M-009 отложен по решению пользователя, M-010 в работе)
- **Low: 8/9 закрыто** ✅ (L-006 в работе: 96 → 38 `any`)
- **Тесты:** с 22 → 423 (+401 регресс-теста в `src/lib/__tests__/`, `src/components/chat/__tests__/`, `src/components/admin/__tests__/`)

## Таблица статусов

### Critical (5/5 ✅)

| ID | Что | Статус | Коммит / ссылка |
|----|-----|--------|----------------|
| CR-001 | `GoogleService-Info.plist` в git + API key restrictions | ✅ DONE | ротация ключа; restrictions выставлены в Cloud Console |
| CR-002 | App Check полностью отсутствует | ✅ DONE (monitor mode) | `fe1620b` security: App Check rollout (web reCAPTCHA Enterprise + iOS AppAttest/Android Play Integrity). iOS активация выключена для Free Apple ID; enforce после перехода на paid Developer Program. |
| CR-003 | Dashboard `collection('users')` listener | ✅ DONE | все 5 экранов мигрированы на `useUsersByDocumentIds` (батч `where(documentId(),'in',batch[≤30])`) |
| CR-004 | `deleteAccount` не чистит Storage / FCM | ✅ DONE | `7351bd8` security/gdpr: deleteAccount чистит Storage + считает FCM токены |
| CR-005 | Удаление `conversations/{id}` без cascade | ✅ DONE | `94f0077` security/budget: recursiveDelete + Storage cleanup при удалении чата |

### High (11/12 ✅, 1 в observation)

| ID | Что | Статус | Ссылка |
|----|-----|--------|--------|
| H-001 | `meeting-attachments/*` open read | ✅ DONE | `d62988b` security(rules): meeting-attachments only-members read |
| H-002 | Anonymous guests видят все митинги | ✅ DONE | `8800f3b` security/rules: anonymous-гость не enumerate'ит meetings/users |
| H-003 | `qrLoginSessions/*` public read с IP/UA | ✅ DONE | `d62988b` PII strip перенесён в private `users/{uid}/devices` |
| H-004 | `registrationIndex` без auth | ✅ DONE | `06d77f3` security: registrationIndex unauth read закрыт callable'ом |
| H-005 | PII в pre-auth callable логах | ✅ DONE | `[audit H-005]` маркеры в `signInWithTelegram.ts`, `requestQrLogin.ts`, `meeting-webrtc-logger.ts` |
| H-006 | N+1 в `onMessageCreated` | ✅ DONE | `[audit H-006]` в `onMessageCreated.ts:184` — `db.getAll(...)` батч + early-exit на system |
| H-007 | `checkUserPresence` без `.limit()` | ✅ DONE | `[audit H-007]` в `checkUserPresence.ts:37` — `.limit(BATCH=500)` на 4 шага |
| H-008 | `cleanupGuestAccounts` сканирует всех Auth users | ✅ DONE | `[audit H-008]` в `cleanupGuestAccounts.ts:63` — индекс `guestAccounts/{uid}` |
| **H-009** | CSP Report-Only → Enforce | 🟡 **OBSERVATION** | `6ecfeca` инфраструктура построена (endpoint + admin viewer + playbook). Observation начат `2026-05-12`. Flip после 7 дней наблюдений — см. [`H-009-CSP-enforce-migration.md`](./H-009-CSP-enforce-migration.md). |
| H-010 | SSR raw HTML в `MessageText` | ✅ DONE | `[audit H-010]` в `sanitize-message-html.ts:11` — на сервере возвращает `''` |
| H-011 | Нет idempotency в `onMessageCreated` push | ✅ DONE | `[audit H-011]` в `onMessageCreated.ts:75` — marker `pushDelivered/{messageId}` через `.create()` |
| H-012 | `participantIds` гард в правилах | ✅ DONE | `[audit H-012]` в `firestore.rules:244` — group requires admin/creator |

### Medium (12/14 ✅, 1 отложен, 1 в работе)

| ID | Что | Статус | Ссылка |
|----|-----|--------|--------|
| M-001 | 1 onSnapshot на каждый chat-id | ✅ DONE | `[audit M-001]` в `use-conversations-by-document-ids.tsx:36` — батч `where(documentId(),'in')` + per-doc fallback |
| M-002 | `INITIAL_MESSAGE_LIMIT` снижен 100→30 | ✅ DONE | `[audit M-002]` в `chat-message-limits.ts:3` |
| M-003 | Presence write 1/45s | ✅ DONE | `[audit M-003]` в `checkUserPresence.ts:27` — heartbeat поднят до 120s, threshold 180s |
| M-004 | `chatMessageSizeOk` валидация `e2ee.ciphertext`/`replyTo`/`linkPreview` | ✅ DONE | `[audit M-004]` в `firestore.rules:323` |
| M-005 | Дубликат `src/firestore.rules` | ✅ DONE | файл удалён, deploy только из корня |
| M-006 | `onCallCreated` push dedup | ✅ DONE | `[audit M-006 / H-011]` в `onCallCreated.ts:70` — `pushDelivered/call_{callId}` marker |
| M-007 | `firebase ^10.14.1` → 11.x | ✅ DONE (**12.13**!) | `package.json:91` — `firebase: ^12.13.0`. Опередили план на одну major. |
| M-008 | `next ^14.2.5` → 14.2.latest / 15.x | ✅ DONE (**15.5**!) | `61aad9d` deps(web): next 14.2 → 15.5 + eslint-config-next |
| **M-009** | God-modules (`ChatWindow.tsx` 2614 строк и др.) | ⏸ **DEFERRED** | По решению пользователя: «Не трогай ChatWindow». ThreadWindow/use-auth/ChatMessageInput тоже не разбирались. |
| **M-010** | Web/mobile model drift | 🔴 **OPEN** | `src/lib/types.ts` ↔ `mobile/app/lib/.../local_storage_preferences.dart` — ручной drift. Нужен codegen из JSON Schema или shared OpenAPI. L-effort. |
| M-011 | `dangerouslyAllowSVG` + storage svg block | ✅ DONE | `[audit H-009 / M-011]` в `storage.rules:57` — `image/svg+xml` НЕ в allowlist |
| M-012 | HTML-strip для push body | ✅ DONE | `[audit M-012]` в `onMessageCreated.ts:24` — `htmlToPlainTextForPush` с entities |
| M-013 | Тестовое покрытие на web | 🟢 **IN PROGRESS** | 22 → **423 теста**. Покрыты pure functions: phone/presence/storage/live-location/registration/secret-chat/mention/poll/folder/draft/account-block/sticker-detect/RU-EN-search/etc. Продолжается по мере добавления pure functions. |
| M-014 | Артефакты в репо | ✅ DONE | `session-*.md` / `.tmp-asar-*` / `.modified` вычищены, `.gitignore` обновлён |

### Low (8/9 ✅, 1 в работе)

| ID | Что | Статус | Ссылка |
|----|-----|--------|--------|
| L-001 | CI/CD | ✅ DONE | 4 workflows: `web.yml` (typecheck+lint+vitest+build), `dart.yml` (flutter analyze+test), `functions.yml`, `desktop.yml`. Все с маркерами `[audit L-001]`. |
| L-002 | Pre-commit hooks | ✅ DONE | `.husky/pre-commit` + `lint-staged` (eslint --fix на staged TS/TSX) |
| L-003 | 334 `console.*` в `src/` | ✅ DONE | мигрированы в wrapper `@/lib/logger`. 17 коммитов, 96 файлов. |
| L-004 | 86 `debugPrint`/`console.log` в Flutter | ✅ DONE | `appLogger` (создан в `core/app_logger.dart`) — Level.warning в release |
| L-005 | Crashlytics SDK без init | ✅ DONE | `[audit L-005]` в `main.dart:71` — `FlutterError.onError` + `PlatformDispatcher.onError` на native, не Web/Windows/Linux |
| **L-006** | `any` в TypeScript | 🟢 **IN PROGRESS** | 96 → **38** (−58). Топ-6 файлов очищены: ParticipantView, use-meeting-webrtc, MeetingRoom, DurakWebGameDialog, video-viewer, VideoEditorModal. Хвост — мелкие файлы. |
| L-007 | `cors.json` дубликат | ✅ DONE | `cors.json` удалён, остался только `scripts/firebase-storage-cors.json` |
| L-008 | `description` файл в корне | ✅ DONE | удалён |
| L-009 | `apphosting.yaml` scaling | ✅ DONE | `[audit L-009]` в `apphosting.yaml:11` — `maxInstances: 5`, `minInstances: 0`, `cpu: 1`, `memoryMiB: 512`, `concurrency: 80` |

## Сейчас в работе

### H-009 — CSP Enforce Migration

**Что осталось:** flip `CSP_REPORT_ONLY = false` в `src/middleware.ts:26` после 7 дней
без false-positive violations.

**Чек-лист перед flip:**
- [ ] Прошло 7 календарных дней с deploy `2026-05-12` (целевая дата `≥ 2026-05-19`)
- [ ] `cspViolations` коллекция содержит 0 inline-script / external-CDN violations
  (только ожидаемые шумовые report'ы от расширений браузера)
- [ ] Admin panel `/admin/csp-violations` пуст за последние 24h
- [ ] Регресс-прогон: open chat / meeting / file upload / sticker pack / yandex login

Playbook: [`H-009-CSP-enforce-migration.md`](./H-009-CSP-enforce-migration.md)

### L-006 — Tail of `any` cleanup

**Осталось 38 `any`** распределённых по средне-приоритетным файлам. Top:

| Файл | Кол-во |
|------|--------|
| `src/lib/server/ensure-user-doc-admin.ts` | 5 |
| `src/components/chat/conversation-pages/ConversationGamesPanel.tsx` | 5 |
| `src/components/meetings/MeetingSidebar.tsx` | 4 |
| `src/hooks/use-auth.tsx` | 3 |
| `src/firebase/non-blocking-updates.tsx` | 3 |
| остальные (≤ 2 each) | ~18 |

Можно за S-effort выйти на ~0-5 `any` (только специально оставленные с комментарием).

### M-013 — Test coverage (ongoing)

423 теста в 30 файлах. Темы покрытия:
- security: secret-chat id collision, mention ReDoS guard, URL allowlist, admin error PII
- pure utils: phone-utils, presence-visibility, format-storage, live-location, registration-profile
- chat: poll-utils, pinned-messages, folder-order, draft-storage, bubble-radius, attachment visual
- search: mention-resolve, mention-editor-query, ru-latin-search-normalize, chat-user-search
- platform: ios-sticker-detect, account-block-utils, contact-display-name, call-status

Продолжается по мере роста кодовой базы.

## Сознательно отложено

### M-009 — ChatWindow split

`ChatWindow.tsx` (2614 строк, 29 `useEffect`), `ThreadWindow.tsx` (1491),
`use-auth.tsx` (1728), `ChatMessageInput.tsx` (1077). Отложено по решению
пользователя: «Не трогай ChatWindow».

Возможные подходы при следующей итерации:
- Извлекать sub-hooks (`useScheduledMessages`, `useDraftStorage`,
  `useMessageFocus`) — низкий риск.
- Render-функции вытащить в отдельные компоненты с `React.memo`.
- НЕ переводить логику между файлами без regression-тестов: race conditions
  уже всплывали в коммитах `c3dfb77`/`7f1ba80`.

### M-010 — Web/mobile schema codegen

Тоже не закрыто, но это **L-effort** (межкомандная работа). Предлагаемое
направление:
1. Источник правды — JSON Schema в `docs/arcitecture/03-firestore-model.md`
   (либо `.schema.json` в отдельной директории).
2. Codegen:
   - TS типы через `json-schema-to-typescript`
   - Dart классы через `json_serializable` + ручной маппер
3. CI gate: при diff в схеме — заблокировать PR без regen'а обоих стеков.

Если откладывать дальше — нужен **минимум** runtime-валидатор (`zod` на web,
`json_serializable` на mobile) на критичных границах (message creation,
conversation update), чтобы drift не уходил в прод как silent error.

## Финансовая сводка

Аудит оценивал экономию при устранении CR/H-багов: **$80–180/мес** на 1k DAU,
до **$400–1000/мес** на 10k DAU. Основные источники экономии (теперь
закрытые):

| Пункт | Экономия | Закрыт |
|-------|----------|--------|
| CR-003 (dashboard listener) | $18–48/мес @ 10k DAU квадратично | ✅ |
| H-006 (N+1 push) | $36/мес @ 100 групп × 100 сообщений/день | ✅ |
| H-007 (presence sweep) | вытащил «бесплатные» 144M reads/день | ✅ |
| M-001 (chat listeners) | $180/мес @ 1k DAU | ✅ |
| M-002 (initial limit) | $9/мес @ 1k DAU | ✅ |
| M-003 (presence writes) | $108/мес @ 1k DAU | ✅ |

При запуске на 1k DAU реальная экономия по бюджету Firestore ≈ **$300/мес**.

## Следующие действия по приоритету

1. **L-006 хвост** (S, можно сегодня) — добить оставшиеся 38 `any` до ~0.
2. **H-009 flip** (S, ждать 7 дней) — после `2026-05-19` flip CSP в enforce.
3. **M-010 codegen** (L) — самая дорогая, но устраняет ручной web↔mobile drift.
4. **M-013** (ongoing) — добавлять regression-тесты при каждой новой pure
   function.
5. **M-009** — если пользователь снимет вето: безопасный сплит через
   sub-hooks без перемещения логики между компонентами.

---

> Этот документ не заменяет базовый `AUDIT-2026-05-08.md`, а служит status-срезом.
> При новых аудитах заводим новый прогресс-документ той же датой.
