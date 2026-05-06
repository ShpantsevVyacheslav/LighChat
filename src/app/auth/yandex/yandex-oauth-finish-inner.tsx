"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { signInWithCustomToken } from "firebase/auth";

import { useFirebaseApp, useAuth } from "@/firebase";
import { useI18n } from "@/hooks/use-i18n";

export function YandexOauthFinishInner() {
  const app = useFirebaseApp();
  const auth = useAuth();
  const router = useRouter();
  const { t } = useI18n();
  const [message, setMessage] = React.useState(t('yandexFinish.inProgress'));

  React.useEffect(() => {
    if (!app || !auth) {
      setMessage(t('yandexFinish.firebaseUninitialized'));
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
        setMessage(t('yandexFinish.missingToken'));
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
            : t('yandexFinish.fallbackError');
        setMessage(msg);
      }
    };

    void run();
  }, [app, auth, router, t]);

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col items-center justify-center gap-3 p-6 text-center text-sm text-muted-foreground">
      <p>{message}</p>
    </div>
  );
}
