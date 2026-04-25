# Вход через Telegram (LighChat)

## Что настроить вручную

1. **BotFather** — создать бота, получить токен, командой `/setdomain` указать домен сайта (тот же, с которого открывается Login Widget), например `lighchat.online`; для staging — отдельный бот или тот же домен.
2. **Firebase Functions** — секрет с токеном бота:
   ```bash
   firebase functions:secrets:set TELEGRAM_BOT_TOKEN
   ```
   Затем задеплоить функции (`signInWithTelegram`). Для **2nd gen** после деплоя настройте **IAM для `signBlob`** (раздел ниже), иначе `createCustomToken` вернёт `auth/insufficient-permission`.
3. **Next.js / хостинг** — переменная **`NEXT_PUBLIC_TELEGRAM_BOT_NAME`** (username бота **без** `@`). Без неё кнопка Telegram на главной входа отключена.
4. **Firebase Authentication → Settings → Authorized domains** — домен приложения (для вызова callable из браузера / WebView).
5. **Flutter (опционально)** — если мост должен открывать не прод-домен по умолчанию, сборка с  
   `--dart-define=TELEGRAM_AUTH_BRIDGE_URL=https://ваш-хост`  
   (без завершающего `/`). По умолчанию в коде: `https://lighchat.online/auth/telegram?mobile=1` (должен совпадать с `/setdomain`).

## IAM: `Permission iam.serviceAccounts.signBlob denied` / `auth/insufficient-permission`

Callable **2nd gen** выполняется в Cloud Run. Admin SDK подписывает custom token через API IAM [`signBlob`](https://cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts/signBlob). Нужно выдать **роль «Service Account Token Creator»** (`roles/iam.serviceAccountTokenCreator`) **на том сервисном аккаунте, от имени которого подписывается JWT** (часто это **App Engine default**: `ВАШ_PROJECT_ID@appspot.gserviceaccount.com`), **субъекту** — **сервисному аккаунту, под которым реально запускается функция** (у 2nd gen по умолчанию это **Default Compute Engine**: `ЧИСЛО_ПРОЕКТА-compute@developer.gserviceaccount.com`). Подробнее: [Firebase — create custom tokens, troubleshooting](https://firebase.google.com/docs/auth/admin/create-custom-tokens#troubleshooting).

**Уточнить аккаунт выполнения:** Google Cloud Console → **Cloud Run** → сервис `signinwithtelegram` (или имя вашей функции) → вкладка **Security** / **Безопасность** → поле **Service account**.

**Вариант A — gcloud** (подставьте `PROJECT_ID` и номер проекта; при необходимости замените `RUNTIME_SA` на email из Cloud Run):

```bash
# Номер проекта (например 123456789012)
gcloud projects describe PROJECT_ID --format='value(projectNumber)'

# Чаще всего подпись идёт через App Engine default:
gcloud iam service-accounts add-iam-policy-binding \
  PROJECT_ID@appspot.gserviceaccount.com \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Если в Cloud Run у функции указан **другой** service account — используйте его в `--member` вместо `…-compute@…`.

**Вариант B — консоль:** [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) → откройте **`PROJECT_ID@appspot.gserviceaccount.com`** → **Permissions** → **Grant access** → **New principals** = email runtime-аккаунта из Cloud Run → роль **Service Account Token Creator** → Save.

Если в логах упоминается отключённый **Identity and Access Management (IAM) API**, включите его в том же проекте ([ссылка из ошибки](https://console.developers.google.com/apis/api/iam.googleapis.com/overview) или поиск «IAM API» в API Library).

## Поток

- **Web**: диалог с Telegram Widget → callable `signInWithTelegram` → `signInWithCustomToken` → [`finalizeOAuthCredential`](../src/hooks/use-auth.tsx) дозаполняет профиль при необходимости. Callable дополнительно мержит в `users/{uid}` **фото** (`photo_url`) и **телефон**, если виджет/клиент передали одно из полей `phone_number` / `phone` / `contact_phone`, и номер не занят в `registrationIndex` у другого uid; если `users.username` ещё пустой — выставляет **уникальный логин** с приоритетом поля **`username`** из payload виджета (как `@handle` в Telegram, в Firestore без `@`), иначе от `displayName` / `user_<хвост_uid>`.
- **Mobile**: WebView открывает `/auth/telegram?mobile=1` → тот же callable → `TelegramAuth.postMessage(customToken)` → `AuthRepository.signInWithCustomToken`.

## UID в Firebase

Пользователи Telegram получают стабильный UID вида `tg_<telegram_user_id>` (создаётся только сервером).

## Где смотреть логи `signInWithTelegram`

1. **[Firebase Console](https://console.firebase.google.com/)** → ваш проект → **Build → Functions** → функция **`signInWithTelegram`** → вкладка **Logs** (или **View logs in Google Cloud**).
2. **[Google Cloud Console → Logging](https://console.cloud.google.com/logs/query)** — в запросе укажите ресурс Cloud Run для 2nd gen, например:
   `resource.type="cloud_run_revision" AND resource.labels.service_name="signinwithtelegram"`
   (имя сервиса может совпадать с именем функции в нижнем регистре; при необходимости найдите его в **Cloud Run → Services**).
3. **Редактируемый дамп payload виджета** (без секретов): задайте секрет/переменную окружения функции **`TELEGRAM_DEBUG_LOGIN_INFO=1`**, задеплойте функцию и снова выполните вход — в логах появятся ключи полей и объект с редактированием телефона/фото/hash.

Сообщения в **браузерной консоли** (`[auth debug] oauth credential`, ошибки Firestore на клиенте) относятся к **клиенту** после `signInWithCustomToken`, а не к Cloud Function.

## Если после кнопки «Войти как …» callable возвращает `INTERNAL`

1. Убедитесь, что задеплоена актуальная версия `signInWithTelegram` и секрет `TELEGRAM_BOT_TOKEN` от **того же** бота, что в `NEXT_PUBLIC_TELEGRAM_BOT_NAME`.
2. В **Google Cloud → Logging** откройте логи функции: там будет точная причина (`createUser`, `updateUser`, `createCustomToken`).
3. Частые причины: гонка двух параллельных входов (обрабатывается в коде), невалидный `photo_url` от Telegram (повтор без фото), несовпадение токена бота и виджета (тогда обычно `permission-denied`, не `INTERNAL`).
4. В логах: **`createCustomToken failed`** с **`signBlob` / `insufficient-permission`** — настройте IAM по разделу **«IAM: signBlob»** выше (это не баг приложения).
