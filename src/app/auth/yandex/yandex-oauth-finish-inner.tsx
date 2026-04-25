"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { signInWithCustomToken } from "firebase/auth";

import { useFirebaseApp, useAuth } from "@/firebase";

export function YandexOauthFinishInner() {
  const app = useFirebaseApp();
  const auth = useAuth();
  const router = useRouter();
  const [message, setMessage] = React.useState("Завершаем вход через Яндекс…");

  React.useEffect(() => {
    if (!app || !auth) {
      setMessage("Firebase не инициализирован. Обновите страницу.");
      return;
    }

    const run = async () => {
      const hash =
        typeof window !== "undefined" && window.location.hash.startsWith("#")
          ? window.location.hash.slice(1)
          : "";
      const params = new URLSearchParams(hash);
      const token = params.get("customToken");
      if (!token || token.trim().length === 0) {
        setMessage("Нет токена входа. Откройте вход с главной страницы ещё раз.");
        return;
      }

      try {
        window.history.replaceState(null, "", "/auth/yandex");
        await signInWithCustomToken(auth, token);
        router.replace("/dashboard");
      } catch (e: unknown) {
        console.error("[yandex-oauth-finish]", e);
        const msg =
          typeof e === "object" && e !== null && "message" in e
            ? String((e as { message: unknown }).message)
            : "Не удалось войти через Яндекс.";
        setMessage(msg);
      }
    };

    void run();
  }, [app, auth, router]);

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col items-center justify-center gap-3 p-6 text-center text-sm text-muted-foreground">
      <p>{message}</p>
    </div>
  );
}
