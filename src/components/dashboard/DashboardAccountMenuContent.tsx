'use client';

import * as React from 'react';
import Link from 'next/link';
import { useAuth } from '@/hooks/use-auth';
import {
  UserCircle,
  MessageSquare,
  BellRing,
  Shield,
  ShieldCheck,
  Smartphone,
  LogOut,
  ChevronRight,
  Palette,
} from 'lucide-react';
import type { AppThemePreference, UserRole } from '@/lib/types';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { useSidebar } from '@/components/ui/sidebar';
import { useTheme } from 'next-themes';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';

function normalizeAppTheme(theme: string | undefined, resolved: string | undefined): AppThemePreference {
  const t = theme ?? resolved;
  if (t === 'light' || t === 'dark' || t === 'chat') return t;
  return 'dark';
}

const THEME_CYCLE: AppThemePreference[] = ['light', 'dark', 'chat'];

function ProfileMenuItem({
  icon: Icon,
  label,
  href,
  onClick,
}: {
  icon: React.ElementType;
  label: string;
  href: string;
  onClick: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-foreground hover:bg-foreground/5 transition-colors group"
    >
      <Icon className="h-4 w-4 text-muted-foreground group-hover:text-foreground transition-colors" />
      <span className="flex-1">{label}</span>
      <ChevronRight className="h-3.5 w-3.5 text-muted-foreground/50" />
    </Link>
  );
}

type DashboardAccountMenuContentProps = {
  /** Закрыть поповер и при необходимости мобильный сайдбар */
  onNavigate: () => void;
};

/**
 * Меню профиля и настроек (поповер у аватара в нижней навигации).
 */
export function DashboardAccountMenuContent({ onNavigate }: DashboardAccountMenuContentProps) {
  const { user, logout, updateUser } = useAuth();
  const role = user?.role as UserRole | undefined;
  const { isMobile, setOpenMobile } = useSidebar();
  const { theme, resolvedTheme, setTheme } = useTheme();
  const { toast } = useToast();
  const { t } = useI18n();

  const handleNav = React.useCallback(() => {
    onNavigate();
    if (isMobile) setOpenMobile(false);
  }, [isMobile, onNavigate, setOpenMobile]);

  const currentTheme = normalizeAppTheme(theme, resolvedTheme);

  const setAppTheme = async (next: AppThemePreference) => {
    if (next === currentTheme) return;
    const prev = currentTheme;
    setTheme(next);
    const result = await updateUser({ appTheme: next });
    if (!result.ok) {
      setTheme(prev);
      toast({
        variant: 'destructive',
        title: t('accountMenu.themeSaveErrorTitle'),
        description: result.message,
      });
    }
  };

  const themeChoices: { value: AppThemePreference; label: string }[] = React.useMemo(
    () => [
      { value: 'light' as const, label: t('accountMenu.themeLight') },
      { value: 'dark' as const, label: t('accountMenu.themeDark') },
      /** Режим `chat` в данных: палитра от фона чата — в меню кратко «Авто». */
      { value: 'chat' as const, label: t('accountMenu.themeAuto') },
    ],
    [t]
  );

  const currentThemeLabel =
    themeChoices.find((c) => c.value === currentTheme)?.label ?? t('accountMenu.themeDark');

  const cycleTheme = () => {
    const i = THEME_CYCLE.indexOf(currentTheme);
    const next = THEME_CYCLE[(i >= 0 ? i + 1 : 1) % THEME_CYCLE.length];
    void setAppTheme(next);
  };

  if (!user) return null;

  return (
    <>
      <div className="flex items-center gap-3 px-3 py-2.5 mb-1">
        <Avatar className="h-10 w-10 border border-black/5 dark:border-white/10 shadow-sm">
          <AvatarImage src={userAvatarListUrl(user)} alt={user.name} />
          <AvatarFallback>{(user.name ?? '?').charAt(0)}</AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-bold truncate">{user.name}</p>
          {user.username && <p className="text-[11px] text-muted-foreground truncate">@{user.username}</p>}
        </div>
      </div>
      <div className="h-px bg-border/50 mx-2 my-1" />
      <nav className="flex flex-col gap-0.5">
        <ProfileMenuItem icon={UserCircle} label={t('accountMenu.profile')} href="/dashboard/profile" onClick={handleNav} />
        <ProfileMenuItem
          icon={MessageSquare}
          label={t('accountMenu.chatSettings')}
          href="/dashboard/settings/chats"
          onClick={handleNav}
        />
        {role === 'admin' && (
          <ProfileMenuItem
            icon={ShieldCheck}
            label={t('accountMenu.admin')}
            href="/dashboard/admin"
            onClick={handleNav}
          />
        )}
        <ProfileMenuItem
          icon={BellRing}
          label={t('accountMenu.notifications')}
          href="/dashboard/settings/notifications"
          onClick={handleNav}
        />
        <ProfileMenuItem icon={Shield} label={t('accountMenu.privacy')} href="/dashboard/settings/privacy" onClick={handleNav} />
        <ProfileMenuItem icon={Smartphone} label={t('accountMenu.devices')} href="/dashboard/settings/devices" onClick={handleNav} />
      </nav>
      <div className="h-px bg-border/50 mx-2 my-1" />
      <button
        type="button"
        onClick={cycleTheme}
        className="flex w-full items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-foreground hover:bg-foreground/5 transition-colors text-left group"
        aria-label={t('accountMenu.themeAria', { label: currentThemeLabel })}
      >
        <Palette className="h-4 w-4 text-muted-foreground group-hover:text-foreground transition-colors shrink-0" />
        <span className="flex-1 min-w-0">
          <span className="font-medium">{t('accountMenu.theme')}</span>
          <span className="text-muted-foreground"> · {currentThemeLabel}</span>
        </span>
        <ChevronRight className="h-3.5 w-3.5 text-muted-foreground/50 shrink-0" aria-hidden />
      </button>
      <div className="h-px bg-border/50 mx-2 my-1" />
      <button
        type="button"
        onClick={() => {
          handleNav();
          logout();
        }}
        className="flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm text-destructive hover:bg-destructive/5 transition-colors"
      >
        <LogOut className="h-4 w-4" />
        <span>{t('accountMenu.signOut')}</span>
      </button>
    </>
  );
}
