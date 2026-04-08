# Фикс догрузки истории чата без скачков верстки

## Контекст

В `ChatWindow` есть стартовый лимит загрузки сообщений (`INITIAL_MESSAGE_LIMIT`), далее история должна подгружаться при достижении верха списка (`startReached`).

Симптомы:

- при скролле вверх показывается `Загрузка истории...`;
- индикатор может зависать (вечный лоадер);
- новые страницы истории фактически не добавляются.

Дополнительное требование: не допускать скачков верстки при prepend старых сообщений.

## Цель

1. Восстановить корректную постраничную догрузку older messages.
2. Устранить залипание состояния загрузки.
3. Гарантировать стабильный scroll-position без визуальных прыжков.

## Принятый подход (гибрид)

Сохраняем realtime-listener для активного окна последних сообщений и добавляем отдельный one-shot канал для older pages:

- `liveMessages` — от `onSnapshot` (последние сообщения).
- `olderMessages` — накопленные страницы истории из `getDocs + startAfter(cursor)`.

Такой подход уменьшает риск регрессий в существующем realtime-потоке и делает пагинацию предсказуемой.

## Почему не альтернативы

- Полный переход на cursor-only без realtime для окна чата — слишком большой рефактор для текущей задачи.
- Косметический фикс текущего `displayLimit`-подхода — недостаточно надежен, остаются риски залипания и повторных регрессий.

## Изменяемые компоненты

### `src/components/chat/ChatWindow.tsx`

- Ввести разделение источников данных:
  - `liveMessages` (snapshot),
  - `olderMessages` (batched pagination).
- Финальный список строить как merge с дедупликацией по `id` и сортировкой по `createdAt` asc.
- Переписать `handleLoadMore` на cursor fetch:
  - guard: `if (isLoadingOlder || !hasMore) return`;
  - cursor = oldest loaded message;
  - query: `orderBy(createdAt, 'desc') + startAfter(cursor) + limit(HISTORY_PAGE_SIZE + 1)`;
  - в UI добавлять максимум `HISTORY_PAGE_SIZE`, а `+1` использовать только для определения `hasMore`.
- Убрать зависимость пагинации от увеличения `displayLimit` (чтобы listener не пересоздавался для истории).
- В `Virtuoso` Header показывать loader только при `isLoadingOlder`.
- На reset по смене `conversation.id` очищать `olderMessages`, `isLoadingOlder`, `hasMore` и служебные anchor-поля.

### `src/components/chat/ThreadWindow.tsx`

- Применить аналогичную схему pagination (live window + older pages), чтобы не повторить тот же дефект в тредах.

## Механика "без скачков"

Перед prepend страницы истории:

1. Сохраняется scroll anchor:
   - id первого видимого message-item,
   - его вертикальный offset относительно scroller.

После обновления списка:

2. Находим тот же message-item в DOM.
3. Вычисляем новый offset.
4. Компенсируем смещение через `scrollBy(newOffset - oldOffset)`.

Результат: пользователь остается в том же визуальном месте, старые сообщения добавляются "над" viewport без рывка.

## Поток данных

1. Открытие чата:
   - запускается snapshot на live window;
   - `olderMessages` пуст.
2. Скролл вверх до `startReached`:
   - если `hasMore && !isLoadingOlder`, выполняется batched fetch older page.
3. Ответ fetch:
   - older page prepend в `olderMessages`;
   - `hasMore` обновляется по `pageSize+1` правилу;
   - выполняется anchor compensation.
4. Повторяется до `hasMore=false`.

## Ошибки и устойчивость

- Любая ошибка older fetch должна завершать цикл загрузки (`isLoadingOlder=false` в `finally`).
- Защита от многократного `startReached` — guard по `isLoadingOlder`.
- Дедуп по `id` при merge live/older защищает от наложения окон.
- При пустом батче `hasMore=false`, повторные загрузки не запускаются.

## Критерии приемки

1. История стабильно подгружается пакетами по `HISTORY_PAGE_SIZE` при каждом достижении верха.
2. Вечный loader отсутствует: индикатор виден только во время фактического fetch.
3. При prepend старых сообщений не наблюдается скачков позиции списка.
4. Когда история закончилась, `startReached` больше не инициирует fetch.
5. После нескольких paginate-up отправка/получение новых сообщений и скролл вниз работают как прежде.
6. Те же гарантии соблюдены для `ThreadWindow`.
