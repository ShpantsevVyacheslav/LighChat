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

export default function NotificationSettingsPage() {
  const { user, isLoading } = useAuth();
  const { notificationSettings, updateNotificationSettings } = useSettings();
  const { toast } = useToast();

  const clientTimeZone =
    typeof Intl !== "undefined" ? Intl.DateTimeFormat().resolvedOptions().timeZone : undefined;

  const handleUpdate = async (patch: Partial<typeof notificationSettings>) => {
    const withTz =
      clientTimeZone != null && clientTimeZone.length > 0
        ? { ...patch, quietHoursTimeZone: clientTimeZone }
        : patch;
    const ok = await updateNotificationSettings(withTz);
    if (!ok) {
      toast({ variant: "destructive", title: "Ошибка", description: "Не удалось сохранить настройки." });
    }
  };

  const handleReset = async () => {
    const withTz =
      clientTimeZone != null && clientTimeZone.length > 0
        ? { ...DEFAULT_NOTIFICATION_SETTINGS, quietHoursTimeZone: clientTimeZone }
        : DEFAULT_NOTIFICATION_SETTINGS;
    const ok = await updateNotificationSettings(withTz);
    if (ok) {
      toast({ title: "Сброшено", description: "Настройки уведомлений восстановлены по умолчанию." });
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
            <BellRing className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Уведомления
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">Управление звуками и показом уведомлений.</p>
        </div>
      </div>

      {/* Main toggles */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Основные</CardTitle>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Отключить все</Label>
              <p className="text-xs text-muted-foreground">Полностью выключить уведомления.</p>
            </div>
            <Switch
              checked={notificationSettings.muteAll}
              onCheckedChange={(v) => handleUpdate({ muteAll: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Звук</Label>
              <p className="text-xs text-muted-foreground">Воспроизводить звук при новом сообщении.</p>
            </div>
            <Switch
              checked={notificationSettings.soundEnabled}
              onCheckedChange={(v) => handleUpdate({ soundEnabled: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Предпросмотр</Label>
              <p className="text-xs text-muted-foreground">Показывать текст сообщения в уведомлении.</p>
            </div>
            <Switch
              checked={notificationSettings.showPreview}
              onCheckedChange={(v) => handleUpdate({ showPreview: v })}
              disabled={notificationSettings.muteAll}
            />
          </div>
        </CardContent>
      </Card>

      {/* Quiet hours */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Тихие часы</CardTitle>
          <CardDescription>Уведомления не будут беспокоить в указанный период.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Включить тихие часы</Label>
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
                <Label className="text-xs text-muted-foreground mb-1 block">С</Label>
                <Input
                  type="time"
                  value={notificationSettings.quietHoursStart}
                  onChange={(e) => handleUpdate({ quietHoursStart: e.target.value })}
                  className="rounded-xl"
                />
              </div>
              <span className="text-muted-foreground mt-5">—</span>
              <div className="flex-1">
                <Label className="text-xs text-muted-foreground mb-1 block">До</Label>
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
          Сбросить настройки
        </Button>
      </div>
    </div>
  );
}
