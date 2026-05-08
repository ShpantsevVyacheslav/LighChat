# Security audit 2026-05-06 — follow-ups (manual / out-of-repo)

Этот документ — список действий, которые **нельзя сделать одним коммитом в репо**.
Они требуют доступа к Google Cloud Console, Apple/Google Play, GitHub Settings,
keystore-материалу или ручной валидации в эмуляторах.

## Сделано в коде (требует только деплоя)

См. историю коммитов с пометкой `security:` / `security/*:`. Бoльшая часть
Critical/High/Medium из аудита закрыта: privilege escalation в users-create,
SSRF guard, rate-limit pre-auth callable, security headers + CSP с nonce,
mobile WebView host allowlist, Telegram TTL+replay, customToken ECDH-encrypt,
e2eeDevices PII split, Custom Claims для admin, Zod-валидация, R8/allowBackup,
@electron/fuses, drafts AES в SharedPreferences и др.

**Manual checklist для деплоя одной командой:**

```bash
# 1. Деплой backend (rules + functions). Без этого ничего не активно.
firebase deploy --only firestore:rules,storage:rules,functions

# 2. Включить TTL policy в Firebase Console для коллекций:
#    - rateLimits.expireAt
#    - telegramAuthReplay.expireAt
#    - guestAccounts.expireAt          (audit H-008)
#    - pushDelivered.expireAt          (audit H-011)
#    (Firestore → TTL → Add policy)

# 3. После первого деплоя — однократно вызвать из админки:
#    - migrateDeviceLocationToPrivate (cursor=null до done=true)
#    - syncAdminClaims              (cursor=null до done=true)

# 4. ENV для App Hosting:
#    LIGHCHAT_PUBLIC_ORIGIN=https://lighchat.online

# 5. После недели мониторинга CSP в Report-Only — переключить на enforce:
#    в src/middleware.ts: const CSP_REPORT_ONLY = false;
```

## Audit 2026-05-08 (`docs/audits/AUDIT-2026-05-08.md`) — статус

**Закрыто в коде** (см. коммиты с пометками `[H-…]` / `[M-…]` / `[L-…]`):

| Sprint 1 (security) | Sprint 2 (compliance) | Sprint 3 (quality) |
|---|---|---|
| H-001 meeting-attachments read | CR-004 deleteAccount Storage+FCM | M-005 удалён src/firestore.rules |
| H-002 anonymous gust enumeration | CR-005 onConversationDeleted recursive | M-002 INITIAL_MESSAGE_LIMIT 100→30 |
| H-003 qrLoginSessions PII | | L-001 web/functions/flutter CI |
| H-004 registrationIndex callable | | L-002 husky + lint-staged |
| H-005 PII в логах | | L-005 Crashlytics init |
| H-006 N+1 onMessageCreated | | L-007 убран дубль cors.json |
| H-007 .limit(500) checkUserPresence | | L-009 apphosting maxInstances cap |
| H-008 guestAccounts TTL index | | M-003 presence interval 45→120s |
| H-009 svg blocked + comment | | M-004 chatMessageSizeOk e2ee/replyTo cap |
| H-010 sanitizeMessageHtml SSR='' | | M-006 push idempotency markers |
| H-011 pushDelivered idempotency | | M-012 push body html-decode |
| H-012 group participantIds защита | | M-014 cleanup tmp/session-* artefacts |

Также прод-фиксы по ходу: `380f3e9` (presence write не роняет UI),
`ef75247` (device session gate + force-refresh), `217aa06` (mobile dart errors).

**Defer (требуют отдельной работы):**

- **CR-001** — ротация Browser API key в Cloud Console + HTTP-referrer restrictions (operational).
- **CR-002** — App Check rollout (reCAPTCHA Enterprise / DeviceCheck / Play Integrity), monitor → enforce.
- **C7** — production keystore для Android (см. ниже).
- **M-001** — `useConversationsByDocumentIds` через `where(documentId(), 'in')` batch. Effort L: риск permission-denied на всю batch при stale conversationId, нужен careful refactor + fallback.
- **M-007 / M-008** — firebase 10→11 / next 14→15 upgrade. Effort M+ с регрессионным прогоном WebRTC митингов.
- **M-009** — split god-modules (`ChatWindow.tsx` 2614 строк). Effort L.
- **M-010** — codegen TS↔Dart типов для shared schema. Effort L.
- **M-013** — UI test coverage (vitest на компонентах + emulator-based firestore.rules tests). Effort L.
- **L-003** — 334 `console.*` в src/ → wrapper `logger.ts`. Effort M.
- **L-004** — 86 `debugPrint`/`console.log` в mobile → flutter_logs. Effort S, но cross-cutting.
- **L-006** — 55 `: any` в TypeScript → strict gradual. Effort M.

Понижение audit-debt дальше — в стандартном backlog.

