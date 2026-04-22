# Вход через Telegram (LighChat)

## Что настроить вручную

1. **BotFather** — создать бота, получить токен, командой `/setdomain` указать домен сайта (тот же, с которого открывается Login Widget), например `lighchat.app` и для staging — отдельный бот или тот же домен.
2. **Firebase Functions** — секрет с токеном бота:
   ```bash
   firebase functions:secrets:set TELEGRAM_BOT_TOKEN
   ```
   Затем задеплоить функции (`signInWithTelegram`).
3. **Next.js / хостинг** — переменная **`NEXT_PUBLIC_TELEGRAM_BOT_NAME`** (username бота **без** `@`). Без неё кнопка Telegram на главной входа отключена.
4. **Firebase Authentication → Settings → Authorized domains** — домен приложения (для вызова callable из браузера / WebView).
5. **Flutter (опционально)** — если мост не на production-домене, сборка с  
   `--dart-define=TELEGRAM_AUTH_BRIDGE_URL=https://ваш-хост`  
   (без завершающего `/`). Иначе по умолчанию используется `https://lighchat.app/auth/telegram?mobile=1`.

## Поток

- **Web**: диалог с Telegram Widget → callable `signInWithTelegram` → `signInWithCustomToken` → дозаполнение профиля при необходимости.
- **Mobile**: WebView открывает `/auth/telegram?mobile=1` → тот же callable → `TelegramAuth.postMessage(customToken)` → `AuthRepository.signInWithCustomToken`.

## UID в Firebase

Пользователи Telegram получают стабильный UID вида `tg_<telegram_user_id>` (создаётся только сервером).
