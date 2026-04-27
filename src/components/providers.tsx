
"use client";

import { AuthProvider } from "@/hooks/use-auth";
import { TooltipProvider } from "@/components/ui/tooltip";
import { OfflineProvider } from "@/components/offline-provider";
import { AppThemeController } from "@/components/AppThemeController";
import { I18nProvider } from "@/components/i18n-provider";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <OfflineProvider>
      <I18nProvider>
        <AuthProvider>
          <AppThemeController />
          <TooltipProvider>{children}</TooltipProvider>
        </AuthProvider>
      </I18nProvider>
    </OfflineProvider>
  );
}
