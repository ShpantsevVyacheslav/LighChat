"use client";

import { useCallback } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  buildPathWithConversation,
  getEffectiveDashboardConversationId,
} from "@/lib/dashboard-conversation-url";

/**
 * Чтение/запись `?conversationId=` на дашборде.
 * Вызывать только внутри границы `<Suspense>` (из‑за `useSearchParams` в Next.js App Router).
 */
export function useDashboardConversationUrl() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  const effectiveConversationId = getEffectiveDashboardConversationId(pathname, searchParams);

  const setConversationInUrl = useCallback(
    (id: string | null) => {
      const next = buildPathWithConversation(pathname, searchParams.toString(), id);
      router.replace(next, { scroll: false });
    },
    [pathname, router, searchParams],
  );

  return {
    effectiveConversationId,
    setConversationInUrl,
    pathname,
  };
}
