'use client';

import type { CSSProperties } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useSettings } from '@/hooks/use-settings';
import { NAV_LINKS } from '@/lib/constants';
import { useTotalUnreadCount } from '@/hooks/use-unread-counts';
import { cn } from '@/lib/utils';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { Badge } from '@/components/ui/badge';
import { DashboardAccountNavButton } from '@/components/dashboard/DashboardAccountNavButton';
import { bottomNavIosTileClasses } from '@/lib/bottom-nav-ios-tiles';
import { resolveBottomNavLucideIconName } from '@/lib/bottom-nav-icons';
import { LucideBottomNavIcon } from '@/components/dashboard/LucideBottomNavIcon';

export type DashboardBottomNavVariant = 'fullWidth' | 'chatSidebar';

/**
 * Нижняя навигация по разделам дашборда (иконки + аватар с меню профиля).
 * `fullWidth` — в `dashboard/layout`; `chatSidebar` — только под колонкой списка чатов (десктоп).
 */
export function DashboardBottomNav({
  variant = 'fullWidth',
  sidebarCollapsed = false,
}: {
  variant?: DashboardBottomNavVariant;
  /** Только для `chatSidebar`: в свёрнутой колонке списка чатов — одна кнопка профиля по центру. */
  sidebarCollapsed?: boolean;
}) {
  const { user } = useAuth();
  const { chatSettings } = useSettings();
  const pathname = usePathname();
  const totalUnreadCount = useTotalUnreadCount(user?.id);

  const role = user?.role;
  if (!user || !role) return null;

  const links = NAV_LINKS.filter((link) => (link.roles as string[]).includes(role));
  const appearance = chatSettings.bottomNavAppearance ?? 'colorful';

  if (variant === 'chatSidebar' && sidebarCollapsed) {
    return (
      <nav
        className={cn(
          'border-t border-white/25 pb-[max(0.35rem,env(safe-area-inset-bottom))] pt-1 backdrop-blur-3xl backdrop-saturate-150 dark:border-white/10',
          'bg-white/45 shadow-none dark:bg-zinc-950/45'
        )}
        aria-label="Профиль"
      >
        <div className="flex w-full items-center justify-center px-2 py-1">
          <DashboardAccountNavButton popoverAlign="center" className="h-10 w-10" navAppearance={appearance} />
        </div>
      </nav>
    );
  }

  return (
    <nav
      className={cn(
        'border-t border-white/30 pb-[max(0.35rem,env(safe-area-inset-bottom))] pt-1 backdrop-blur-3xl backdrop-saturate-150 dark:border-white/12',
        variant === 'fullWidth' &&
          'bg-white/55 shadow-[0_-8px_32px_rgba(0,0,0,0.08)] dark:bg-zinc-950/55 dark:shadow-[0_-8px_36px_rgba(0,0,0,0.45)]',
        variant === 'chatSidebar' &&
          'border-black/10 bg-white/42 shadow-none dark:border-white/10 dark:bg-zinc-950/45'
      )}
      aria-label="Разделы приложения"
    >
      <div
        className={cn(
          'flex items-center justify-center gap-0.5 overflow-x-auto px-2 py-1 scrollbar-hide',
          variant === 'fullWidth' && 'mx-auto max-w-3xl',
          variant === 'chatSidebar' && 'w-full max-w-none'
        )}
      >
        {links.map((link) => {
          const isChatLink = link.href === '/dashboard/chat';
          const showBadge = isChatLink && totalUnreadCount > 0;
          const isActive =
            link.href === '/dashboard' ? pathname === link.href : pathname.startsWith(link.href);
          const Icon = link.icon;
          const tileClass = bottomNavIosTileClasses(link.href);
          const dynamicIconName = resolveBottomNavLucideIconName(
            link.href,
            chatSettings.bottomNavIconNames
          );
          const visual = chatSettings.bottomNavIconStyles?.[link.href];
          const defaultStroke = appearance === 'colorful' ? 2.35 : isActive ? 2.35 : 2;
          const strokeW =
            typeof visual?.strokeWidth === 'number' &&
            Number.isFinite(visual.strokeWidth) &&
            visual.strokeWidth >= 0.75
              ? visual.strokeWidth
              : defaultStroke;
          const customIconColor =
            typeof visual?.iconColor === 'string' && visual.iconColor.trim().length > 0
              ? visual.iconColor.trim()
              : null;
          /** Кастомный фон плитки — в обоих пресетах нижнего меню (раньше только «цветные плитки»). */
          const useCustomTileBg =
            typeof visual?.tileBackground === 'string' && visual.tileBackground.trim().length > 0;
          const tileInlineStyle: CSSProperties | undefined = useCustomTileBg
            ? {
                background: visual!.tileBackground!.trim(),
                boxShadow:
                  '0 4px 14px rgba(0,0,0,0.28), inset 0 1px 0 rgba(255,255,255,0.35)',
              }
            : undefined;
          const iconInlineStyle: CSSProperties | undefined = customIconColor
            ? { color: customIconColor }
            : undefined;

          return (
            <Tooltip key={link.href}>
              <TooltipTrigger asChild>
                <Link
                  href={link.href}
                  className={cn(
                    'relative flex min-h-12 min-w-10 flex-1 flex-col items-center justify-center rounded-2xl px-1.5 py-1 transition-[background,transform] duration-200 sm:min-w-11',
                    'hover:bg-white/25 hover:backdrop-blur-md dark:hover:bg-white/[0.07]',
                    isActive &&
                      'bg-white/45 shadow-sm backdrop-blur-xl dark:bg-white/[0.12] dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]'
                  )}
                >
                  <span className="relative inline-flex">
                    <span
                      className={cn(
                        'flex h-11 w-11 items-center justify-center rounded-[1.25rem] transition-[box-shadow,transform] duration-200',
                        appearance === 'colorful' && !useCustomTileBg && tileClass,
                        appearance === 'minimal' && !useCustomTileBg && 'bg-transparent shadow-none'
                      )}
                      style={tileInlineStyle}
                    >
                      <LucideBottomNavIcon
                        name={dynamicIconName}
                        fallbackIcon={Icon}
                        className={cn(
                          'h-[22px] w-[22px] shrink-0',
                          appearance === 'colorful' &&
                            !customIconColor &&
                            'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]',
                          appearance === 'minimal' &&
                            !customIconColor &&
                            (useCustomTileBg
                              ? 'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]'
                              : isActive
                                ? 'text-primary'
                                : 'text-muted-foreground')
                        )}
                        style={iconInlineStyle}
                        strokeWidth={strokeW}
                      />
                    </span>
                    {showBadge && (
                      <Badge className="absolute -right-1.5 -top-1 flex h-[18px] min-w-[18px] justify-center rounded-full border-2 border-white bg-[#FF3B30] p-0 text-[9px] font-bold text-white shadow-sm dark:border-zinc-900">
                        {totalUnreadCount > 99 ? '99+' : totalUnreadCount}
                      </Badge>
                    )}
                  </span>
                </Link>
              </TooltipTrigger>
              <TooltipContent side="top">{link.label}</TooltipContent>
            </Tooltip>
          );
        })}
        <DashboardAccountNavButton className="min-w-10 sm:min-w-11" navAppearance={appearance} />
      </div>
    </nav>
  );
}
