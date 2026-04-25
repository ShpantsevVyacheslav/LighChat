## Mobile auth parity: web source of truth

Этот документ фиксирует требования к мобильной авторизации/регистрации **1-в-1 с web**, чтобы Flutter-реализация повторяла поведение `src/hooks/use-auth.tsx`.

### Supported auth providers (same as web)
- **Email/Password**
- **Google**

### Registration (Email/Password) — required fields and validation
Источник: `src/lib/register-profile-schema.ts`.

- **name**
  - trim
  - min length: 2
- **username**
  - trim
  - allowed: латиница/цифры/`_`, допускает префикс `@` (удаляется при нормализации)
  - min length: 3, max length: 30
  - regex: `^@?[a-zA-Z0-9_]+$`
- **phone**
  - после удаления всех не-цифр: **ровно 11 цифр**
- **email**
  - валидный email (формат)
- **dateOfBirth** (optional)
  - если задан: год в диапазоне `1920..currentYear`
- **bio** (optional)
  - max length: 200
- **password**
  - min length: 6
- **confirmPassword**
  - совпадает с `password`

### Registration availability checks (pre-auth)
Источник: `src/lib/registration-field-availability.ts` + `src/lib/registration-index-keys.ts`.

Проверки выполняются через чтение документов:
- `registrationIndex/{key}` — если документ существует и `uid` не равен `exceptUid`, поле считается занятым.

Ключи:
- **phone**: `p_${digits}` где `digits` — normalizePhoneDigits; если `<10` → `null`
- **email**: `e_${utf8ToBase64Url(lowerTrimEmail)}`; анонимные placeholder email (`guest_*@anonymous.com`) не участвуют в индексе
- **username**: `u_${normalizedLowerUsernameWithoutAt}`

### Profile completion criteria (Google completion and registration completeness)
Источник: `src/lib/registration-profile-complete.ts`.

Профиль считается завершённым, если:
- `name.trim().length >= 2`
- `username` после нормализации (`trim`, remove leading `@`, lowercase):
  - `3..30`
  - regex: `^[a-zA-Z0-9_]+$`
- `email.trim()` соответствует простому email regex (`^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$`)

Телефон **не обязателен** для первого входа (соц-вход / email регистрация), но требуется для сценариев, где есть поиск/добавление контактов по номеру.

### Firestore user document (target shape)
Источник: `src/lib/types.ts` (`User`).

Минимально значимые для auth/registration поля:
- `id` (uid)
- `name`
- `username`
- `email`
- `phone`
- `avatar` (full url)
- `avatarThumb` (optional)
- `bio` (optional)
- `dateOfBirth` (optional)
- `deletedAt` (nullable; если не null — вход ограничен)
- `createdAt` (ISO string)

Остальные поля (настроечные/присутствие/FCM) не обязательны для первого паритетного auth-потока, но должны сохранять обратную совместимость при наличии.

