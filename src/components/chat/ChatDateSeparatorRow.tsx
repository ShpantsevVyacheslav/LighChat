'use client';

import { Badge } from '@/components/ui/badge';

/** Капсула даты: фон только здесь — не на всю ширину строки (иначе видна «полоса» под обоями чата). */
export const CHAT_DATE_LABEL_BADGE_CLASSNAME =
  'border-0 bg-background/95 px-4 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest text-muted-foreground shadow-md dark:bg-background/92 dark:shadow-black/40';

type ChatDateSeparatorRowProps = {
  label: string;
  /**
   * Индекс группы по возрастанию даты (0 — самый старый день в ленте).
   * Большее значение — более новый день; выше z-index, чтобы при схлопывании липких заголовков
   * (как в Telegram) более новая дата оказывалась поверх и «вытесняла» старую.
   */
  stickyStackOrder: number;
};

/**
 * Заголовок календарного дня в ленте чата: липкий к верху скроллера (плоский Virtuoso или группа).
 * Обёртка без фона — только центрированная капсула; иначе на тёмной теме тянется чёрная полоса на всю ширину.
 */
export function ChatDateSeparatorRow({ label, stickyStackOrder }: ChatDateSeparatorRowProps) {
  const z = 24 + Math.min(Math.max(0, stickyStackOrder), 600);
  return (
    <div
      className="sticky top-0 flex w-full shrink-0 justify-center border-0 bg-transparent py-2 px-4 shadow-none ring-0 outline-none"
      style={{ zIndex: z }}
    >
      <Badge variant="secondary" className={`${CHAT_DATE_LABEL_BADGE_CLASSNAME} pointer-events-none`}>
        {label}
      </Badge>
    </div>
  );
}
