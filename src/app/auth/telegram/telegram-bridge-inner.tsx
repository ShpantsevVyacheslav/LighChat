"use client";

import * as React from "react";
import { useSearchParams } from "next/navigation";
import { getFunctions, httpsCallable } from "firebase/functions";
import { useFirebaseApp } from "@/firebase";

declare global {
  interface Window {
    onTelegramAuth?: (user: Record<string, unknown>) => void;
    /** Flutter `webview_flutter`: `JavaScriptChannel` с именем `TelegramAuth`. */
    TelegramAuth?: { postMessage: (message: string) => void };
  }
}

const BOT_NAME =
  typeof process.env.NEXT_PUBLIC_TELEGRAM_BOT_NAME === "string"
    ? process.env.NEXT_PUBLIC_TELEGRAM_BOT_NAME.trim()
    : "";

/**
 * Мост для мобильного WebView: `?mobile=1` — виджет Telegram → callable `signInWithTelegram` →
 * `TelegramAuth.postMessage(customToken)` в Flutter (без `signInWithCustomToken` внутри WebView).
 */
export function TelegramBridgeInner() {
  const app = useFirebaseApp();
  const searchParams = useSearchParams();
  const mobile = searchParams.get("mobile") === "1";
  const containerRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    if (!mobile || !BOT_NAME) return;
    const container = containerRef.current;
    if (!container) return;

    container.innerHTML = "";
    window.onTelegramAuth = async (user: unknown) => {
      if (!user || typeof user !== "object") return;
      try {
        const functions = getFunctions(app, "us-central1");
        const fn = httpsCallable<
          { auth: Record<string, unknown> },
          { customToken: string }
        >(functions, "signInWithTelegram");
        const res = await fn({ auth: user as Record<string, unknown> });
        const token = res.data?.customToken;
        if (token && typeof token === "string" && window.TelegramAuth) {
          window.TelegramAuth.postMessage(token);
        }
      } catch (e) {
        console.error("[telegram-bridge] signInWithTelegram failed", e);
      }
    };

    const s = document.createElement("script");
    s.src = "https://telegram.org/js/telegram-widget.js?22";
    s.async = true;
    s.setAttribute("data-telegram-login", BOT_NAME);
    s.setAttribute("data-size", "large");
    s.setAttribute("data-onauth", "onTelegramAuth(user)");
    s.setAttribute("data-request-access", "write");
    container.appendChild(s);

    return () => {
      delete window.onTelegramAuth;
      container.innerHTML = "";
    };
  }, [app, mobile]);

  if (!mobile) {
    return (
      <div className="mx-auto max-w-md p-6 text-center text-sm text-muted-foreground">
        Эта страница для входа из мобильного приложения. Откройте её с параметром{" "}
        <code className="rounded bg-muted px-1 py-0.5 text-xs">?mobile=1</code>.
      </div>
    );
  }

  if (!BOT_NAME) {
    return (
      <div className="mx-auto max-w-md p-6 text-center text-sm text-destructive">
        Не задан <code className="rounded bg-muted px-1">NEXT_PUBLIC_TELEGRAM_BOT_NAME</code>.
      </div>
    );
  }

  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-4 bg-background p-4">
      <p className="text-sm text-muted-foreground">Войдите через Telegram</p>
      <div ref={containerRef} className="min-h-[56px]" />
    </div>
  );
}
