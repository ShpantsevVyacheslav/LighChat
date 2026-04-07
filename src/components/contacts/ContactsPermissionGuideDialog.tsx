'use client';

import * as React from 'react';
import { Loader2 } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import {
  shouldOfferAndroidSettingsButton,
  tryOpenAndroidBrowserApplicationSettings,
} from '@/lib/contact-permission-settings';
import { isPwaDisplayMode } from '@/lib/pwa-display-mode';

export type ContactsPermissionGuideDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  hasConsent: boolean;
  onRequestConsent: () => void;
  onImportNow: () => void;
  syncBusy: boolean;
};

/**
 * Объясняет ограничения веб-платформы и ведёт к настройкам (Android intent) или к шагам на iOS.
 */
export function ContactsPermissionGuideDialog({
  open,
  onOpenChange,
  hasConsent,
  onRequestConsent,
  onImportNow,
  syncBusy,
}: ContactsPermissionGuideDialogProps) {
  const standalone = typeof window !== 'undefined' && isPwaDisplayMode();
  const showAndroidOpenSettings = shouldOfferAndroidSettingsButton();

  const handleOpenAndroidSettings = React.useCallback(() => {
    tryOpenAndroidBrowserApplicationSettings();
  }, []);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-[min(100%,400px)] rounded-2xl border border-border/60 sm:rounded-2xl" showCloseButton>
        <DialogHeader>
          <DialogTitle className="text-lg">Доступ к контактам</DialogTitle>
          <DialogDescription>
            В веб-приложении нельзя принудительно открыть экран контактов в «Настройках» на iPhone — это
            ограничение Safari и PWA. Ниже — пошагово, что сделать вручную; на Android можно открыть настройки
            браузера.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3 text-sm text-muted-foreground">
          {standalone ? (
            <ol className="list-decimal space-y-1.5 pl-4 text-foreground/90">
              <li>Откройте приложение «Настройки» на устройстве.</li>
              <li>Прокрутите список приложений и выберите «LighChat» (как у ярлыка на экране «Домой»).</li>
              <li>Нажмите «Контакты» и включите доступ (или «Полный доступ», если доступно).</li>
              <li>Вернитесь в LighChat и снова нажмите синюю кнопку или «Импортировать контакты сейчас».</li>
            </ol>
          ) : (
            <ol className="list-decimal space-y-1.5 pl-4 text-foreground/90">
              <li>Откройте «Настройки» на iPhone.</li>
              <li>
                Если LighChat на экране «Домой», найдите в списке приложений пункт «LighChat». В Safari — при
                открытии только в браузере настройки контактов могут быть у приложения браузера или сайта.
              </li>
              <li>Включите доступ к контактам и вернитесь в LighChat.</li>
            </ol>
          )}
          {showAndroidOpenSettings && (
            <p className="rounded-lg bg-muted/60 px-3 py-2 text-foreground/90">
              На Android кнопка ниже открывает карточку приложения <strong>браузера</strong>. Далее: «Разрешения»
              → «Контакты».
            </p>
          )}
        </div>
        <DialogFooter className="flex-col gap-2 sm:flex-col sm:space-x-0">
          {showAndroidOpenSettings && (
            <Button
              type="button"
              className="h-11 w-full rounded-xl font-semibold"
              variant="default"
              onClick={handleOpenAndroidSettings}
            >
              Открыть настройки браузера
            </Button>
          )}
          {hasConsent ? (
            <Button
              type="button"
              className="h-11 w-full rounded-xl font-semibold"
              variant={showAndroidOpenSettings ? 'secondary' : 'default'}
              disabled={syncBusy}
              onClick={() => {
                onOpenChange(false);
                onImportNow();
              }}
            >
              {syncBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Импортировать контакты сейчас
            </Button>
          ) : (
            <Button
              type="button"
              className="h-11 w-full rounded-xl font-semibold"
              variant={showAndroidOpenSettings ? 'secondary' : 'default'}
              onClick={() => {
                onOpenChange(false);
                onRequestConsent();
              }}
            >
              Запросить доступ к контактам
            </Button>
          )}
          <Button type="button" variant="outline" className="h-11 w-full rounded-xl" onClick={() => onOpenChange(false)}>
            Закрыть
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
