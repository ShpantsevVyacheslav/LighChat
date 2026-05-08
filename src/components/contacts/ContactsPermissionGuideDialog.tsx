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
import { useI18n } from '@/hooks/use-i18n';

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
  const { t } = useI18n();
  const standalone = typeof window !== 'undefined' && isPwaDisplayMode();
  const showAndroidOpenSettings = shouldOfferAndroidSettingsButton();

  const handleOpenAndroidSettings = React.useCallback(() => {
    tryOpenAndroidBrowserApplicationSettings();
  }, []);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-[min(100%,400px)] rounded-2xl border border-border/60 sm:rounded-2xl" showCloseButton>
        <DialogHeader>
          <DialogTitle className="text-lg">{t('contacts.permissionGuide.title')}</DialogTitle>
          <DialogDescription>
            {t('contacts.permissionGuide.description')}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3 text-sm text-muted-foreground">
          {standalone ? (
            <ol className="list-decimal space-y-1.5 pl-4 text-foreground/90">
              <li>{t('contacts.permissionGuide.pwaStep1')}</li>
              <li>{t('contacts.permissionGuide.pwaStep2')}</li>
              <li>{t('contacts.permissionGuide.pwaStep3')}</li>
              <li>{t('contacts.permissionGuide.pwaStep4')}</li>
            </ol>
          ) : (
            <ol className="list-decimal space-y-1.5 pl-4 text-foreground/90">
              <li>{t('contacts.permissionGuide.browserStep1')}</li>
              <li>{t('contacts.permissionGuide.browserStep2')}</li>
              <li>{t('contacts.permissionGuide.browserStep3')}</li>
            </ol>
          )}
          {showAndroidOpenSettings && (
            <p className="rounded-lg bg-muted/60 px-3 py-2 text-foreground/90">
              {t('contacts.permissionGuide.androidHint')}
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
              {t('contacts.permissionGuide.openBrowserSettings')}
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
              {t('contacts.permissionGuide.importNow')}
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
              {t('contacts.permissionGuide.requestAccess')}
            </Button>
          )}
          <Button type="button" variant="outline" className="h-11 w-full rounded-xl" onClick={() => onOpenChange(false)}>
            {t('common.close')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
