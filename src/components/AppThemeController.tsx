'use client';

import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';
import { useAuth } from '@/hooks/use-auth';
import { useSettings } from '@/hooks/use-settings';
import type { AppThemePreference } from '@/lib/types';
import {
  CHAT_THEME_CSS_VAR_NAMES,
  buildChatThemeStyleProps,
  defaultChatThemeWhenNoWallpaper,
  isLightChatBackdropFromRgbs,
  resolveWallpaperAccentRgbs,
} from '@/lib/chat-app-theme';

function isPersistedTheme(v: unknown): v is AppThemePreference {
  return v === 'light' || v === 'dark' || v === 'chat';
}

/**
 * Синхронизирует next-themes с `user.appTheme` и выставляет CSS-переменные для режима «chat».
 */
export function AppThemeController() {
  const { theme, resolvedTheme, setTheme } = useTheme();
  const { user, isLoading } = useAuth();
  const { chatSettings } = useSettings();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted || isLoading) return;
    if (!user) return;
    const pref = user.appTheme;
    if (isPersistedTheme(pref)) {
      setTheme(pref);
    }
  }, [mounted, isLoading, user?.appTheme, user?.id, setTheme]);

  /** Режим «Авто» (`chat`): палитра только из глобального фона (`users.chatSettings.chatWallpaper`). */
  const globalWallpaperForTheme = chatSettings.chatWallpaper ?? null;

  useEffect(() => {
    const el = document.documentElement;
    const active = theme === 'chat' || resolvedTheme === 'chat';

    if (!active) {
      CHAT_THEME_CSS_VAR_NAMES.forEach((k) => el.style.removeProperty(k));
      return;
    }

    let cancelled = false;
    void (async () => {
      const rgbs = await resolveWallpaperAccentRgbs(globalWallpaperForTheme);
      if (cancelled) return;
      const props =
        rgbs.length > 0 ? buildChatThemeStyleProps(rgbs) : defaultChatThemeWhenNoWallpaper();
      Object.entries(props).forEach(([k, v]) => el.style.setProperty(k, v));
    })();

    return () => {
      cancelled = true;
    };
  }, [theme, resolvedTheme, globalWallpaperForTheme]);

  /** Tailwind `dark:` зависит от класса `.dark` на `html`; next-themes в режиме `chat` выставляет только `chat`. */
  useEffect(() => {
    const el = document.documentElement;
    const isChat = theme === 'chat' || resolvedTheme === 'chat';
    if (!isChat) return;

    let cancelled = false;
    void (async () => {
      const rgbs = await resolveWallpaperAccentRgbs(globalWallpaperForTheme);
      if (cancelled) return;
      const light = isLightChatBackdropFromRgbs(rgbs);
      if (light) el.classList.remove('dark');
      else el.classList.add('dark');
    })();

    return () => {
      cancelled = true;
    };
  }, [theme, resolvedTheme, globalWallpaperForTheme]);

  return null;
}
