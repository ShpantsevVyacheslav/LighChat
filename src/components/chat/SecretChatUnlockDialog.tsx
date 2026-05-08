'use client';

import { useEffect, useMemo, useState } from 'react';
import { Loader2, ShieldAlert } from 'lucide-react';

import { useI18n } from '@/hooks/use-i18n';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { useFirestore } from '@/firebase';
import {
  isSecretPinLockedError,
  isSecretPinNotSetError,
  setSecretChatPin,
  unlockSecretChat,
} from '@/lib/secret-chat/secret-chat-callables';

type SecretChatUnlockDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversationId: string;
  onUnlocked?: () => void;
};

function savedPinKey(conversationId: string): string {
  return `lighchat.secretChat.pin.v1.${conversationId}`;
}

function readSavedPin(conversationId: string): string | null {
  if (typeof window === 'undefined') return null;
  const v = window.localStorage.getItem(savedPinKey(conversationId));
  const pin = (v ?? '').trim();
  return /^\d{4}$/.test(pin) ? pin : null;
}

function writeSavedPin(conversationId: string, pin: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(savedPinKey(conversationId), pin);
}

function clearSavedPin(conversationId: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(savedPinKey(conversationId));
}

export function SecretChatUnlockDialog({
  open,
  onOpenChange,
  conversationId,
  onUnlocked,
}: SecretChatUnlockDialogProps) {
  const firestore = useFirestore();
  const { t } = useI18n();
  const app = firestore.app;
  const [pin, setPin] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pinNotSet, setPinNotSet] = useState(false);
  const [rememberOnDevice, setRememberOnDevice] = useState(true);

  const savedPin = useMemo(() => readSavedPin(conversationId), [conversationId]);

  useEffect(() => {
    if (!open) {
      setBusy(false);
      setError(null);
      setPinNotSet(false);
      setPin('');
      setRememberOnDevice(true);
    }
  }, [open]);

  const validatePin = (value: string): boolean => /^\d{4}$/.test(value.trim());

  const runUnlock = async (pinValue: string, mode: 'unlock' | 'set-and-unlock') => {
    setBusy(true);
    setError(null);
    try {
      if (mode === 'set-and-unlock') {
        await setSecretChatPin(app, pinValue);
      }
      await unlockSecretChat(app, {
        conversationId,
        pin: pinValue,
        method: 'pin',
      });
      if (rememberOnDevice) writeSavedPin(conversationId, pinValue);
      else clearSavedPin(conversationId);
      onUnlocked?.();
      onOpenChange(false);
    } catch (e) {
      if (isSecretPinNotSetError(e)) {
        setPinNotSet(true);
        setError(t('chat.secretChat.pinNotSetError'));
      } else if (isSecretPinLockedError(e)) {
        setError(t('chat.secretChat.tooManyAttempts'));
      } else {
        setError(t('chat.secretChat.unlockFailed'));
      }
    } finally {
      setBusy(false);
    }
  };

  const handleSubmit = async () => {
    const nextPin = pin.trim();
    if (!validatePin(nextPin)) {
      setError(t('chat.secretChat.enter4DigitPin'));
      return;
    }
    await runUnlock(nextPin, pinNotSet ? 'set-and-unlock' : 'unlock');
  };

  const handleUseSavedPin = async () => {
    if (!savedPin) return;
    await runUnlock(savedPin, 'unlock');
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{t('chat.secretChat.unlockTitle')}</DialogTitle>
          <DialogDescription>
            {t('chat.secretChat.unlockDescription')}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="secret-chat-pin">{t('chat.secretChat.unlockPinLabel')}</Label>
            <Input
              id="secret-chat-pin"
              type="password"
              inputMode="numeric"
              maxLength={4}
              value={pin}
              onChange={(e) => setPin(e.target.value.replace(/\D+/g, '').slice(0, 4))}
              placeholder="••••"
              disabled={busy}
            />
          </div>

          <div className="flex items-center gap-2">
            <Checkbox
              id="remember-secret-pin"
              checked={rememberOnDevice}
              onCheckedChange={(checked) => setRememberOnDevice(checked === true)}
              disabled={busy}
            />
            <Label htmlFor="remember-secret-pin" className="text-sm text-muted-foreground">
              {t('chat.secretChat.rememberPinOnDevice')}
            </Label>
          </div>

          {error ? (
            <div className="flex items-start gap-2 rounded-md border border-destructive/25 bg-destructive/10 p-2 text-sm text-destructive">
              <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          ) : null}
        </div>

        <DialogFooter className="gap-2 sm:justify-between">
          <div className="flex items-center gap-2">
            {savedPin ? (
              <Button
                type="button"
                variant="outline"
                onClick={() => void handleUseSavedPin()}
                disabled={busy}
              >
                {t('chat.secretChat.useSavedPinButton')}
              </Button>
            ) : null}
          </div>
          <div className="flex items-center gap-2">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={busy}>
              {t('common.cancel')}
            </Button>
            <Button type="button" onClick={() => void handleSubmit()} disabled={busy}>
              {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {pinNotSet ? t('chat.secretChat.setPinAndUnlock') : t('chat.secretChat.unlockButton')}
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
