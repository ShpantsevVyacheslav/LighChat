"use client";

import { useSettings, DEFAULT_NOTIFICATION_SETTINGS } from "@/hooks/use-settings";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { BellRing, RotateCcw } from "lucide-react";
import { useI18n } from "@/hooks/use-i18n";
import { RingtonePicker } from "@/components/settings/RingtonePicker";

export default function NotificationSettingsPage() {
  const { user, isLoading } = useAuth();
  const { notificationSettings, updateNotificationSettings } = useSettings();
  const { toast } = useToast();
  const { t } = useI18n();

  const clientTimeZone =
    typeof Intl !== "undefined" ? Intl.DateTimeFormat().resolvedOptions().timeZone : undefined;

  const handleUpdate = async (patch: Partial<typeof notificationSettings>) => {
    const withTz =
      clientTimeZone != null && clientTimeZone.length > 0
        ? { ...patch, quietHoursTimeZone: clientTimeZone }
        : patch;
    const ok = await updateNotificationSettings(withTz);
    if (!ok) {
      toast({ variant: "destructive", title: t('notifications.toastSaveErrorTitle'), description: t('notifications.toastSaveErrorDesc') });
    }
  };

  const handleReset = async () => {
    const withTz =
      clientTimeZone != null && clientTimeZone.length > 0
        ? { ...DEFAULT_NOTIFICATION_SETTINGS, quietHoursTimeZone: clientTimeZone }
        : DEFAULT_NOTIFICATION_SETTINGS;
    const ok = await updateNotificationSettings(withTz);
    if (ok) {
      toast({ title: t('notifications.toastResetTitle'), description: t('notifications.toastResetDesc') });
    }
  };

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
            <BellRing className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> {t('notifications.pageTitle')}
          </h1>
        </div>
      </div>

      {/* Main toggles */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('notifications.mainCardTitle')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.muteAllLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.muteAllHint')}</p>
            </div>
            <Switch
              checked={notificationSettings.muteAll}
              onCheckedChange={(v) => handleUpdate({ muteAll: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.soundLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.soundHint')}</p>
            </div>
            <Switch
              checked={notificationSettings.soundEnabled}
              onCheckedChange={(v) => handleUpdate({ soundEnabled: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.previewLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.previewHint')}</p>
            </div>
            <Switch
              checked={notificationSettings.showPreview}
              onCheckedChange={(v) => handleUpdate({ showPreview: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.messageRingtoneLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.messageRingtoneHint')}</p>
            </div>
            <RingtonePicker
              value={notificationSettings.messageRingtoneId ?? null}
              onChange={(v) => handleUpdate({ messageRingtoneId: v })}
              disabled={notificationSettings.muteAll || !notificationSettings.soundEnabled}
              ariaLabel={t('notifications.messageRingtoneLabel')}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.callRingtoneLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.callRingtoneHint')}</p>
            </div>
            <RingtonePicker
              value={notificationSettings.callRingtoneId ?? null}
              onChange={(v) => handleUpdate({ callRingtoneId: v })}
              disabled={notificationSettings.muteAll || !notificationSettings.soundEnabled}
              ariaLabel={t('notifications.callRingtoneLabel')}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.meetingHandRaiseLabel')}</Label>
              <p className="text-xs text-muted-foreground">{t('notifications.meetingHandRaiseHint')}</p>
            </div>
            <Switch
              checked={notificationSettings.meetingHandRaiseSoundEnabled !== false}
              onCheckedChange={(v) => handleUpdate({ meetingHandRaiseSoundEnabled: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
        </CardContent>
      </Card>

      {/* Quiet hours */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('notifications.quietCardTitle')}</CardTitle>
          <CardDescription>{t('notifications.quietCardDescription')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">{t('notifications.quietEnableLabel')}</Label>
            </div>
            <Switch
              checked={notificationSettings.quietHoursEnabled}
              onCheckedChange={(v) => handleUpdate({ quietHoursEnabled: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
          {notificationSettings.quietHoursEnabled && !notificationSettings.muteAll && (
            <div className="flex items-center gap-3 animate-in fade-in slide-in-from-top-2 duration-300">
              <div className="flex-1">
                <Label className="text-xs text-muted-foreground mb-1 block">{t('notifications.quietFromLabel')}</Label>
                <Input
                  type="time"
                  value={notificationSettings.quietHoursStart}
                  onChange={(e) => handleUpdate({ quietHoursStart: e.target.value })}
                  className="rounded-xl"
                />
              </div>
              <span className="text-muted-foreground mt-5">—</span>
              <div className="flex-1">
                <Label className="text-xs text-muted-foreground mb-1 block">{t('notifications.quietToLabel')}</Label>
                <Input
                  type="time"
                  value={notificationSettings.quietHoursEnd}
                  onChange={(e) => handleUpdate({ quietHoursEnd: e.target.value })}
                  className="rounded-xl"
                />
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Reset */}
      <div className="flex justify-center pt-2">
        <Button variant="ghost" onClick={handleReset} className="rounded-full gap-2 text-sm text-muted-foreground hover:text-foreground">
          <RotateCcw className="h-4 w-4" />
          {t('notifications.resetButton')}
        </Button>
      </div>
    </div>
  );
}
