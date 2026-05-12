# H-009: Миграция CSP Report-Only → Enforce

**Аудит:** `docs/audits/AUDIT-2026-05-08.md`, пункт H-009
**Текущее состояние:** Report-Only, observation period начат после deploy этого коммита
**Целевое состояние:** `Content-Security-Policy` (enforce) с `report-uri`
**Минимальный срок наблюдения:** 7 дней с реальным трафиком

---

## Что закрывает enforce

В Report-Only режиме браузер логирует violations, но **не блокирует ресурсы** — атакующий с XSS-инъекцией всё ещё может:
- Загрузить произвольный скрипт с внешнего CDN
- Сделать POST на сторонний домен с украденными токенами
- Внедрить inline `onclick` или `<script>`-тег

Переключение на Enforce закрывает все эти векторы (за вычетом `'unsafe-inline'` в style-src, который оставлен для Tailwind — стилевые XSS существенно менее опасны).

## Что было сделано

### 1. Endpoint для сбора violations
**Файл:** `src/app/api/csp-report/route.ts`

- POST принимает CSP report JSON (две версии формата — `application/csp-report` и `application/reports+json`)
- Дедупает по `directive + blockedBase + docPath` (SHA-256 → 16 hex)
- Хранит в Firestore `cspViolations/{hash}`:
  - `count` — общее число hits
  - `firstSeenAt`, `lastSeenAt`, `lastSeenDay`
  - `samples[]` — последние 10 примеров (UA, sourceFile, lineNumber, scriptSample)
- **Throttle:** 1 write per hash per day, чтобы Firestore не флудился

### 2. CSP middleware дополнение
**Файл:** `src/middleware.ts`

- Добавлена директива `report-uri /api/csp-report` (работает в обоих режимах)
- Endpoint исключён из CSP matcher (matcher: `(?!...|api/csp-report)`) чтобы избежать цикла

### 3. Firestore rules
**Файл:** `firestore.rules`

```
match /cspViolations/{hash} {
  allow read: if isAdmin();
  allow write: if false; // Admin SDK игнорирует rules, клиенты не могут
}
```

---

## Observation period: что делать сейчас

После deploy этого коммита подождать **минимум 7 дней** реального prod-трафика. За это время:

1. Каждый день проверять Firestore Console → `cspViolations`:
   - Sort by `lastSeenAt desc`
   - Note все новые directive + blockedBase, которых раньше не было

2. Для каждого нового violation решить:
   - **False positive** — известный третий-парти ресурс, который мы хотим разрешить. Добавить в `SCRIPT_SRC_EXTERNAL` / `CONNECT_SRC_EXTERNAL` / etc в `middleware.ts`.
   - **Подозрительно** — неизвестный домен. Поискать в коде. Если введён намеренно — добавить. Если нет — это **потенциальный XSS** или brittle integration, чинить отдельно.
   - **Шум** — `eval()` / inline-script от browser extension (например, Yandex Translate). Можно игнорить через директиву `'unsafe-eval'` НО только если уверены что наш код eval не использует.

3. Особое внимание на:
   - `script-src` violations — самое критичное (RCE potential)
   - `connect-src` — могут означать data exfiltration
   - `frame-ancestors` — кто-то пытается embed нас в iframe

---

## Чеклист перед переключением

Прежде чем менять `CSP_REPORT_ONLY = false`:

- [ ] За последние 3 дня нет новых уникальных violations (только знакомые из baseline)
- [ ] Все script-src violations либо в whitelist, либо classified как noise
- [ ] Все connect-src violations либо в whitelist, либо classified
- [ ] `npm run build` проходит, `tsc --noEmit` чист
- [ ] Smoke-тест prod-сборки локально через `npm run start`:
  - [ ] Логин (email + Google + Yandex + Telegram)
  - [ ] Открыть чат, отправить сообщение
  - [ ] Загрузить фото / видео / стикер
  - [ ] Открыть профиль участника
  - [ ] Открыть admin panel (если admin)
  - [ ] DevTools console — никаких новых CSP violations

## Сам переключатель

В `src/middleware.ts`:
```diff
-const CSP_REPORT_ONLY = true;
+const CSP_REPORT_ONLY = false;
```

После этого:
- `upgrade-insecure-requests` директива снова добавляется (защита от mixed-content)
- Браузер начинает **блокировать** запрещённые ресурсы (не только логировать)
- `report-uri` продолжает работать — нарушения будут видны в Firestore

## Rollback план

Если после переключения сайт ломается у части юзеров:

1. **Мгновенный rollback:** revert коммита enforce-перехода, redeploy
2. Параллельно — Firestore Console → `cspViolations` → найти новые блокировки за период
3. Добавить новые источники в whitelist `middleware.ts`
4. Повторить переключение

**Не нужно:** удалять данные из `cspViolations` после переключения — продолжают служить мониторингом.

---

## Известные источники в whitelist (baseline)

Из текущего `src/middleware.ts`:

| Директива | Whitelisted hosts | Зачем |
|---|---|---|
| script-src | `gstatic.com`, `apis.google.com`, `accounts.google.com`, `telegram.org`, `oauth.telegram.org` | Firebase compat SDK, Google sign-in, Telegram Login widget |
| connect-src | `*.googleapis.com`, `*.firebaseio.com`, `*.cloudfunctions.net`, `*.run.app`, `identitytoolkit.googleapis.com`, `securetoken.googleapis.com`, `api.giphy.com` + ws/wss | Firebase services, GIPHY API |
| img-src | `api.dicebear.com`, `*.googleusercontent.com`, `firebasestorage.googleapis.com`, `media.giphy.com`, `*.giphy.com`, `placehold.co`, `images.unsplash.com`, `picsum.photos`, `i.pravatar.cc` | Аватары, стикеры, чат-вложения |
| frame-src | `accounts.google.com`, `*.firebaseapp.com`, `oauth.telegram.org`, `www.youtube.com`, `www.google.com` | OAuth popup'ы, YouTube embeds |
| style-src | `'unsafe-inline'`, `fonts.googleapis.com` | Tailwind inline-css, Google Fonts |
| font-src | `data:`, `fonts.gstatic.com` | inline-fonts, Google Fonts CDN |
| media-src | `blob:`, `data:`, `firebasestorage.googleapis.com`, `*.googleusercontent.com` | Голосовые сообщения, видео-кружки, photos |
| worker-src | `'self'`, `blob:` | Service worker для FCM |
| object-src | `'none'` | Полный deny |
| base-uri | `'none'` | Защита от base-tag injection |
| frame-ancestors | `'none'` | Запрет клик-джэкинга |

Любое добавление **новых hosts** в этот список — security review.
