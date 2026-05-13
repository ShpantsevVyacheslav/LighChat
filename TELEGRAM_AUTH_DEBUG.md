# Отладка Telegram авторизации - инструкция

## Шаг 1: Пересобрать Flutter app
```bash
cd mobile/app
flutter clean
flutter pub get
flutter run
```

## Шаг 2: Открыть консоль Flutter для логов

### Вариант 1: Xcode (iOS)
```
Xcode → Window → Devices and Simulators
Выберите устройство/симулятор
Откройте Console tab
```

### Вариант 2: Android Studio
```
Logcat view (нижняя панель)
Фильтр: "AUTH" или "[UI-AUTH]"
```

## Шаг 3: Попробовать Google и Telegram авторизацию
На устройстве iOS нажмите на кнопку "Google" или "Telegram" и попытайтесь авторизоваться.

**Смотрите логи в консоли - они должны показать:**

### Google Auth flow:
```
[AUTH] Google Sign-In: Starting...
[AUTH] Google Sign-In: Attempt 1/3 - calling signInWithProvider
[UI-AUTH] OAuth flow: Starting...
[UI-AUTH] OAuth flow: Calling signIn function...
... (Firebase OAuth процесс)
[AUTH] Google Sign-In: SUCCESS - User signed in
[UI-AUTH] OAuth flow: signIn completed successfully
[UI-AUTH] OAuth flow: Checking current user...
[UI-AUTH] OAuth flow: Current user: google-xyz123
... (проверка профиля и навигация)
```

### Telegram Auth flow:
```
[UI-AUTH] OAuth flow: Starting...
... (WebView с Telegram)
[AUTH] Custom Token Sign-In: Starting...
[AUTH]   Token length: 245
[AUTH] Custom Token Sign-In: SUCCESS
[UI-AUTH] OAuth flow: signIn completed successfully
... (проверка профиля и навигация)
```

**Если видите ошибку:**
```
[AUTH] Google Sign-In: ERROR (attempt 1/3)
[AUTH]   Code: auth/network-request-failed
[AUTH]   Message: A network error (such as timeout, interrupted connection or unreachable host) has occurred.
[AUTH]   IsNetworkError: true
[AUTH] Google Sign-In: Retrying after 250ms
```

## Шаг 4: Собрать логи Firebase Cloud Functions (только для Telegram)

### Вариант 1: Console (веб)
1. Откройте [Firebase Console](https://console.firebase.google.com/project/project-72b24/functions/list)
2. Кликните на функцию `signInWithTelegram`
3. Перейдите в tab "Logs"
4. Выберите time range (последние несколько минут)
5. Ищите записи типа:
   - ✅ `signInWithTelegram: Request received` — функция вызвана
   - ✅ `signInWithTelegram: Rate limit passed` — rate limit OK
   - ✅ `signInWithTelegram: Telegram signature verified` — подпись OK
   - ✅ `signInWithTelegram: Anti-replay passed` — anti-replay OK
   - ✅ `signInWithTelegram: User created/updated successfully` — пользователь создан
   - ✅ `signInWithTelegram: Authentication successful` — УСПЕХ!
   - ❌ Любые `ERROR` или `WARN` строки

### Вариант 2: CLI
```bash
# Логи за последний час (с более подробной информацией)
gcloud functions logs read signInWithTelegram \
  --region=us-central1 \
  --gen2 \
  --limit=100 \
  --format=json

# Или в более читаемом формате
gcloud functions logs read signInWithTelegram \
  --region=us-central1 \
  --gen2 \
  --limit=50
```

### Вариант 3: Cloud Logging (самый мощный)
1. Откройте [Cloud Logging](https://console.cloud.google.com/logs/query)
2. Вставьте запрос:
```
resource.type="cloud_function"
resource.labels.function_name="signInWithTelegram"
resource.labels.region="us-central1"
severity >= "DEBUG"
```
3. Кликните "RUN QUERY"
4. Найдите записи про ваш вызов (по времени)

## Шаг 5: Интерпретировать логи

### Нормальный flow (успех):
```
Request received → Rate limit passed → Telegram signature verified → Anti-replay passed → User created → Authentication successful
```

### Возможные проблемы:

**❌ "Rate limit exceeded"**
- Вы делаете слишком много попыток авторизации подряд
- Решение: подождите 60 секунд и попробуйте снова

**❌ "Telegram signature verification failed"**
- Payload неправильный или повреждён при передаче
- Проверьте, что WebView правильно передаёт данные

**❌ "Invalid Telegram authorization"**
- HMAC проверка не прошла
- Значит либо бот-токен неправильный, либо данные повреждены

**❌ "Replay attempt detected"**
- Вы пытались использовать один и тот же Telegram auth дважды
- Это нормально на начальных тестах — просто авторизуйтесь снова

**❌ "createCustomToken failed"**
- Firebase Auth не может создать custom token
- Проверьте Firebase Console и App Check статус

## Шаг 6: Поделиться логами

### Собрать логи из Flutter (самое важное!)
```
1. В Xcode Console скопируйте все логи с префиксами [AUTH] и [UI-AUTH]
2. Это покажет точное место ошибки и детали
```

### Собрать логи из Firebase (только если Telegram не работает)
```
gcloud functions logs read signInWithTelegram --region=us-central1 --gen2 --limit=100
```

Отправьте мне:

**От Flutter (обязательно):**
- Полный flow с логами [AUTH] и [UI-AUTH]
- Точные ошибки с кодами (auth/network-request-failed и т.п.)
- Время и порядок событий

**От Firebase (если Telegram не работает):**
- Логи от signInWithTelegram функции
- Любые ERROR или WARN сообщения
- Время попытки авторизации

## Быстрая проверка App Check

Если все логи показывают успех, но ошибки остаются, может быть проблема с App Check в самой системе:

```bash
# Проверить App Check enforcement status
gcloud firestore databases describe default --project=project-72b24

# Проверить если есть Cloud Armor rules
gcloud compute security-policies list --project=project-72b24
```

## Результат

После добавленного логирования каждый вызов `signInWithTelegram` будет записывать:
- Когда пришёл запрос
- Какие данные пришли
- На каком этапе произошла ошибка (если есть)
- Полный error stack (если есть)

Это поможет точно идентифицировать, где ломается авторизация.
