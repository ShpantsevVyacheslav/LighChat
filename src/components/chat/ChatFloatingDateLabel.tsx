'use client';

import { Badge } from '@/components/ui/badge';
import { CHAT_DATE_LABEL_BADGE_CLASSNAME } from '@/components/chat/ChatDateSeparatorRow';

type ChatFloatingDateLabelProps = {
  /** Уже отформатированная подпись (как у разделителя в ленте); `null` — не показывать. */
  label: string | null;
};

/**
 * Метка дня у верхней кромки области списка. Virtuoso задаёт айтемам `transform`,
 * из‑за этого `position: sticky` на строках ленты не срабатывает — дублируем визуал фиксированно.
 */
export function ChatFloatingDateLabel({ label }: ChatFloatingDateLabelProps) {
  if (!label) return null;
  return (
    <div
      className="pointer-events-none absolute left-0 right-0 top-2 z-[50] flex justify-center px-4"
      aria-hidden
    >
      <Badge variant="secondary" className={`${CHAT_DATE_LABEL_BADGE_CLASSNAME} shadow-sm`}>
        {label}
      </Badge>
    </div>
  );
}
