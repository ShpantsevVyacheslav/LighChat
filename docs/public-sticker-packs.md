# Общие стикерпаки (`publicStickerPacks`)

Наборы стикеров (включая GIF как `image/gif`), доступные **всем вошедшим** пользователям во вкладке «Стикеры» в меню вложений.

## Модель данных

### Firestore

- Документ пака: `publicStickerPacks/{packId}`
  - `name` (string) — название в UI
  - `sortOrder` (number) — порядок сортировки (меньше — выше в списке)
  - `createdAt`, `updatedAt` — ISO-строки времени
- Стикер: `publicStickerPacks/{packId}/items/{itemId}`
  - Поля как у личного пака: `downloadUrl`, `storagePath`, `contentType`, `size`, опционально `width`, `height`, `createdAt`

Типы в коде: [`src/lib/public-sticker-packs.ts`](../src/lib/public-sticker-packs.ts).

### Storage

Файлы: `public/sticker-packs/{packId}/{имя_файла}`

Правила: чтение — любой авторизованный; запись — только пользователь с `users/{uid}.role == "admin"` (см. [`storage.rules`](../storage.rules)).

## Правила доступа

- [`firestore.rules`](../firestore.rules): блок `match /publicStickerPacks/{packId}` — **read** для `isSignedIn()`, **write** для `isAdmin()`.

После изменения правил:

```bash
npm run deploy:firestore
firebase deploy --only storage
```

(или эквивалентные команды для вашего проекта.)

## Как наполнить каталог

Запись с клиентского приложения обычным пользователем **недоступна** — только роль **admin** в документе профиля `users/{uid}`.

### Вариант A: Firebase Console

1. **Storage:** загрузите файлы в `public/sticker-packs/{packId}/` (сгенерируйте `packId` заранее или используйте auto-id из шага 2).
2. **Firestore:** создайте документ `publicStickerPacks/{packId}` с полями `name`, `sortOrder`, `createdAt`, `updatedAt`.
3. Для каждого файла создайте документ в `publicStickerPacks/{packId}/items/{itemId}`:
   - `downloadUrl` — URL из Storage («Get download URL» / публичная ссылка объекта)
   - `storagePath` — полный путь объекта в бакете (как в личных стикерах)
   - `contentType`, `size`, при необходимости `width`, `height`, `createdAt`

### Вариант B: Admin SDK (скрипт или Cloud Function)

Используйте `firebase-admin`: загрузка в Storage, затем `setDoc` / `addDoc` для пака и `items`. Пример окружения: каталог [`functions/`](../functions/) проекта уже зависит от `firebase-admin`.

Убедитесь, что у всех документов паков есть поле **`sortOrder`**, иначе запрос `orderBy('sortOrder')` на клиенте может вернуть ошибку для документов без поля.

## Поведение в приложении

- Общие паки отображаются в строке выбора пака (кнопки с пунктирной обводкой); свои паки — справа от разделителя.
- Редактирование общих паков из UI не предусмотрено; личные действия («С устройства», «Дублировать», «Удалить», удаление стикера) отключены при выбранном общем паке.
