/**
 * Стили «плиток» нижней навигации в духе iOS: насыщенные градиенты + сквиркл.
 * Ключ — `href` из NAV_LINKS.
 */
export const BOTTOM_NAV_IOS_TILE_BY_HREF: Record<
  string,
  {
    /** Классы градиента, тени и подсветки «стекла» на плитке */
    tileClass: string;
  }
> = {
  '/dashboard/chat': {
    tileClass:
      'bg-gradient-to-b from-[#6CF0A4] via-[#34D97E] to-[#0DB56A] shadow-[0_4px_14px_rgba(13,181,106,0.55),inset_0_1px_0_rgba(255,255,255,0.45)] dark:shadow-[0_4px_18px_rgba(13,181,106,0.35),inset_0_1px_0_rgba(255,255,255,0.2)]',
  },
  '/dashboard/contacts': {
    tileClass:
      'bg-gradient-to-b from-[#FFCC66] via-[#FF9F40] to-[#FF6B1A] shadow-[0_4px_14px_rgba(255,107,26,0.45),inset_0_1px_0_rgba(255,255,255,0.4)] dark:shadow-[0_4px_18px_rgba(255,107,26,0.3),inset_0_1px_0_rgba(255,255,255,0.2)]',
  },
  '/dashboard/meetings': {
    tileClass:
      'bg-gradient-to-b from-[#6EB7FF] via-[#3C9EFF] to-[#0A6EDF] shadow-[0_4px_14px_rgba(10,110,223,0.5),inset_0_1px_0_rgba(255,255,255,0.42)] dark:shadow-[0_4px_18px_rgba(10,110,223,0.35),inset_0_1px_0_rgba(255,255,255,0.2)]',
  },
  '/dashboard/calls': {
    tileClass:
      'bg-gradient-to-b from-[#B794F6] via-[#8B5CF6] to-[#5B21B6] shadow-[0_4px_14px_rgba(91,33,182,0.45),inset_0_1px_0_rgba(255,255,255,0.4)] dark:shadow-[0_4px_18px_rgba(91,33,182,0.3),inset_0_1px_0_rgba(255,255,255,0.18)]',
  },
};

export function bottomNavIosTileClasses(href: string): string {
  return (
    BOTTOM_NAV_IOS_TILE_BY_HREF[href]?.tileClass ??
    'bg-gradient-to-b from-muted to-muted-foreground/30 shadow-md'
  );
}
