import { Suspense } from "react";
import { TelegramBridgeInner } from "./telegram-bridge-inner";

export default function TelegramAuthBridgePage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-dvh items-center justify-center text-sm text-muted-foreground">
          Загрузка…
        </div>
      }
    >
      <TelegramBridgeInner />
    </Suspense>
  );
}
