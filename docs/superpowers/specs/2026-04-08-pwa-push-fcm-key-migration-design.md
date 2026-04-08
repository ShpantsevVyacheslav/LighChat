# Восстановление web push в PWA: миграция API key + защитные проверки

## Контекст

Фактические симптомы:

- В iOS Safari tab: `Can't find variable: Notification`.
- В iOS PWA (Home Screen): `FCM ... missing required authentication credential`.
- На desktop push также не активируется.

Текущая реализация:

- FCM подписка в `src/hooks/use-notifications.ts`.
- Общий web `apiKey` в `src/firebase/config.ts`.
- Ошибки маппятся в `src/lib/fcm-subscribe-user-message.ts`.

## Цель

1. Восстановить успешную подписку на push в desktop + iOS PWA.
2. Исключить ложные/непонятные ошибки в неподдерживаемом контексте (Safari tab).
3. Мигрировать на новый browser API key без простоя и без поломки auth/chat/storage.

## Принятое решение

Комбинированный подход:

1. **Infra migration**: переключить веб-приложение на новый Browser API key с Website restrictions.
2. **App hardening**: добавить защитные проверки поддержки Notification API до `requestPermission()`.
3. **Error UX**: расширить маппинг ошибок, чтобы пользователь получал точную причину и действие.

## Детали infra-миграции

- Новый key используется как `apiKey` в `src/firebase/config.ts`.
- Старый key не удаляется до полного подтверждения стабильности.
- На новом key:
  - `Application restrictions`: Websites.
  - Website restrictions:
    - `https://lighchat.online/*`
    - `https://www.lighchat.online/*`
    - `https://project-72b24.firebaseapp.com/*`
    - `https://project-72b24.web.app/*`
  - `API restrictions`: на этапе безопасной миграции оставить максимально совместимый набор (или весь ранее используемый список), чтобы не сломать auth/firestore/storage.

После стабилизации допускается отдельный hardening-этап с уменьшением списка API.

## Изменения в приложении

### `src/hooks/use-notifications.ts`

- Перед `Notification.requestPermission()` добавить guard:
  - если `typeof Notification === 'undefined'` -> явная ошибка о неподдерживаемом контексте и необходимости открыть установленное PWA.
- Сохранить текущую логику `isSupported()`/SW/getToken с timeout.
- В `catch` оставить технический текст в логах и отдавать нормализованный user-friendly текст через mapper.

### `src/lib/fcm-subscribe-user-message.ts`

- Добавить отдельные сообщения для:
  - отсутствия `Notification` API;
  - `messaging/unsupported-browser`;
  - существующего кейса `missing required authentication credential` (оставить).

## Поток проверки после миграции

1. Обновить `apiKey` в `src/firebase/config.ts`.
2. Deploy web.
3. Проверить на desktop:
   - login,
   - загрузка чатов,
   - вложения,
   - включение push.
4. Проверить на iOS:
   - Safari tab -> ожидаемый отказ с понятным текстом,
   - Home Screen PWA -> успешная подписка push.
5. Только после успешной проверки отключать старый ключ.

## Критерии приемки

1. На desktop и iOS PWA подписка на push завершается без credential-ошибки.
2. В `users/{uid}.fcmTokens` появляется новый токен.
3. Тестовое push-событие (новое сообщение из другого аккаунта) приходит в фоне.
4. В Safari tab пользователь видит корректный отказ (без runtime-падения).
5. После замены `apiKey` не деградируют auth/firestore/storage-потоки.

## Риски и защита

- Риск поломки других Firebase SDK при слишком узком API restrictions:
  - mitigation: на миграции использовать широкий совместимый набор API.
- Риск преждевременного удаления старого key:
  - mitigation: отключать старый ключ только после smoke-проверки всех основных сценариев.
- Риск кэширования старого JS/SW:
  - mitigation: после deploy выполнить hard refresh/перезапуск PWA.
