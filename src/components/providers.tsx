
"use client";

import { AuthProvider } from "@/hooks/use-auth";
import { TooltipProvider } from "@/components/ui/tooltip";
import { OfflineProvider } from "@/components/offline-provider";
import { AppThemeController } from "@/components/AppThemeController";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <OfflineProvider>
      <AuthProvider>
        <AppThemeController />
        <TooltipProvider>{children}</TooltipProvider>
      </AuthProvider>
    </OfflineProvider>
  );
}
