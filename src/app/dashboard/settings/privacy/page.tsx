"use client";

import { useSettings, DEFAULT_PRIVACY_SETTINGS } from "@/hooks/use-settings";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Shield, RotateCcw, Mail, Smartphone, Cake, UserRound, Search, Users, Lock } from "lucide-react";
import { DevicesPanel } from "@/components/settings/DevicesPanel";
import { E2eeRecoveryPanel } from "@/components/settings/E2eeRecoveryPanel";
import { DEFAULT_E2EE_ENCRYPTED_DATA_TYPES } from "@/lib/e2ee/e2ee-data-type-policy";
export default function PrivacySettingsPage() {
  const { user, isLoading } = useAuth();
  const { privacySettings, updatePrivacySettings } = useSettings();
  const { toast } = useToast();

  const handleUpdate = async (patch: Partial<typeof privacySettings>) => {
    const ok = await updatePrivacySettings(patch);
    if (!ok) {
      toast({ variant: "destructive", title: "Ошибка", description: "Не удалось сохранить настройки." });
    }
  };

  const handleReset = async () => {
    const ok = await updatePrivacySettings(DEFAULT_PRIVACY_SETTINGS);
    if (ok) {
      toast({ title: "Сброшено", description: "Настройки конфиденциальности восстановлены по умолчанию." });
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
            <Shield className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Конфиденциальность
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Видимость в чатах и то, что другие видят в вашем профиле.
          </p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Lock className="h-4 w-4 text-muted-foreground" />
            Сквозное шифрование
          </CardTitle>
          <CardDescription>
            Новые личные чаты: при создании приложение попробует включить E2E, если у вас и у собеседника опубликованы
            ключи (нужен хотя бы один вход на устройстве). Администраторы и сервер не читают зашифрованные сообщения.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Пытаться включать E2E в новых личных чатах</Label>
              <p className="text-xs text-muted-foreground">
                Работает вместе с платформенной настройкой (если её включил админ). Если ключей нет — чат останется
                обычным.
              </p>
            </div>
            <Switch
              checked={privacySettings.e2eeForNewDirectChats === true}
              onCheckedChange={(v) => handleUpdate({ e2eeForNewDirectChats: v })}
            />
          </div>
          <div className="border-t pt-5 space-y-4">
            {(() => {
              const cur = privacySettings.e2eeEncryptedDataTypes ?? DEFAULT_E2EE_ENCRYPTED_DATA_TYPES;
              const effective = { ...cur, replyPreview: cur.text };
              return (
                <>
            <div>
              <Label className="text-sm font-medium">Что шифруем в E2EE чатах</Label>
              <p className="text-xs text-muted-foreground">
                Это не меняет протокол шифрования — только решает, какие типы данных отправлять в зашифрованном виде.
              </p>
            </div>
            <div className="flex items-center justify-between gap-4">
              <div>
                <Label className="text-sm font-medium">Текст сообщений</Label>
              </div>
              <Switch
                checked={effective.text}
                onCheckedChange={(v) =>
                  handleUpdate({
                    e2eeEncryptedDataTypes: {
                      ...effective,
                      text: v,
                      replyPreview: v,
                    },
                  })
                }
              />
            </div>
            <div className="flex items-center justify-between gap-4">
              <div>
                <Label className="text-sm font-medium">Вложения (медиа/файлы)</Label>
              </div>
              <Switch
                checked={effective.media}
                onCheckedChange={(v) =>
                  handleUpdate({
                    e2eeEncryptedDataTypes: {
                      ...effective,
                      media: v,
                    },
                  })
                }
              />
            </div>
                </>
              );
            })()}
          </div>
        </CardContent>
      </Card>

      <DevicesPanel />
      <E2eeRecoveryPanel />

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Видимость</CardTitle>
          <CardDescription>Кто может видеть вашу активность.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Статус онлайн</Label>
              <p className="text-xs text-muted-foreground">Другие пользователи видят, что вы в сети.</p>
            </div>
            <Switch
              checked={privacySettings.showOnlineStatus}
              onCheckedChange={(v) => handleUpdate({ showOnlineStatus: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Последний визит</Label>
              <p className="text-xs text-muted-foreground">Показывать время последнего посещения.</p>
            </div>
            <Switch
              checked={privacySettings.showLastSeen}
              onCheckedChange={(v) => handleUpdate({ showLastSeen: v })}
            />
          </div>
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Индикатор прочтения</Label>
              <p className="text-xs text-muted-foreground">Показывать отправителям, что вы прочитали сообщение.</p>
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
            Приглашения в группы
          </CardTitle>
          <CardDescription>
            Кто может добавлять вас в групповой чат. Администраторы приложения не ограничены этим правилом.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Все пользователи</Label>
              <p className="text-xs text-muted-foreground">
                Любой участник может включить вас в новую группу или добавить в существующую.
              </p>
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
              <Label className="text-sm font-medium">Только контакты</Label>
              <p className="text-xs text-muted-foreground">
                В группу вас сможет добавить только тот, кого вы сами сохранили в «Контактах».
              </p>
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
              <Label className="text-sm font-medium">Никто</Label>
              <p className="text-xs text-muted-foreground">
                Обычные пользователи не смогут добавить вас в группу.
              </p>
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
          <CardTitle className="text-base">Поиск собеседников</CardTitle>
          <CardDescription>Кто может найти вас по имени среди всех пользователей приложения.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Search className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">Глобальный поиск</Label>
                <p className="text-xs text-muted-foreground">
                  Если выключено, вы не отображаетесь в списке «Все пользователи» при создании чата. В блоке «Контакты»
                  вы по-прежнему видны тем, кто добавил вас в контакты.
                </p>
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
          <CardTitle className="text-base">Профиль для других</CardTitle>
          <CardDescription>Что показывать в карточке контакта и в профиле из беседы.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-start gap-3 min-w-0">
              <Mail className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" />
              <div>
                <Label className="text-sm font-medium">Email</Label>
                <p className="text-xs text-muted-foreground">Адрес почты в профиле собеседника.</p>
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
                <Label className="text-sm font-medium">Номер телефона</Label>
                <p className="text-xs text-muted-foreground">В профиле и в списке контактов у других.</p>
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
                <Label className="text-sm font-medium">Дата рождения</Label>
                <p className="text-xs text-muted-foreground">Поле «День рождения» в профиле.</p>
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
                <Label className="text-sm font-medium">О себе</Label>
                <p className="text-xs text-muted-foreground">Текст биографии в профиле.</p>
              </div>
            </div>
            <Switch
              checked={privacySettings.showBioToOthers !== false}
              onCheckedChange={(v) => handleUpdate({ showBioToOthers: v })}
            />
          </div>
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
