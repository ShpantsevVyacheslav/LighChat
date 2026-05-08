'use client';
import { useI18n } from '@/hooks/use-i18n';

import { useState } from 'react';
import { Loader2, LockKeyhole } from 'lucide-react';

import type { User } from '@/lib/types';
import { useFirestore } from '@/firebase';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { createOrOpenSecretDirectChat } from '@/lib/secret-chat/secret-chat-create';
import { setSecretChatPin } from '@/lib/secret-chat/secret-chat-callables';
import type { SecretChatRestrictions, SecretChatTtlPresetSec } from '@/lib/types';

const TTL_PRESETS: Array<{ value: SecretChatTtlPresetSec; labelKey: string }> = [
  { value: 300, labelKey: 'chat.secretChat.ttl5m' },
  { value: 900, labelKey: 'chat.secretChat.ttl15m' },
  { value: 1800, labelKey: 'chat.secretChat.ttl30m' },
  { value: 3600, labelKey: 'chat.secretChat.ttl1h' },
  { value: 7200, labelKey: 'chat.secretChat.ttl2h' },
  { value: 21600, labelKey: 'chat.secretChat.ttl6h' },
  { value: 43200, labelKey: 'chat.secretChat.ttl12h' },
  { value: 86400, labelKey: 'chat.secretChat.ttl24h' },
];

const VIEW_LIMIT_OPTIONS: Array<{ value: string; labelKey: string }> = [
  { value: '', labelKey: 'chat.secretChat.viewUnlimited' },
  { value: '1', labelKey: 'chat.secretChat.view1' },
  { value: '2', labelKey: 'chat.secretChat.view2' },
  { value: '3', labelKey: 'chat.secretChat.view3' },
  { value: '5', labelKey: 'chat.secretChat.view5' },
  { value: '10', labelKey: 'chat.secretChat.view10' },
];

const SECRET_VAULT_PIN_KEY = 'lighchat.secretVault.pin.v1';

type SecretChatComposeDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  currentUser: User;
  peerUser: User;
  onCreated: (conversationId: string) => void;
};

function parseLimit(value: string): number | null {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : null;
}

