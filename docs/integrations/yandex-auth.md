# Вход и регистрация через Яндекс (LighChat Web)

## Поток

1. Пользователь нажимает «Яндекс» на главной (`/`) → браузер переходит на **`GET /api/auth/yandex`**.
2. Сервер Next.js ставит HttpOnly-cookie с `state`, редирект на **oauth.yandex.ru**.
3. После согласия Яндекс ведёт на **`GET /api/auth/yandex/callback?code=…&state=…`**.
4. Сервер обменивает `code` на `access_token`, читает профиль **login.yandex.ru/info**, создаёт/обновляет пользователя Firebase с UID **`ya_<числовой_id_Яндекса>`**, выпускает **custom token** с claim `yandex: true`.
5. Редирект на **`/auth/yandex#customToken=…`** → клиент вызывает `signInWithCustomToken` → сразу в приложение. Сервер дополнительно пытается записать в `users/{uid}` **username** (первый кандидат — `login` Яндекса; если `login` выглядит как email, для ника используется **только локальная часть до `@`**, например `name.surname@domain` → `name.surname`, дальше автосуффиксы по `registrationIndex`), **телефон** (`default_phone.number`, OAuth scope в кабинете чаще **`login:default_phone`**, в доке также встречается `login:phone`) и **аватар** из Яндекса, если в профиле они ещё пустые/заглушка; телефон **не пишется**, если в `registrationIndex` уже есть другой владелец этого номера. Клиентский [`finalizeOAuthCredential`](../src/hooks/use-auth.tsx) дозаполняет email и подтягивает `photoURL` из Firebase Auth. Телефон по-прежнему можно задать вручную в профиле (нужен для сценариев контактов по телефону).

## Переменные окружения

| Переменная | Где | Назначение |
|------------|-----|------------|
| **`YANDEX_CLIENT_SECRET`** | только сервер (хостинг / `.env.local`, не в git) | Секрет приложения из кабинета Яндекса |
| **`YANDEX_CLIENT_ID`** | сервер (опционально, если не хотите дублировать) | Client ID; если не задан, для обмена кода берётся `NEXT_PUBLIC_YANDEX_CLIENT_ID` |
| **`NEXT_PUBLIC_YANDEX_CLIENT_ID`** | опционально | Дубликат Client ID для удобства; на главной кнопка «Яндекс» **всегда активна**, сервер читает `YANDEX_CLIENT_ID` или этот ключ |
| **`YANDEX_SCOPE`** | сервер (опционально) | Список scope для `oauth.yandex.ru/authorize`. Если не задано — дефолт совпадает с типовым набором в кабинете: `login:email login:info login:avatar login:birthday login:default_phone`. Строка **должна** совпадать с тем, что реально подключено у приложения; иначе Яндекс вернёт `invalid_scope`. Узкий набор можно задать вручную (например, без ДР или телефона). |

Локально: задайте **`YANDEX_CLIENT_ID`** и **`YANDEX_CLIENT_SECRET`** (и при желании продублируйте ID в `NEXT_PUBLIC_YANDEX_CLIENT_ID`).

## Redirect URI в кабинете Яндекса

Должны совпадать с тем, что формирует сервер (`origin` из запроса):

- `https://lighchat.online/api/auth/yandex/callback`
- `http://localhost:3000/api/auth/yandex/callback` (разработка)

## Firebase Admin на хостинге

Обмен кода и выпуск custom token выполняются в **Route Handlers** Next.js (`runtime: nodejs`). Нужны рабочие **Application Default Credentials** для Firebase Admin (как у других server-эндпойнтов проекта). Если `createCustomToken` падает с `signBlob` / IAM — см. аналогичные шаги для Cloud Functions в `docs/integrations/telegram-auth.md` (роль **Service Account Token Creator** на нужном service account).

## Безопасность

- **Не коммитьте** `YANDEX_CLIENT_SECRET` и не вставляйте его в клиентский код.
- Если секрет когда-либо светился в чате или в репозитории — **смените Client secret** в кабинете Яндекса и обновите значение в секретах/переменных окружения.

## Мобильное приложение (Flutter)

На экране входа есть кнопка **«Продолжить с Яндекс»**: открывается WebView с URL старта OAuth (по умолчанию `https://lighchat.online/api/auth/yandex`). После редиректа на `/auth/yandex#customToken=…` приложение вызывает `signInWithCustomToken`, как для Telegram.

Переопределить URL (staging и т.д.):

```bash
flutter run --dart-define=YANDEX_OAUTH_START_URL=https://ваш-хост/api/auth/yandex
```

Без завершающего `/` в конце полного URL (лишний слэш в конце строки из define убирается в коде).
