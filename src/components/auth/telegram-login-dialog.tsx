"use client";

import * as React from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AUTH_DIALOG_OVERLAY_CLASS,
  AUTH_GLASS_CARD_SHELL_CLASS,
} from "@/components/auth/auth-glass-classes";
import { cn } from "@/lib/utils";
import { useI18n } from "@/hooks/use-i18n";

declare global {
  interface Window {
    onTelegramAuth?: (user: Record<string, unknown>) => void;
  }
}

export type TelegramLoginDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Имя бота без @ (BotFather), из `NEXT_PUBLIC_TELEGRAM_BOT_NAME`. */
  botName: string | undefined;
  onAuthUser: (user: Record<string, unknown>) => void | Promise<void>;
};

/**
 * Диалог с официальным [Telegram Login Widget](https://core.telegram.org/widgets/login).
 * После успеха вызывает `onAuthUser` с объектом полей + `hash` для callable `signInWithTelegram`.
 */
export function TelegramLoginDialog({
  open,
  onOpenChange,
  botName,
  onAuthUser,
}: TelegramLoginDialogProps) {
  const { t } = useI18n();
  const containerRef = React.useRef<HTMLDivElement>(null);
  const onAuthUserRef = React.useRef(onAuthUser);
  onAuthUserRef.current = onAuthUser;

  /**
   * Radix Dialog рендерит контент в portal; на первом кадре после open=true ref часто ещё null,
   * и прежний useEffect выходил раньше вставки скрипта — кнопка Telegram не появлялась.
   */
  React.useLayoutEffect(() => {
    if (!open || !botName?.trim()) {
      delete window.onTelegramAuth;
      containerRef.current?.replaceChildren();
      return;
    }

    let cancelled = false;
    let attempts = 0;
    const maxAttempts = 50;

    const mountWidget = () => {
      if (cancelled) return;
      const container = containerRef.current;
      if (!container) {
        attempts += 1;
        if (attempts < maxAttempts) {
          requestAnimationFrame(mountWidget);
        }
        return;
      }

      container.replaceChildren();
      window.onTelegramAuth = (user: unknown) => {
        if (user && typeof user === "object") {
          void onAuthUserRef.current(user as Record<string, unknown>);
        }
      };

      const s = document.createElement("script");
      s.src = "https://telegram.org/js/telegram-widget.js?22";
      s.async = true;
      s.setAttribute("data-telegram-login", botName.trim());
      s.setAttribute("data-size", "large");
      s.setAttribute("data-onauth", "onTelegramAuth(user)");
      s.setAttribute("data-request-access", "write");
      container.appendChild(s);
    };

    requestAnimationFrame(mountWidget);

    return () => {
      cancelled = true;
      delete window.onTelegramAuth;
      containerRef.current?.replaceChildren();
    };
  }, [open, botName]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        className={cn(
          AUTH_DIALOG_OVERLAY_CLASS,
          "max-w-sm border-white/40 bg-white/90 shadow-2xl backdrop-blur-xl dark:border-white/15 dark:bg-[#0b1220]/92",
          AUTH_GLASS_CARD_SHELL_CLASS,
        )}
      >
        <DialogHeader>
          <DialogTitle>{t('telegramLogin.title')}</DialogTitle>
          <DialogDescription>
            {t('telegramLogin.description')}
          </DialogDescription>
        </DialogHeader>
        {!botName?.trim() ? (
          <p className="text-center text-sm text-destructive">
            {t('telegramLogin.envMissing', { var: 'NEXT_PUBLIC_TELEGRAM_BOT_NAME' })}
          </p>
        ) : (
          <div
            ref={containerRef}
            className="flex min-h-[52px] flex-col items-center justify-center py-2"
          />
        )}
      </DialogContent>
    </Dialog>
  );
}
