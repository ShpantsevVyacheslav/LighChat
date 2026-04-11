# Гость не входит в видеоконференцию: `auth/admin-restricted-operation`, Anonymous

Гостевая ссылка `/meetings/{id}` вызывает **`signInAnonymously`**, без этого Firestore не отдаёт документ встречи (`permission-denied`).

**Тот же экран с красным баннером** «Не удалось открыть встречу… `auth/admin-restricted-operation`» исправляется **настройками Firebase**, а не правкой кода чата: см. разделы ниже (Anonymous, App Check, домены).

## Сообщение `Firebase: Error (auth/admin-restricted-operation)`

Означает, что **клиентская операция входа запрещена** настройками проекта. Чаще всего:

### 1. Выключен анонимный провайдер

1. [Firebase Console](https://console.firebase.google.com/) → ваш проект → **Build → Authentication → Sign-in method**.
2. Включите **Anonymous** → **Save**.

После сохранения подождите 1–2 минуты и обновите страницу встречи.

### 2. App Check и Authentication

Если для **Authentication** (или глобально для продукта) включён **App Check** с **enforcement**, а **веб-приложение не зарегистрировано** в App Check или нет отладочного токена, анонимный вход может падать с `admin-restricted-operation`.

- **App Check** → зарегистрируйте хостинг / домен или временно **отключите enforcement** для проверки.
- Для локальной отладки используйте [debug provider](https://firebase.google.com/docs/app-check/web/debug-provider).

### 3. Authorized domains

**Authentication → Settings → Authorized domains**: должны быть `lighchat.online`, `www.lighchat.online`, при необходимости `project-72b24.web.app` и `project-72b24.firebaseapp.com`.

### 4. Google Cloud: API и ключ

- Включён **Identity Toolkit API** для проекта.
- Browser API key не блокирует запросы к **identitytoolkit** (HTTP referrers и список API): [troubleshooting-firebase-web-api-key.md](troubleshooting-firebase-web-api-key.md).

### 5. Организационные политики (редко)

В корпоративных организациях GCP политики могут запрещать анонимных пользователей — смотреть **Organization policies** в Google Cloud.

---

## Связанные файлы в коде

- `src/app/meetings/[meetingId]/page.tsx` — анонимный вход перед чтением встречи.
- `src/lib/meetings-guest-auth-message.ts` — подсказки по коду ошибки в UI.
