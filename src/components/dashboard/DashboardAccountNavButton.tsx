'use client';

import * as React from 'react';
import { useAuth } from '@/hooks/use-auth';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';
import type { ChatSettings } from '@/lib/types';
import { DashboardAccountMenuContent } from '@/components/dashboard/DashboardAccountMenuContent';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { useI18n } from '@/hooks/use-i18n';

type DashboardAccountNavButtonProps = {
  className?: string;
  /** Выравнивание меню относительно триггера (в узком сайдбаре удобно `center`). */
  popoverAlign?: 'start' | 'center' | 'end';
  /** Согласованно с нижним меню (настройки → чаты). */
  navAppearance?: ChatSettings['bottomNavAppearance'];
};

/**
 * Кнопка с аватаром и тем же меню, что в сайдбаре — для нижней навигации на странице чатов.
 */
export function DashboardAccountNavButton({
  className,
  popoverAlign = 'end',
  navAppearance = 'colorful',
}: DashboardAccountNavButtonProps) {
  const { user } = useAuth();
  const { t } = useI18n();
  const [open, setOpen] = React.useState(false);

  if (!user) return null;

  const minimal = navAppearance === 'minimal';

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          aria-label={t('dashboard.accountMenuAria')}
          className={cn(
            'relative flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl transition-[background,transform] duration-200',
            !minimal &&
              'bg-gradient-to-b from-white/50 to-white/15 shadow-[0_4px_12px_rgba(0,0,0,0.12),inset_0_1px_0_rgba(255,255,255,0.5)] dark:from-white/15 dark:to-zinc-800/50 dark:shadow-[0_4px_14px_rgba(0,0,0,0.4)]',
            minimal && 'bg-transparent shadow-none',
            open &&
              'bg-white/45 shadow-sm backdrop-blur-xl dark:bg-white/[0.12] dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]',
            'hover:bg-white/30 hover:backdrop-blur-md dark:hover:bg-white/[0.08]',
            className
          )}
        >
          <Avatar
            className={cn(
              'h-9 w-9 rounded-[1.05rem]',
              minimal ? 'ring-0' : 'ring-1 ring-white/60 dark:ring-white/10'
            )}
          >
            <AvatarImage src={userAvatarListUrl(user)} alt={user.name} />
            <AvatarFallback className="text-xs font-bold">{user.name.charAt(0)}</AvatarFallback>
          </Avatar>
        </button>
      </PopoverTrigger>
      <PopoverContent side="top" align={popoverAlign} className="w-64 p-2 rounded-2xl border-0 shadow-2xl bg-card">
        <DashboardAccountMenuContent onNavigate={() => setOpen(false)} />
      </PopoverContent>
    </Popover>
  );
}
