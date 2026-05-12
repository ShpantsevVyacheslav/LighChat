# CR-001 follow-up: Browser API key — restrictions list

После ротации API key и установки **API restrictions** обнаружилось, что
restrictions заданы слишком узко — `firebase.googleapis.com`
(Firebase Management API / DynamicConfigService) **не в allowlist'е**, и
запросы из веб-клиента валятся с:

```
{
  "error": {
    "code": 403,
    "message": "Requests to this API firebase.googleapis.com method google.firebase.service.v1alpha.DynamicConfigService.GetWebConfig are blocked.",
    "status": "PERMISSION_DENIED",
    "details": [{ "reason": "API_KEY_SERVICE_BLOCKED" }]
  }
}
```

Этот endpoint вызывается **Firebase JS SDK** (особенно при инициализации App Check
через `ReCaptchaEnterpriseProvider`) — он фетчит метаданные о сервисах проекта.
Без `firebase.googleapis.com` в allowlist'е web-приложение не может корректно
получить App Check token, и в Enforce-режиме потеряет доступ к Firestore / Storage.

## Минимально необходимый allowlist для Browser API key

Открыть **Cloud Console** → APIs & Services → Credentials → выбрать Browser API key →
**API restrictions** → **Restrict key** → проставить галочки:

| API | Зачем |
|-----|-------|
| **Identity Toolkit API** | Firebase Auth (signIn, signUp, password reset) |
| **Cloud Firestore API** | основной datastore (`firestore.googleapis.com`) |
| **Firebase Cloud Storage API** | загрузка медиа/аватаров |
| **Firebase Cloud Messaging API** | web push (FCM) |
| **Firebase Installations API** | FCM registration ID, App Check device id |
| **Firebase Management API** | ← **этот пункт сейчас отсутствует, отсюда 403** |
| **Firebase App Check API** | reCAPTCHA Enterprise token exchange |
| **reCAPTCHA Enterprise API** | сам reCAPTCHA invisible challenge |
| **Cloud Functions API** | callable functions (`requestQrLogin`, …) |

После сохранения — **подождать 2-5 минут** (распространение по edge'ам), затем
перезагрузить `lighchat.online` и убедиться что в DevTools → Network запрос
к `firebase.googleapis.com/v1alpha/projects/<PROJECT>/webConfig` отдаёт **200**.

## Application restrictions

Параллельно проверить (не меняя ничего без причины):
- **HTTP referrers** должны включать:
  - `lighchat.online/*`
  - `*.lighchat.online/*`
  - `localhost:*/*` (для dev)
  - `localhost/*`

Без referrer'а `localhost:*/*` локальная dev-сборка не загрузит конфиг и
будет получать `400 referer not allowed`.

## Проверка после фикса

1. Открыть https://lighchat.online в анонимном окне
2. DevTools → Network → Fetch/XHR
3. Найти `webConfig` — должен быть **200 OK**, body содержит `serviceUrls`
4. Найти `recaptchaenterprise.googleapis.com` — должен пройти через App Check
5. Firestore запросы (`firestore.googleapis.com/.../channel?...`) — **200**

Если webConfig до сих пор 403 — restriction не сохранилась или не распространилась.
Подождать ещё 5 минут и попробовать `Disable cache` в DevTools (Cmd+Shift+R).

## Связано

- CR-001 — ротация API key + restrictions (основной аудит-пункт)
- CR-002 — App Check rollout (depends на корректно работающую Firebase Management API)