## Critical (требуют ручных шагов)

### C7. Android release-сборка подписана debug-keystore
- **Файл:** `mobile/app/android/app/build.gradle.kts:39-44`
- **Что:** `signingConfig = signingConfigs.getByName("debug")` — публично известный
  ключ. Невозможно загрузить в Play, App Links auto-verify не работает,
  KeyStore-bound материал теряется при ротации.
- **Действия:**
  1. Сгенерировать production keystore локально (`keytool -genkey -v -keystore lighchat-release.keystore -alias lighchat -keyalg RSA -keysize 4096 -validity 10000`).
  2. Сохранить `keystore + password + alias` в защищённом vault (1Password/Bitwarden), **никогда** не коммитить.
  3. Создать `mobile/app/android/key.properties` (уже в `.gitignore`):
     ```
     storeFile=/abs/path/to/lighchat-release.keystore
     storePassword=...
     keyAlias=lighchat
     keyPassword=...
     ```
  4. Обновить `build.gradle.kts`: загрузить `key.properties` через `Properties()` и добавить `signingConfigs { create("release") { ... } }`. В `buildTypes.release` — `signingConfig = signingConfigs.getByName("release")`.
  5. После первой сборки — обновить `assetlinks.json` на сервере с SHA-256 нового сертификата.
  6. Проверить: `apksigner verify --print-certs lighchat-release.apk`.

## High (требуют доступа к Google Cloud / провайдерам)

### Включить App Check на Firebase
- **Что:** callable Cloud Functions (`requestQrLogin`, `signInWithTelegram`, `confirmQrLogin`) сейчас принимают анонимные вызовы — DoS-вектор и злоупотребление quota.
- **Действия:**
  1. Firebase Console → App Check → включить для Firestore, Storage, Cloud Functions.
  2. Web: reCAPTCHA Enterprise.
  3. iOS: DeviceCheck/AppAttest.
  4. Android: Play Integrity.
  5. В коде Functions добавить `enforceAppCheck: true` для callable. Постепенный rollout: сначала monitor mode → enforce.

### Ограничить Browser API key в Google Cloud Console
- **Что:** `AIzaSy...` web-ключ в `src/firebase/config.ts` без HTTP-referrer restrictions.
- **Действия:** Cloud Console → APIs & Services → Credentials → Browser API key → Application restrictions: HTTP referrers → `https://lighchat.online/*`, `https://*.firebaseapp.com/*`. API restrictions → только нужные API.

### Аналогично — ограничить iOS/Android API keys
- iOS: bundle ID `com.lighchat.lighchatMobile`.
- Android: package name + SHA-1 production keystore.

### Yandex/OAuth host header injection
- **Файл:** `src/app/api/auth/yandex/route.ts:28`
- **Что:** `redirect_uri` строится из `X-Forwarded-Host` без allowlist.
- **Действие:** добавить ENV `LIGHCHAT_PUBLIC_ORIGIN=https://lighchat.online`, использовать его как источник истины. Запасной вариант — `request.nextUrl.origin`.
- **Проверка:** в Yandex OAuth кабинете redirect_uri должен быть зафиксирован (не wildcard).

### SSRF в `getLinkMetadata` (link preview)
- **Файл:** `src/actions/link-preview-actions.ts:10`
- **Что:** недоflltering список private IP — нет `169.254.169.254`, IPv6, `172.16/12`, нет блока redirects/DNS-rebind. На App Hosting может вытащить metadata-token.
- **Фикс:** см. готовое решение в `electron/media-cache.js` (после security-fix коммита). Перенести логику `assertResolvesToPublicIp` + `isPrivateIp` в общий helper `src/lib/server/ssrf-guard.ts` и применить к `link-preview-actions.ts`. Дополнительно — `redirect: 'manual'` для всех fetch.

### `verifySecretVaultPin` — добавить counter
- **Файл:** `functions/src/triggers/http/verifySecretVaultPin.ts:12`
- **Что:** brute-force 4-значного PIN без блокировки.
- **Действие:** портировать логику `failedAttempts/lockedUntil` из `unlockSecretChat`.

### Mobile: WebView host validation
- **Файлы:** `mobile/app/lib/features/auth/ui/telegram_sign_in_webview_screen.dart`, `yandex_sign_in_webview_screen.dart`
- **Действие:** в `onNavigationRequest` отвергать всё кроме `lighchat.online|www.lighchat.online`. В `_customTokenFromUrl`/`_onCustomToken` проверять `uri.host` против allowlist перед `signInWithCustomToken`.

### Mobile: ffmpeg-kit deprecated
- **Файл:** `mobile/app/pubspec.yaml:75` (`ffmpeg_kit_min_gpl: 6.0.3+2-LTS`)
- **Действие:** мигрировать на community-fork (`ffmpeg_kit_flutter_new`) или нативные API (`AVAssetExportSession` на iOS, `MediaCodec` на Android).

