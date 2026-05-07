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

const TTL_LABELS: Record<number, string> = {
  300: '5 мин',
  900: '15 мин',
  1800: '30 мин',
  3600: '1 час',
  7200: '2 часа',
  21600: '6 часов',
  43200: '12 часов',
  86400: '24 часа',
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
  const ttlLabel = secret ? TTL_LABELS[secret.ttlPresetSec] ?? `${secret.ttlPresetSec} сек` : '—';

  const mediaRows = useMemo(() => {
    const media = secret?.mediaViewPolicy;
    const asText = (value?: number | null) => (value == null ? 'Безлимит' : `${value} просмотров`);
    return [
      { label: 'Изображения', value: asText(media?.image) },
      { label: 'Видео', value: asText(media?.video) },
      { label: 'Голосовые', value: asText(media?.voice) },
      { label: 'Файлы', value: asText(media?.file) },
      { label: t('chat.locationLabel'), value: asText(media?.location) },
    ];
  }, [secret?.mediaViewPolicy]);

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
            <DialogTitle>Настройки секретного чата</DialogTitle>
            <DialogDescription>
              После создания эти параметры доступны только для просмотра.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 text-sm">
            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Timer className="h-4 w-4" /> Срок жизни
              </p>
              <p>Профиль TTL: {ttlLabel}</p>
              <p>Осталось: {remaining}</p>
              <p>Истекает: {expiresAt ? expiresAt.toLocaleString() : '—'}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Shield className="h-4 w-4" /> Ограничения
              </p>
              <p>Запрет пересылки: {secret.restrictions.noForward ? 'Да' : 'Нет'}</p>
              <p>Запрет копирования: {secret.restrictions.noCopy ? 'Да' : 'Нет'}</p>
              <p>Запрет сохранения: {secret.restrictions.noSave ? 'Да' : 'Нет'}</p>
              <p>Защита скриншотов: {secret.restrictions.screenshotProtection ? 'Да' : 'Нет'}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 flex items-center gap-2 font-semibold">
                <Lock className="h-4 w-4" /> Доступ
              </p>
              <p>Требуется PIN при входе: {secret.lockPolicy.required ? 'Да' : 'Нет'}</p>
            </section>

            <section className="rounded-lg border p-3">
              <p className="mb-2 font-semibold">Лимиты просмотров медиа</p>
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
              <Trash2 className="mr-2 h-4 w-4" /> Удалить секретный чат
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Удалить секретный чат?</AlertDialogTitle>
            <AlertDialogDescription>
              Чат будет удалён для обоих участников вместе с вложениями. Это действие нельзя отменить.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={busy}>Отмена</AlertDialogCancel>
            <AlertDialogAction
              disabled={busy}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={(e) => {
                e.preventDefault();
                void handleDelete();
              }}
            >
              {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Удалить
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
