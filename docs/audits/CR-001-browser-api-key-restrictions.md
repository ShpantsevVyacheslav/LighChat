# CR-001: Restrictions для всех API keys проекта `project-72b24`

После ротации web API key (основной CR-001) необходимо restrict'нуть **все** API
keys проекта, включая ключи для Flutter desktop (Windows/Linux). Этот документ —
пошаговая инструкция.

## TL;DR

В проекте `project-72b24` есть **5 разных API keys**:

| Ключ | Где используется | Префикс | Источник в коде |
|------|------------------|---------|-----------------|
| **Web** | `lighchat.online` (Next.js) | `AIzaSyD9GM…` | `src/firebase/config.ts` |
| **iOS** | iOS app + macOS Flutter | `AIzaSyBfedXY…` | `firebase_options.dart:ios` + `GoogleService-Info.plist` |
| **Android** | Android app | `AIzaSyBpL4…` | `firebase_options.dart:android` + `google-services.json` |
| **Windows** | Flutter Windows desktop | `AIzaSyAmAmwy…` | `firebase_options.dart:windows` |
| **Linux** | Flutter Linux desktop | `AIzaSyA_IC…` | `firebase_options.dart:linux` |

Все 5 нужно настроить — иначе любой, кто извлёк ключ из бинарника или DevTools,
сможет звать Firebase API за твой счёт. Ниже — точные значения для каждого.

---

## Где открыть

[Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials?project=project-72b24)

Для каждого ключа кликнуть на его название → откроется страница «Edit API key» с двумя
секциями: **Application restrictions** и **API restrictions**.

---

## 1. Web API key (`AIzaSyD9GM…`)

Используется веб-клиентом на `lighchat.online`.

### Application restrictions: **Websites**

В `Website restrictions` добавить (если ещё не добавлено):

```
https://lighchat.online/*
https://www.lighchat.online/*
https://project-72b24.firebaseapp.com/*   ← нужно для Firebase Auth OAuth handler
https://project-72b24.web.app/*           ← Firebase Hosting fallback
http://localhost:3000/*                   ← dev сервер (npm run dev)
http://127.0.0.1:3000/*                   ← dev сервер альтернативный host
```

> ⚠️ `https://lighchat.online` (apex) и `https://www.lighchat.online` — это **разные**
> origins. Нужны оба, иначе один из них даст `400 referer not allowed`.

### API restrictions: **Restrict key** → проставить:

| API | Зачем |
|-----|-------|
| ✅ Identity Toolkit API | Firebase Auth (signIn/signUp/reset) |
| ✅ Token Service API | refresh tokens |
| ✅ Cloud Firestore API | основной datastore |
| ✅ Cloud Functions API | callable functions (`requestQrLogin`, `signInWithTelegram`, …) |
| ✅ Cloud Storage for Firebase API | upload аватаров/медиа/стикеров |
| ✅ Firebase Cloud Messaging API | web push |
| ✅ FCM Registration API | регистрация FCM токена |
| ✅ Firebase Installations API | install IDs (нужно для FCM + App Check) |
| ✅ Firebase Management API | `webConfig` endpoint (← без него 403) |
| ✅ Firebase App Check API | exchange reCAPTCHA token → App Check token |
| ✅ reCAPTCHA Enterprise API | invisible CAPTCHA |
| ✅ Firebase App Hosting API | App Hosting runtime config |

Итого 12 API. **Save**.

---

## 2. iOS API key (`AIzaSyBfedXY…`)

Используется iOS Mobile app (Flutter) **и** macOS Flutter desktop.

### Application restrictions: **iOS apps**

В `iOS apps` добавить **оба** bundle ID:

```
com.lighchat.lighchatMobile    ← iOS app (firebase_options.dart:ios.iosBundleId)
com.lighchat.lighchat          ← macOS Flutter (см. комментарий в firebase_options.dart:macos)
```

> ⚠️ Если macOS bundle ID не добавлен — macOS-сборка Flutter получит
> `API_KEY_SERVICE_BLOCKED` при инициализации Firebase. iOS app тоже сломается
> если оставить только macOS bundle.
>
> Для каждого bundle ID нужно также добавить **App Store ID** (если приложение
> опубликовано) или **Team ID** (для unpublished — в Apple Developer Console
> найти Team ID).

### API restrictions: **Restrict key** → проставить:

| API | Зачем |
|-----|-------|
| ✅ Identity Toolkit API | Firebase Auth |
| ✅ Token Service API | refresh tokens |
| ✅ Cloud Firestore API | datastore |
| ✅ Cloud Functions API | callable |
| ✅ Cloud Storage for Firebase API | upload |
| ✅ Firebase Cloud Messaging API | push (APNs через FCM) |
| ✅ FCM Registration API | регистрация push token |
| ✅ Firebase Installations API | install IDs |
| ✅ Firebase App Check API | App Attest token exchange |

**НЕ нужны для iOS/macOS** (не добавлять — экономия attack surface):
- ❌ Firebase Management API (используется только web)
- ❌ reCAPTCHA Enterprise API (только web)
- ❌ Firebase App Hosting API (только web)

Итого 9 API. **Save**.

---

## 3. Android API key (`AIzaSyBpL4…`)

Используется Android Mobile app (Flutter).

### Application restrictions: **Android apps**

Добавить package + SHA-1 certificate fingerprint:

```
Package name: com.lighchat.lighchat_mobile  (или как у тебя в AndroidManifest.xml)
SHA-1: <отпечаток>
```

Получить SHA-1:

