import { Suspense } from "react";

import { YandexOauthFinishInner } from "./yandex-oauth-finish-inner";

export default function YandexOauthFinishPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-dvh items-center justify-center text-sm text-muted-foreground">
          Загрузка…
        </div>
      }
    >
      <YandexOauthFinishInner />
    </Suspense>
  );
}
