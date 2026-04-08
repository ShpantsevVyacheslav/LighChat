# iOS regression: зум в fullscreen media viewer

## Контекст

В fullscreen просмотре медиа (фото/видео в чате) на iOS перестал работать zoom жестами. На desktop текущее поведение корректное, и его нужно сохранить.

Текущая реализация в `src/components/chat/media-viewer.tsx` использует:

- `react-zoom-pan-pinch` для zoom/pan.
- touch-обработчики на контейнере `DialogContent` для swipe-down закрытия (`translateY`).

Гипотеза регрессии: контейнер перехватывает touch-события и в vertical-ветке делает `preventDefault`, что на iOS блокирует pinch/zoom в media-зоне.

## Цель

Восстановить iOS zoom/pan в fullscreen viewer без регресса desktop и без потери swipe-down-to-close.

## Принятое решение

Выбран подход с **разделением зон жестов**:

- `media-zone`: область контента `TransformComponent` (изображение/видео).
  - Жесты zoom/pan обрабатывает `react-zoom-pan-pinch`.
  - Контейнер не должен делать `stopPropagation`/`preventDefault`.
- `overlay-zone`: фон/хром viewer за пределами media-зоны.
  - Сохраняется текущий свайп вниз для закрытия.

## Почему не альтернативы

- Полное отключение swipe-down на iOS: быстро, но деградация UX.
- Вынос dismiss-жеста только на узкие края: чище технично, но меняет привычную механику закрытия.

Выбранный вариант минимально инвазивен и ближе всего к текущему UX.

## Затрагиваемые компоненты

### `src/components/chat/media-viewer.tsx`

- Добавить ref на media-интерактивную область (`mediaInteractiveRef`).
- В touch-обработчиках определять, пришло ли событие из media-зоны через `contains(target)`.
- Ввести scope жеста (`media`/`overlay`) и разделить поведение:
  - `media`: не запускать dismiss-логику, не блокировать события.
  - `overlay`: оставить текущую логику vertical swipe-to-close.
- Оставить текущую механику double tap:
  - первый двойной тап увеличивает,
  - повторный двойной тап возвращает к исходному масштабу.

Дополнительно:

- Проверить/зафиксировать `touch-action` у media-зоны так, чтобы не мешать multi-touch на iOS (без `touch-action: none` для этой зоны).

### Не требует изменений

- `src/components/chat/ChatWindow.tsx`
- `src/components/chat/ThreadWindow.tsx`

Контракты открытия `MediaViewer` остаются прежними.

## Поток событий

1. `touchstart`:
   - если target внутри media-зоны -> `gestureScope=media`;
   - иначе -> `gestureScope=overlay` и инициализация dismiss-состояния.
2. `touchmove`:
   - `media` -> контейнер не вмешивается;
   - `overlay` -> действует текущий анализ направления и `translateY`.
3. `touchend`:
   - `media` -> только очистка служебного состояния;
   - `overlay` -> текущая логика закрытия по порогу (`abs(translateY) > 120`) или возврат на место.

## Критерии приемки

На iOS:

1. Pinch-in/pinch-out в fullscreen фото корректно меняет масштаб.
2. Pan по увеличенному фото работает без случайного закрытия viewer.
3. Первый двойной тап делает zoom-in, повторный двойной тап делает reset.
4. Swipe-down вне media-зоны (overlay/header) закрывает viewer.
5. Видео controls/play не ломаются.

На desktop:

1. Текущее поведение zoom/double-tap parity не регрессирует.
2. Навигация карусели и UI-controls работают как раньше.

## Риски и защита

- Риск конфликтов на границе зон: mitigated через `contains(target)` и явный `gestureScope`.
- Риск повторной блокировки pinch: `preventDefault` допускается только в `overlay`-ветке при vertical-dismiss.
- Риск регресса закрытия: сохраняются текущие пороги и анимации dismiss.
