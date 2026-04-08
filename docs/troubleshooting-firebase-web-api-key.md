# Firebase Web: «Requests from referer … are blocked» / `API_KEY_HTTP_REFERRER_BLOCKED`

В консоли браузера или в JSON ответа может быть:

- `403` / `PERMISSION_DENIED`
- `API_KEY_HTTP_REFERRER_BLOCKED`
- `service`: `identitytoolkit.googleapis.com` (Firebase Auth: email/пароль, Google и т.д.)

Это значит, что **Browser API key** из вашего `apiKey` (см. Firebase SDK config / `src/firebase/config`) в **Google Cloud Console** настроен с **Application restrictions → HTTP referrers**, и **текущий origin не в списке** (часто при локальной разработке: `http://localhost:3000`).

Это **не** баг приложения и **не** правила Firestore — ключ нужно поправить в Google Cloud для того же проекта, что и `projectId` в приложении.

---

## Что сделать

1. Откройте [Google Cloud Console](https://console.cloud.google.com/) → проект с тем же ID, что в Firebase (у вас в ошибке указан consumer вроде `projects/262148817877` — это numeric project id; в интерфейсе обычно ориентируйтесь на **projectId** из Firebase, например из настроек в консоли Firebase).

2. **APIs & Services → Credentials**.

3. Найдите ключ с именем вроде **Browser key (auto created by Firebase)** или тот, который совпадает с **Web API Key** в Firebase Console: **Project settings → General → Your apps → Web app**.

4. **Application restrictions**  
   Если выбрано **HTTP referrers (web sites)**, добавьте (каждый паттерн с новой строки), например:
   - `http://localhost:3000/*` — если приложение на порту 3000  
   - `http://127.0.0.1:3000/*` — то же для IP  
   - удобно для любого порта на localhost: `http://localhost:*/*`  
   - продакшен-домены: `https://ваш-домен.ru/*`

5. **API restrictions**  
   Если ключ **ограничен по API**, в список разрешённых нужно включить как минимум:
   - **Identity Toolkit API** (Firebase Authentication в браузере)
   - при использовании других клиентских функций с тем же ключом — также **Firebase Installations API**, при необходимости **FCM** и др. (см. [troubleshooting-fcm-web.md](troubleshooting-fcm-web.md)).

6. Сохраните изменения и подождите **1–5 минут** (кэш ограничений).

7. Обновите страницу приложения и повторите регистрацию / вход.

---

## Проверка

После правок запросы к `identitytoolkit.googleapis.com` с вашего origin не должны возвращать `API_KEY_HTTP_REFERRER_BLOCKED`.

Если ошибка сохраняется, убедитесь, что правите **именно тот** ключ, чей `apiKey` подставлен в сборку (`NEXT_PUBLIC_*` / `.env.local`), и что в браузере нет расширений, подменяющих referrer (редко).
