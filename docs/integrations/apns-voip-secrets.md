# APNs VoIP: секрет для Cloud Functions (`oncallcreated`)

Триггер [`oncallcreated`](../../functions/src/triggers/firestore/onCallCreated.ts) монтирует **один** секрет Firebase / Google Cloud Secret Manager: **`APNS_VOIP_CONFIG`**.

Значение — **JSON** (одна строка или многострочный файл). Поля:

| Поле | Тип | Описание |
|------|-----|----------|
| `keyId` | string | Key ID из Apple Developer (ключ APNs) |
| `teamId` | string | Team ID |
| `bundleId` | string | Bundle ID iOS-приложения (без `.voip` — суффикс добавляет код) |
| `privateKeyPem` | string | Содержимое `.p8` целиком; в JSON переводы строк можно задать как `\n` или `\\n` |
| `useSandbox` | boolean или строка | `true` / `1` — sandbox APNs (`api.sandbox.push.apple.com`) |

Если секрет пустой или поля не заполнены, VoIP push **пропускается** (остаётся FCM и остальная логика звонка).

## Ошибка при деплое: «no latest version of the secret …»

Firebase при анализе кода проверяет, что у каждого `defineSecret` в Secret Manager есть **версия `latest`**. Создайте секрет хотя бы с заглушкой:

```bash
printf '%s' '{"keyId":"","teamId":"","bundleId":"","privateKeyPem":"","useSandbox":false}' | firebase functions:secrets:set APNS_VOIP_CONFIG
```

Затем снова `firebase deploy --only functions`. После появления реального `.p8` обновите значение тем же способом (новая версия секрета).

## Реальные значения

1. В Apple Developer создайте ключ APNs (`.p8`), выпишите `Key ID` и `Team ID`.
2. Соберите JSON (удобно положить `.p8` в файл и подставить содержимое в `privateKeyPem` с `\n` внутри строки).
3. Выполните:

```bash
firebase functions:secrets:set APNS_VOIP_CONFIG
```

и вставьте JSON (в терминале многострочный ввод завершите `Ctrl+D`).

## Миграция со старых пяти секретов

Раньше использовались отдельные секреты `APNS_VOIP_AUTH_KEY`, `APNS_VOIP_KEY_ID`, … — они **больше не читаются кодом**. Старые имена в GSM можно удалить вручную после переноса значений в один JSON `APNS_VOIP_CONFIG`.
