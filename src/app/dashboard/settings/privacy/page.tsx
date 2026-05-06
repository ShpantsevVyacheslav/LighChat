"use client";

import { useSettings, DEFAULT_PRIVACY_SETTINGS } from "@/hooks/use-settings";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { useI18n } from "@/hooks/use-i18n";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Shield, RotateCcw, Mail, Smartphone, Cake, UserRound, Search, Users } from "lucide-react";

export default function PrivacySettingsPage() {
  const { user, isLoading } = useAuth();
  const { privacySettings, updatePrivacySettings } = useSettings();
  const { toast } = useToast();
  const { t } = useI18n();

  const handleUpdate = async (patch: Partial<typeof privacySettings>) => {
    const ok = await updatePrivacySettings(patch);
    if (!ok) {
      toast({
        variant: "destructive",
        title: t("privacy.toastSaveErrorTitle"),
        description: t("privacy.toastSaveErrorDesc"),
      });
    }
  };

  const handleReset = async () => {
    const ok = await updatePrivacySettings(DEFAULT_PRIVACY_SETTINGS);
    if (ok) {
      toast({
        title: t("privacy.toastResetTitle"),
        description: t("privacy.toastResetDesc"),
      });
    }
  };

  const groupInvitePolicy = privacySettings.groupInvitePolicy ?? "everyone";

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
            <Shield className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> {t("privacy.pageTitle")}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">{t("privacy.pageSubtitle")}</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("privacy.visibilityTitle")}</CardTitle>
          <CardDescription>{t("privacy.visibilitySubtitle")}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.onlineStatusLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.onlineStatusHint")}</p>
            </div>
            <Switch
              checked={privacySettings.showOnlineStatus}
              onCheckedChange={(v) => handleUpdate({ showOnlineStatus: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.lastSeenLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.lastSeenHint")}</p>
            </div>
            <Switch
              checked={privacySettings.showLastSeen}
              onCheckedChange={(v) => handleUpdate({ showLastSeen: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.readReceiptsLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.readReceiptsHint")}</p>
            </div>
            <Switch
              checked={privacySettings.showReadReceipts}
              onCheckedChange={(v) => handleUpdate({ showReadReceipts: v })}
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Users className="h-4 w-4 text-muted-foreground" />
            {t("privacy.groupInvitesTitle")}
          </CardTitle>
          <CardDescription>{t("privacy.groupInvitesSubtitle")}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.groupInviteEveryoneLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.groupInviteEveryoneHint")}</p>
            </div>
            <Switch
              checked={groupInvitePolicy === "everyone"}
              onCheckedChange={(on) => {
                if (on) void handleUpdate({ groupInvitePolicy: "everyone" });
              }}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.groupInviteContactsLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.groupInviteContactsHint")}</p>
            </div>
            <Switch
              checked={groupInvitePolicy === "contacts"}
              onCheckedChange={(on) => {
                if (on) void handleUpdate({ groupInvitePolicy: "contacts" });
              }}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t("privacy.groupInviteNoneLabel")}</Label>
              <p className="text-xs text-muted-foreground">{t("privacy.groupInviteNoneHint")}</p>
            </div>
            <Switch
              checked={groupInvitePolicy === "none"}
              onCheckedChange={(on) => {
                if (on) void handleUpdate({ groupInvitePolicy: "none" });
              }}
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("privacy.searchPeersTitle")}</CardTitle>
          <CardDescription>{t("privacy.searchPeersSubtitle")}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Search className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">{t("privacy.globalSearchLabel")}</Label>
                <p className="text-xs text-muted-foreground">{t("privacy.globalSearchHint")}</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showInGlobalUserSearch !== false}
              onCheckedChange={(v) => handleUpdate({ showInGlobalUserSearch: v })}
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("privacy.profileOthersTitle")}</CardTitle>
          <CardDescription>{t("privacy.profileOthersSubtitle")}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Mail className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">{t("privacy.showEmailLabel")}</Label>
                <p className="text-xs text-muted-foreground">{t("privacy.showEmailHint")}</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showEmailToOthers !== false}
              onCheckedChange={(v) => handleUpdate({ showEmailToOthers: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Smartphone className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">{t("privacy.showPhoneLabel")}</Label>
                <p className="text-xs text-muted-foreground">{t("privacy.showPhoneHint")}</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showPhoneToOthers !== false}
              onCheckedChange={(v) => handleUpdate({ showPhoneToOthers: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Cake className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">{t("privacy.showDobLabel")}</Label>
                <p className="text-xs text-muted-foreground">{t("privacy.showDobHint")}</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showDateOfBirthToOthers !== false}
              onCheckedChange={(v) => handleUpdate({ showDateOfBirthToOthers: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <UserRound className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">{t("privacy.showBioLabel")}</Label>
                <p className="text-xs text-muted-foreground">{t("privacy.showBioHint")}</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showBioToOthers !== false}
              onCheckedChange={(v) => handleUpdate({ showBioToOthers: v })}
            />
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-center pt-2">
        <Button
          variant="ghost"
          onClick={handleReset}
          className="rounded-full gap-2 text-sm text-muted-foreground hover:text-foreground"
        >
          <RotateCcw className="h-4 w-4" />
          {t("privacy.resetDefaultsButton")}
        </Button>
      </div>
    </div>
  );
}
