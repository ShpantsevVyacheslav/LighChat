'use client';

import Image from 'next/image';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

/** Тот же ресурс, что на экране входа — квадратный PNG с альфой. */
const BRAND_MARK_SRC = '/brand/lighchat-mark.png';

type LighChatSidebarMarkButtonProps = {
  onClick: () => void;
  /** Узкий режим (колонка ~80px при свёрнутом списке). */
  compact?: boolean;
  title?: string;
};

/**
 * Кликабельный знак LighChat (маяк) для сворачивания/разворачивания боковой колонки чатов на десктопе.
 */
export function LighChatSidebarMarkButton({
  onClick,
  compact = false,
  title,
}: LighChatSidebarMarkButtonProps) {
  const { t } = useI18n();
  const resolvedTitle = title ?? t('chat.sidebar.togglePanel');
  const side = compact ? 26 : 34;
  return (
    <button
      type="button"
      onClick={onClick}
      title={resolvedTitle}
      aria-label={resolvedTitle}
      className={cn(
        'flex shrink-0 items-center justify-center rounded-2xl transition-colors',
        'hover:bg-white/12 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40',
        'dark:hover:bg-white/[0.08]',
        compact ? 'mx-auto py-1.5 px-1' : 'mx-1 py-1.5'
      )}
    >
      <Image
        src={BRAND_MARK_SRC}
        alt=""
        width={side}
        height={side}
        className="object-contain drop-shadow-sm"
      />
    </button>
  );
}