export function SecretChatComposeDialog({
  open,
  onOpenChange,
  currentUser,
  peerUser,
  onCreated,
}: SecretChatComposeDialogProps) {
  const { t } = useI18n();
  const firestore = useFirestore();
  const [ttl, setTtl] = useState<SecretChatTtlPresetSec>(3600);
  const [noForward, setNoForward] = useState(true);
  const [noCopy, setNoCopy] = useState(true);
  const [noSave, setNoSave] = useState(true);
  const [screenshotProtection, setScreenshotProtection] = useState(true);
  const [lockRequired, setLockRequired] = useState(false);
  const [vaultPin, setVaultPin] = useState('');
  const [imageViews, setImageViews] = useState('');
  const [videoViews, setVideoViews] = useState('');
  const [voiceViews, setVoiceViews] = useState('');
  const [fileViews, setFileViews] = useState('');
  const [locationViews, setLocationViews] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const resetState = () => {
    setTtl(3600);
    setNoForward(true);
    setNoCopy(true);
    setNoSave(true);
    setScreenshotProtection(true);
    setLockRequired(false);
    setVaultPin('');
    setImageViews('');
    setVideoViews('');
    setVoiceViews('');
    setFileViews('');
    setLocationViews('');
    setBusy(false);
    setError(null);
  };

  const handleOpenChange = (next: boolean) => {
    onOpenChange(next);
    if (!next) resetState();
  };

  const handleCreate = async () => {
    const pin = vaultPin.trim();
    if (pin && !/^\d{4}$/.test(pin)) {
      setError(t('chat.secretChat.pinMustBe4Digits'));
      return;
    }

    setBusy(true);
    setError(null);

    const restrictions: SecretChatRestrictions = {
      noForward,
      noCopy,
      noSave,
      screenshotProtection,
    };

    try {
      const conversationId = await createOrOpenSecretDirectChat(firestore, currentUser, peerUser, {
        ttlPresetSec: ttl,
        restrictions,
        lockRequired,
        mediaViewPolicy: {
          image: parseLimit(imageViews),
          video: parseLimit(videoViews),
          voice: parseLimit(voiceViews),
          file: parseLimit(fileViews),
          location: parseLimit(locationViews),
        },
      });

      if (pin) {
        await setSecretChatPin(firestore.app, pin);
        if (typeof window !== 'undefined') {
          window.localStorage.setItem(SECRET_VAULT_PIN_KEY, pin);
        }
      }

      onCreated(conversationId);
      handleOpenChange(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : t('chat.secretChat.createFailed'));
    } finally {
      setBusy(false);
    }
  };

  const mediaLimitSelect = (
    label: string,
    value: string,
    setValue: (next: string) => void
  ) => (
    <div className="space-y-1">
      <Label className="text-xs text-muted-foreground">{label}</Label>
      <select
        value={value}
        onChange={(e) => setValue(e.target.value)}
        disabled={busy}
        className="h-9 w-full rounded-md border bg-background px-2 text-sm"
      >
        {VIEW_LIMIT_OPTIONS.map((opt) => (
          <option key={opt.value || 'none'} value={opt.value}>
            {t(opt.labelKey)}
          </option>
        ))}
      </select>
    </div>
  );

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{t('chat.secretChat.createTitle', { name: peerUser.name || t('chat.secretChat.userFallback') })}</DialogTitle>
          <DialogDescription>
            {t('chat.secretChat.composeDescription')}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-4 rounded-lg border p-3">
            <div className="space-y-2">
              <Label>{t('chat.secretChat.chatLifetime')}</Label>
              <select
                value={String(ttl)}
                onChange={(e) => setTtl(Number(e.target.value) as SecretChatTtlPresetSec)}
                disabled={busy}
                className="h-9 w-full rounded-md border bg-background px-2 text-sm"
              >
                {TTL_PRESETS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {t(opt.labelKey)}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-3">
              <Label className="text-sm">{t('chat.secretChat.restrictions')}</Label>
              <SwitchRow label={t('chat.secretChat.noForwardToggle')} checked={noForward} onCheckedChange={setNoForward} disabled={busy} />
              <SwitchRow label={t('chat.secretChat.noCopyToggle')} checked={noCopy} onCheckedChange={setNoCopy} disabled={busy} />
              <SwitchRow label={t('chat.secretChat.noSaveToggle')} checked={noSave} onCheckedChange={setNoSave} disabled={busy} />
              <SwitchRow
                label={t('chat.secretChat.screenshotProtectionToggle')}
                checked={screenshotProtection}
                onCheckedChange={setScreenshotProtection}
                disabled={busy}
              />
            </div>
          </div>

          <div className="space-y-4 rounded-lg border p-3">
            <div className="space-y-3">
              <Label className="text-sm">{t('chat.secretChat.mediaViewLimits')}</Label>
              {mediaLimitSelect(t('chat.secretChat.images'), imageViews, setImageViews)}
              {mediaLimitSelect(t('chat.secretChat.videos'), videoViews, setVideoViews)}
              {mediaLimitSelect(t('chat.secretChat.voice'), voiceViews, setVoiceViews)}
              {mediaLimitSelect(t('chat.secretChat.files'), fileViews, setFileViews)}
              {mediaLimitSelect(t('chat.locationLabel'), locationViews, setLocationViews)}
            </div>

            <div className="space-y-3 rounded-md border p-3">
              <SwitchRow
                label={t('chat.secretChat.requirePinToggle')}
                checked={lockRequired}
                onCheckedChange={setLockRequired}
                disabled={busy}
              />
              {lockRequired ? (
                <div className="space-y-2">
                  <Label htmlFor="secret-compose-vault-pin" className="text-xs text-muted-foreground">
                    {t('chat.secretChat.vaultPinLabel')}
                  </Label>
                  <Input
                    id="secret-compose-vault-pin"
                    type="password"
                    inputMode="numeric"
                    maxLength={4}
                    value={vaultPin}
                    onChange={(e) => setVaultPin(e.target.value.replace(/\D+/g, '').slice(0, 4))}
                    placeholder="••••"
                    disabled={busy}
                  />
                  <p className="text-xs text-muted-foreground">
                    {t('chat.secretChat.vaultPinHint')}
                  </p>
                </div>
              ) : null}
            </div>
          </div>
        </div>

        {error ? <p className="text-sm text-destructive">{error}</p> : null}

        <DialogFooter className="gap-2">
          <Button type="button" variant="ghost" disabled={busy} onClick={() => handleOpenChange(false)}>
            {t('common.cancel')}
          </Button>
          <Button type="button" disabled={busy} onClick={() => void handleCreate()}>
            {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <LockKeyhole className="mr-2 h-4 w-4" />}
            {t('chat.secretChat.createButton')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function SwitchRow({
  label,
  checked,
  onCheckedChange,
  disabled,
}: {
  label: string;
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <Label className="text-sm">{label}</Label>
      <Switch checked={checked} onCheckedChange={onCheckedChange} disabled={disabled} />
    </div>
  );
}