## Medium

### Security headers (Web)
- **Файл:** `next.config.js`, `firebase.json`
- **Действие:** добавить `Strict-Transport-Security`, `X-Frame-Options: DENY` (или CSP `frame-ancestors 'self'`), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(self), microphone=(self), geolocation=(self)`. CSP — отдельной задачей с nonce'ами для inline-script в `layout.tsx`.

### Custom Claims вместо Firestore role
- **Что:** `assertAdminByIdToken` читает `users/{uid}.role` из Firestore. После закрытия C1 это безопасно, но JWT-claim надёжнее.
- **Действие:** на admin-endpoint `setAdminRole` через `auth.setCustomUserClaims({ admin: true })`. В `assertAdminByIdToken` использовать `decoded.admin === true`.

### `qrLoginSessions` — не хранить customToken в публично-читаемом документе
- **Файлы:** `firestore.rules:289`, `functions/src/triggers/http/confirmQrLogin.ts:140`
- **Действие:** клиент при scan делает второй callable, скармливает свой `nonce`, callable возвращает customToken по защищённому каналу.

### `e2eeDevices` — IP/гео всех пользователей читаемы
- **Файл:** `firestore.rules:386`, `confirmQrLogin.ts:162`
- **Действие:** разделить публичный (`e2eeDevices/{id}` — только pubKey) и приватный (`users/{uid}/devices/{id}` — IP/city/country/lastLogin) документы.

### Group conversation: любой участник может удалить
- **Файл:** `firestore.rules:654`
- **Действие:** ограничить delete для `isGroup === true` ролью `isGroupAdminOrCreatorFromConvData(resource.data)`.

### `chat-attachments` — нет лимитов
- **Файл:** `storage.rules:53`
- **Действие:** добавить `request.resource.size < 220 * 1024 * 1024` и `request.resource.contentType.matches('image/.*|video/.*|audio/.*|application/pdf|...')`.

### Android: allowBackup="false"
- **Файл:** `mobile/app/android/app/src/main/AndroidManifest.xml`
- **Действие:** добавить `android:allowBackup="false"` в `<application>`.

### Android: R8/minify в release
- **Файл:** `mobile/app/android/app/build.gradle.kts`
- **Действие:** в `buildTypes.release` — `isMinifyEnabled = true`, `isShrinkResources = true`, добавить `proguard-rules.pro`. Сборка через `flutter build apk --obfuscate --split-debug-info=...`.

### Reporter/userId с клиента
- **Файлы:** `src/actions/moderation-actions.ts:8`, `src/actions/support-ticket-actions.ts:8`
- **Действие:** принимать `idToken`, через `adminAuth.verifyIdToken` получать `uid` и подставлять его. Не доверять клиентскому `userEmail/userName` — читать из Firebase Auth.

### Электрон-обновления
- **Что:** `electron 31.x` уже EOL; нет auto-updater, нет signing/notarize.
- **Действие:** обновить до текущего LTS, подключить `electron-updater` с подписанным каналом, в electron-builder включить `mac.hardenedRuntime: true`, `afterSign` notarize hook, фьюзы (`@electron/fuses`: `OnlyLoadAppFromAsar`, `EnableEmbeddedAsarIntegrityValidation`, отключить `EnableNodeOptionsEnvironmentVariable`/`EnableNodeCliInspectArguments`).

## Manual git/infra проверки

### Скан истории git на утечку секретов
- Bash в окружении был ограничен; запустите вручную:
  ```bash
  git log --all -p -S 'BEGIN PRIVATE KEY' -- ':!*.lock'
  git log --all -p -S 'service_account'
  git log --all -p -S 'AKIA' -- ':!*.lock'
  git log --all -- '*.env' '*.env.local' '*.p8' '*.p12' '*.keystore' '*service-account*' '*adminsdk*'
  ```
- Если что-то найдётся: revoke ключ → `git filter-repo --invert-paths --path <file>` → force-push (с координацией команды).

### npm audit
```bash
npm audit --omit=dev
cd functions && npm audit --omit=dev
```

### Файлы в репо, на которые стоит посмотреть
- `tmp-mark-src.png` (в корне) — артефакт генерации брендового знака. Если не нужен — `git rm`.
- `session-ses_2872.md` (385KB) — дамп сессии Claude. Раскрывает внутреннюю архитектуру. Удалить или перенести в private storage.
- `GoogleService-Info.plist` в корне — `.gitignore` имеет `**/GoogleService-Info.plist`, но файл уже отслеживается. Решить: либо `git rm --cached`, либо убрать правило (это публичный client config, не секрет).

### CI hardening
- `.github/workflows/dart.yml`: запинить `actions/checkout@v4` по SHA. Добавить `permissions: contents: read` верхнего уровня.