**Debug** (для разработки):
```bash
cd ~/Desktop/LighChat/mobile/app/android
./gradlew signingReport
# Скопировать SHA1: из строки `Variant: debug`
```

**Release** (для prod-сборки):
```bash
keytool -list -v -keystore <path-to-release-keystore.jks> -alias <alias>
# Скопировать SHA-1 fingerprint
```

> ⚠️ Если release-keystore ещё не создан — добавить пока только debug SHA-1.
> При первом release-сборке добавишь release SHA-1.

### API restrictions: **Restrict key** → тот же список что для iOS (9 API)

(Identity Toolkit, Token Service, Firestore, Functions, Storage, FCM, FCM Registration,
Installations, App Check API)

**Save**.

---

## 4. Windows Flutter API key (`AIzaSyAmAmwy…`)

Используется Flutter Windows desktop. Это **web-style** ключ, потому что у Flutter
Windows нет нативного Firebase SDK — он идёт через REST.

### Application restrictions: **None**

> ⚠️ **Не выставлять Websites** — Flutter Windows не шлёт HTTP Referer как браузер,
> запросы будут резаться с `400 referer not allowed`.
>
> **Не выставлять IP addresses** — конечные пользователи имеют свои IP.
>
> Защита остаётся только через API restrictions ниже + (планируется) App Check
> Custom Provider.

### API restrictions: **Restrict key** → проставить:

| API | Зачем |
|-----|-------|
| ✅ Identity Toolkit API | Firebase Auth |
| ✅ Token Service API | refresh tokens |
| ✅ Cloud Firestore API | datastore |
| ✅ Cloud Functions API | callable |
| ✅ Cloud Storage for Firebase API | upload |
| ✅ Firebase Cloud Messaging API | push fallback через Firestore (нет нативного FCM на Windows) |
| ✅ Firebase Installations API | install IDs |

**НЕ нужны для Windows Flutter**:
- ❌ FCM Registration API (нет нативного FCM провайдера)
- ❌ Firebase App Check API (нет provider — App Attest/Play Integrity недоступны)
- ❌ reCAPTCHA Enterprise / Firebase Management / App Hosting

Итого 7 API. **Save**.

---

## 5. Linux Flutter API key (`AIzaSyA_IC…`)

То же что Windows — Flutter Linux desktop, web-style ключ.

### Application restrictions: **None** (см. объяснение в Windows секции)

### API restrictions: **Restrict key** → тот же список из 7 API что для Windows

**Save**.

---

## После всех Save: проверка

### Web (lighchat.online)

1. Открыть `https://lighchat.online` в **инкогнито** с DevTools
2. Network → Fetch/XHR
3. Найти запрос `webConfig` — должен быть **200 OK** (а не 403)
4. Найти `recaptchaenterprise.googleapis.com` — должен пройти
5. Firestore `firestore.googleapis.com/.../channel?...` — **200**
6. QR-login на главной — генерится QR-код без ошибок

### iOS / macOS

1. `cd mobile/app/ios && pod install`
2. Запустить через Xcode
3. Login → должен пройти без 403 на Identity Toolkit
4. Открыть чат → Firestore запросы без ошибок

Если на macOS получаешь `[firebase_core/no-app]` или `API_KEY_SERVICE_BLOCKED` —
проверь что Bundle ID `com.lighchat.lighchat` добавлен в restrictions iOS key.

### Android

1. `cd mobile/app && flutter run -d android`
2. Login → Firestore работают

Если получаешь `API_KEY_SERVICE_BLOCKED` — SHA-1 в restrictions не совпадает.
Снять текущий debug SHA-1 командой выше, добавить.

### Windows / Linux Flutter

1. `cd mobile/app && flutter run -d windows` (или `-d linux`)
2. Login → Firestore работают

Если 403 на init — Application restrictions выставлены в Websites или IP. Должно
быть **None**.

---

## Что не делать

1. ❌ **НЕ ставить «Don't restrict key»** на любой ключ — это исходное состояние
   уязвимости CR-001 (любой может звать Maps/Translate/Gemini за твой счёт).

2. ❌ **НЕ копировать один ключ между платформами** — если ключ скомпрометируют,
   придётся ротировать только его, а не все. Сейчас web/iOS/Android/Windows/Linux
   корректно разделены.

3. ❌ **НЕ добавлять Firebase Management API в desktop/mobile keys** — этот endpoint
   нужен только web-клиенту для App Check / webConfig.

4. ❌ **НЕ снимать App Hosting API из web key** — иначе App Hosting deploy сломается
   при попытке Next.js встать на runtime.

5. ❌ **НЕ снимать referrer-restriction на web key** «для теста» — даже на 5 минут.
   В этом окне ключ открыт для всего интернета.

---

## Bonus: Gemini API key (баннер сверху)

Cloud Console пишет:

> Action Required: One or more projects enabled with Gemini API
> (generativelanguage.googleapis.com) have unrestricted API keys.

Это **отдельный** ключ для Gemini API, который **не** используется LighChat'ом
напрямую. Варианты:

- **Если Gemini не используется** — удалить этот ключ (Credentials → выбрать → Delete).
- **Если используется** (например, в `genkit` Cloud Functions) — restrict'нуть:
  - Application restrictions: **None** (сервер-side)
  - API restrictions: только **Generative Language API**

---

## Связано

- CR-001 (основной аудит) — ротация web key + restrictions
- CR-002 — App Check rollout (web/iOS/Android — Windows/Linux позже через Custom Provider)
- `AUDIT-2026-05-12-progress.md` — общий статус задач аудита
