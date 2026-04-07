'use client';

/**
 * Элемент `type: 'date'` в flatItems остаётся для стабильных индексов Virtuoso,
 * но визуально не дублирует плавающую метку дня (`ChatFloatingDateLabel`).
 *
 * Высота **не может быть 0**: Virtuoso измеряет строки через ResizeObserver; нулевой размер
 * ломает расчёт viewport («Zero-sized element») и лента может не отрисоваться.
 */
export function ChatDateListAnchor() {
  return (
    <div
      className="pointer-events-none h-px min-h-px w-full shrink-0 overflow-hidden opacity-0"
      aria-hidden
    />
  );
}
