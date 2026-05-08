'use client';
import { useI18n } from '@/hooks/use-i18n';

import { useEffect, useMemo, useState } from 'react';
import { Loader2, Lock, Shield, Timer, Trash2 } from 'lucide-react';

import type { Conversation } from '@/lib/types';
import { useFirestore } from '@/firebase';
import { deleteSecretChat } from '@/lib/secret-chat/secret-chat-callables';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';

const TTL_LABEL_KEYS: Record<number, string> = {
  300: 'chat.secretChat.ttl5m',
  900: 'chat.secretChat.ttl15m',
  1800: 'chat.secretChat.ttl30m',
  3600: 'chat.secretChat.ttl1h',
  7200: 'chat.secretChat.ttl2h',
  21600: 'chat.secretChat.ttl6h',
  43200: 'chat.secretChat.ttl12h',
  86400: 'chat.secretChat.ttl24h',
};

type SecretChatSettingsDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversation: Conversation;
  onDeleted?: () => void;
};

function parseIso(value?: string | null): Date | null {
  if (!value) return null;
  const dt = new Date(value);
  return Number.isNaN(dt.getTime()) ? null : dt;
}

function formatRemaining(ms: number): string {
  if (ms <= 0) return '00:00:00';
  const totalSec = Math.floor(ms / 1000);
  const hours = Math.floor(totalSec / 3600);
  const minutes = Math.floor((totalSec % 3600) / 60);
  const seconds = totalSec % 60;
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

export function SecretChatSettingsDialog({
  open,
  onOpenChange,
  conversation,
  onDeleted,
}: SecretChatSettingsDialogProps) {
  const { t } = useI18n();
  const firestore = useFirestore();
  const app = firestore.app;
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [busy, setBusy] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const secret = conversation.secretChat;

  useEffect(() => {
    if (!open) return;
    const id = window.setInterval(() => setNowMs(Date.now()), 1000);
    return () => window.clearInterval(id);
  }, [open]);

  const expiresAt = useMemo(() => parseIso(secret?.expiresAt), [secret?.expiresAt]);
  const remaining = expiresAt ? formatRemaining(expiresAt.getTime() - nowMs) : '—';
  const ttlLabel = secret ? (TTL_LABEL_KEYS[secret.ttlPresetSec] ? t(TTL_LABEL_KEYS[secret.ttlPresetSec]) : t('chat.secretChat.ttlSec', { n: secret.ttlPresetSec })) : '—';

  const mediaRows = useMemo(() => {
    const media = secret?.mediaViewPolicy;
    const asText = (value?: number | null) => (value == null ? t('chat.secretChat.unlimited') : t('chat.secretChat.nViews', { n: value }));
    return [
      { label: t('chat.secretChat.images'), value: asText(media?.image) },
      { label: t('chat.secretChat.videos'), value: asText(media?.video) },
      { label: t('chat.secretChat.voice'), value: asText(media?.voice) },
      { label: t('chat.secretChat.files'), value: asText(media?.file) },
      { label: t('chat.locationLabel'), value: asText(media?.location) },
    ];
  }, [secret?.mediaViewPolicy, t]);

  const handleDelete = async () => {
    setBusy(true);
    try {
      await deleteSecretChat(app, conversation.id);
      setConfirmOpen(false);
      onOpenChange(false);
      onDeleted?.();
    } finally {
      setBusy(false);
    }
  };

  if (secret?.enabled !== true) return null;

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{t('chat.secretChat.settingsTitle')}</DialogTitle>
            <DialogDescription>
              {t('chat.secretChat.settingsDescription')}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 text-sm">
            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Timer className="h-4 w-4" /> {t('chat.secretChat.lifetime')}
              </p>
              <p>{t('chat.secretChat.ttlProfile')} {ttlLabel}</p>
              <p>{t('chat.secretChat.remaining')} {remaining}</p>
              <p>{t('chat.secretChat.expires')} {expiresAt ? expiresAt.toLocaleString() : '—'}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Shield className="h-4 w-4" /> {t('chat.secretChat.restrictions')}
              </p>
              <p>{t('chat.secretChat.noForward')} {secret.restrictions.noForward ? t('chat.secretChat.yes') : t('chat.secretChat.no')}</p>
              <p>{t('chat.secretChat.noCopy')} {secret.restrictions.noCopy ? t('chat.secretChat.yes') : t('chat.secretChat.no')}</p>
              <p>{t('chat.secretChat.noSave')} {secret.restrictions.noSave ? t('chat.secretChat.yes') : t('chat.secretChat.no')}</p>
              <p>{t('chat.secretChat.screenshotProtection')} {secret.restrictions.screenshotProtection ? t('chat.secretChat.yes') : t('chat.secretChat.no')}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Lock className="h-4 w-4" /> {t('chat.secretChat.access')}
              </p>
              <p>{t('chat.secretChat.pinRequired')} {secret.lockPolicy.required ? t('chat.secretChat.yes') : t('chat.secretChat.no')}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 font-semibold">{t('chat.secretChat.mediaViewLimitsTitle')}</p>
              <div className="space-y-1">
                {mediaRows.map((row) => (
                  <p key={row.label}>
                    {row.label}: {row.value}
                  </p>
                ))}
              </div>
            </section>

            <Button
              type="button"
              variant="destructive"
              className="w-full"
              onClick={() => setConfirmOpen(true)}
              disabled={busy}
            >
              <Trash2 className="mr-2 h-4 w-4" /> {t('chat.secretChat.deleteButton')}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('chat.secretChat.deleteConfirmTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {t('chat.secretChat.deleteConfirmDescription')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={busy}>{t('common.cancel')}</AlertDialogCancel>
            <AlertDialogAction
              disabled={busy}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={(e) => {
                e.preventDefault();
                void handleDelete();
              }}
            >
              {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {t('chat.secretChat.deleteAction')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
