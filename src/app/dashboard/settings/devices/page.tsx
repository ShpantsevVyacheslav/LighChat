"use client";

import { Smartphone } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { useI18n } from "@/hooks/use-i18n";
import { Skeleton } from "@/components/ui/skeleton";
import { DevicesPanel } from "@/components/settings/DevicesPanel";
import { E2eeRecoveryPanel } from "@/components/settings/E2eeRecoveryPanel";

export default function DevicesSettingsPage() {
  const { user, isLoading } = useAuth();
  const { t } = useI18n();

  if (isLoading || !user) {
    return (
      <div className="space-y-4 max-w-3xl mx-auto">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-3xl mx-auto pb-10">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <Smartphone className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> {t("devices.pageTitle")}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">{t("devices.pageSubtitle")}</p>
        </div>
      </div>

      <DevicesPanel />
      <E2eeRecoveryPanel />
    </div>
  );
}
