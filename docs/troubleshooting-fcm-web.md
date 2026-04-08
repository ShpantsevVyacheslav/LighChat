# Веб-push (FCM): «Request is missing required authentication credential» / `messaging/token-subscribe-failed`

Сообщение вроде:

> *Messaging: A problem occurred while subscribing the user to FCM: Request is missing required authentication credential. Expected OAuth 2 access token…* (`messaging/token-subscribe-failed`)

означает, что **Google отклонил HTTP-запрос** при выдаче FCM-токена в браузере. Это **не** ошибка правил Firestore и **не** значит, что пользователь «не залогинен» в приложении: клиентский SDK передаёт **ваш Browser API key** (`apiKey` из конфига Firebase), и именно к нему предъявляются требования в **Google Cloud Console**.

Типичная причина после выноса приложения на **свой домен** (`https://lighchat.online`): ключ был создан с ограничением **HTTP referrers**, в списке есть только `*.firebaseapp.com` / `*.web.app`, а **кастомного хоста нет**.

---

## Что сделать (Google Cloud Console)

1. Откройте [Google Cloud Console](https://console.cloud.google.com/) → выберите проект **`project-72b24`** (или ваш `projectId` из [`src/firebase/config.ts`](../src/firebase/config.ts)).

2. **APIs & Services → Credentials**.

3. Найдите **API key** с типом использования для веба (тот же ключ, что в `apiKey` в настройках приложения в Firebase). Откройте его.

4. **Application restrictions**  
   - Если выбрано **HTTP referrers (web sites)**, добавьте origin’ы (по одному паттерну на строку), например:
     - `https://lighchat.online/*`
     - `https://www.lighchat.online/*`
     - `https://project-72b24.firebaseapp.com/*`
     - `https://project-72b24.web.app/*`
     - для локальной разработки: `http://localhost:*/*` и при необходимости `http://127.0.0.1:*/*`  
   - Сохраните и подождите **несколько минут** (распространение ограничений).

5. **API restrictions**  
   - Либо **Don't restrict key** (проще для проверки на тесте).  
   - Либо **Restrict key** и явно включите минимум:
     - **Firebase Installations API**
     - **Firebase Cloud Messaging API** (иногда в интерфейсе — «FCM» / «Cloud Messaging»)

6. Убедитесь, что API включены для проекта: **APIs & Services → Library** — поиск по именам выше → **Enable**.

7. Если после правильных ограничений ошибка остаётся, выполните безопасную миграцию ключа:
   - создайте новый Browser API key;
   - задайте Website restrictions для `lighchat.online`, `www.lighchat.online`, `project-72b24.firebaseapp.com`, `project-72b24.web.app`;
   - оставьте совместимый список API (Auth/Firestore/Storage/FCM), чтобы не сломать основной функционал;
   - обновите `apiKey` в [`src/firebase/config.ts`](../src/firebase/config.ts);
   - старый ключ отключайте только после smoke-проверки.

---

## Firebase Console (дополнительно)

- **Project settings → Cloud Messaging → Web Push certificates**: должен быть пара ключей; публичный ключ (VAPID) должен совпадать с тем, что использует приложение (см. [`src/hooks/use-notifications.ts`](../src/hooks/use-notifications.ts) — константа VAPID). Несовпадение VAPID обычно даёт **другую** ошибку, но сверить стоит.

- **Authentication → Settings → Authorized domains**: в списке должны быть `lighchat.online` и при необходимости `www.lighchat.online` (это про **Auth**, не про FCM напрямую, но для полноты окружения полезно).

---

## Проверка

После сохранения ограничений ключа: жёсткое обновление PWA/страницы, снова включить уведомления. В **Network** (если смотрите с десктопа) запросы к `fcmregistrations.googleapis.com` / установкам не должны отвечать 403 с текстом про credential.

Дополнительно разделяйте контексты на iOS:

- обычная вкладка Safari может не поддерживать нужный Notification/Push-контекст;
- подписку проверяйте из установленного Home Screen PWA.

---

## Связь с диалогом камеры/микрофона

Запрос **камеры и микрофона** к домену `lighchat.online` — от **видеозвонков/WebRTC**, не от FCM. На ошибку подписки на пуш он не влияет; их можно разруливать отдельно.
