'use client';

import { useCallback, useState } from 'react';
import { useFirestore } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { enableE2eeOnConversationV2 } from '@/lib/e2ee';
import { disableE2eeOnConversation } from '@/lib/e2ee/disable-conversation-e2ee';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useToast } from '@/hooks/use-toast';
import { Loader2 } from 'lucide-react';
import { useSettings } from '@/hooks/use-settings';
import {
  parseE2eeEncryptedDataTypes,
  resolveEffectiveE2eeEncryptedDataTypes,
} from '@/lib/e2ee/e2ee-data-type-policy';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { E2eeFingerprintBadge } from '@/components/chat/E2eeFingerprintBadge';

type ConversationEncryptionPanelProps = {
  conversation: Conversation;
  currentUserId: string;
};

export function ConversationEncryptionPanel({ conversation, currentUserId }: ConversationEncryptionPanelProps) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const { privacySettings } = useSettings();
  const [busy, setBusy] = useState(false);
  const [disableOpen, setDisableOpen] = useState(false);
  const [typesBusy, setTypesBusy] = useState(false);

  const e2eeOn = !!(conversation.e2eeEnabled && (conversation.e2eeKeyEpoch ?? 0) > 0);
  const globalTypes = parseE2eeEncryptedDataTypes(privacySettings.e2eeEncryptedDataTypes);
  const overrideTypes = conversation.e2eeEncryptedDataTypesOverride
    ? parseE2eeEncryptedDataTypes(conversation.e2eeEncryptedDataTypesOverride)
    : null;
  const effectiveTypes = resolveEffectiveE2eeEncryptedDataTypes({
    global: globalTypes,
    override: overrideTypes,
  });
  const hasOverride = conversation.e2eeEncryptedDataTypesOverride != null;

  const handleEnable = useCallback(async () => {
    if (!firestore) return;
    setBusy(true);
    try {
      await enableE2eeOnConversationV2(firestore, conversation, currentUserId);
      toast({ title: 'Сквозное шифрование включено', description: 'Новые текстовые сообщения будут зашифрованы на устройствах.' });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.warn('[e2ee] enable from profile failed', e);
      toast({
        variant: 'destructive',
        title: 'Не удалось включить шифрование',
        description:
          message.includes('E2EE_NO_DEVICE') || message.includes('E2EE_NO_PUBLIC_KEY') || message.includes('нет ключа')
            ? 'У собеседника должен быть опубликован ключ (нужен хотя бы один вход в приложение).'
            : message.slice(0, 200),
      });
    } finally {
      setBusy(false);
    }
  }, [firestore, conversation, currentUserId, toast]);

  const runDisable = useCallback(async () => {
    if (!firestore) return;
    setDisableOpen(false);
    setBusy(true);
    try {
      await disableE2eeOnConversation(firestore, conversation.id, currentUserId);
      toast({
        title: 'Сквозное шифрование выключено',
        description: 'Новые сообщения не шифруются. Старые зашифрованные по-прежнему читаются в этом чате.',
      });
    } catch (e) {
      console.warn('[e2ee] disable from profile failed', e);
      toast({ variant: 'destructive', title: 'Не удалось выключить шифрование' });
    } finally {
      setBusy(false);
    }
  }, [firestore, conversation.id, toast]);

  const onSwitchChecked = useCallback(
    (next: boolean) => {
      if (busy) return;
      if (next) {
        void handleEnable();
        return;
      }
      setDisableOpen(true);
    },
    [busy, handleEnable]
  );

  return (
    <div className="text-zinc-100 [&_label]:text-zinc-100">
      <p className="mb-6 text-sm text-zinc-400">
        Текст новых сообщений шифруется на ваших устройствах; сервер не хранит расшифрованный текст. Звонки и
        вложения в этой версии протокола обрабатываются отдельно.
      </p>
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <Label className="text-base">Сквозное шифрование</Label>
          <p className="text-xs text-zinc-500">
            {e2eeOn
              ? `Включено (эпоха ключа ${conversation.e2eeKeyEpoch ?? 0}). Выключение не удаляет старые сообщения.`
              : 'Выключено. Включение создаёт новую эпоху ключа для всех участников.'}
          </p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          {busy ? <Loader2 className="h-5 w-5 animate-spin text-zinc-400" aria-hidden /> : null}
          <Switch
            checked={e2eeOn}
            disabled={busy || !firestore}
            onCheckedChange={onSwitchChecked}
            className="data-[state=checked]:bg-emerald-600"
            aria-label="Сквозное шифрование в этом чате"
          />
        </div>
      </div>

      {/* Phase 8: отпечаток E2EE собеседника в DM. Скрыто в группах и
          Saved Messages; для self-chat тоже не имеет смысла. */}
      {e2eeOn && !conversation.isGroup && firestore ? (() => {
        const otherId = (conversation.participantIds ?? []).find(
          (id) => id !== currentUserId
        );
        if (!otherId) return null;
        return (
          <div className="mt-6 border-t border-zinc-800 pt-4">
            <E2eeFingerprintBadge
              firestore={firestore}
              userId={otherId}
            />
            <p className="mt-2 text-xs text-zinc-500">
              Сверьте отпечатки по защищённому каналу, чтобы убедиться, что
              устройства собеседника не подменены. Отпечатки одинаковые у
              обоих участников.
            </p>
          </div>
        );
      })() : null}

      <AlertDialog open={disableOpen} onOpenChange={setDisableOpen}>
        <AlertDialogContent className="rounded-2xl border-border sm:rounded-2xl">
          <AlertDialogHeader>
            <AlertDialogTitle>Выключить сквозное шифрование?</AlertDialogTitle>
            <AlertDialogDescription>
              Новые сообщения перестанут шифроваться. Ранее отправленные зашифрованные сообщения останутся в истории и
              смогут отображаться, если ключи на устройстве совпадают с эпохой сообщения.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={busy}>Отмена</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={(ev) => {
                ev.preventDefault();
                void runDisable();
              }}
            >
              Выключить
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <div className="mt-6 border-t border-zinc-800 pt-4">
        <p className="text-sm font-medium text-zinc-200">Типы данных</p>
        <p className="mt-1 text-xs text-zinc-500">
          Это не меняет протокол — только управляет тем, что отправлять зашифрованным. Для E2EE-off чатов настройка
          не применяется.
        </p>

        <div className="mt-3 flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-sm">Настройки шифрования для этого чата</Label>
          </div>
          <div className="flex items-center gap-2">
            {typesBusy ? <Loader2 className="h-4 w-4 animate-spin text-zinc-400" aria-hidden /> : null}
            <Switch
              checked={hasOverride}
              disabled={!firestore || typesBusy}
              onCheckedChange={async (on) => {
                if (!firestore) return;
                setTypesBusy(true);
                try {
                  await updateDoc(doc(firestore, 'conversations', conversation.id), {
                    e2eeEncryptedDataTypesOverride: on ? { ...effectiveTypes, replyPreview: effectiveTypes.text } : null,
                  });
                } finally {
                  setTypesBusy(false);
                }
              }}
              aria-label="Переопределить типы данных для этого чата"
            />
          </div>
        </div>

        <div className={`mt-4 space-y-3 rounded-lg border border-zinc-800 bg-zinc-950/30 p-4 ${!hasOverride ? 'opacity-60' : ''}`}>
          {([
            {
              key: 'text' as const,
              title: 'Текст сообщений',
            },
            {
              key: 'media' as const,
              title: 'Вложения (медиа/файлы)',
            },
          ] as const).map((row) => (
            <div key={row.key} className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <Label className="text-sm">{row.title}</Label>
              </div>
              <Switch
                checked={effectiveTypes[row.key]}
                disabled={!firestore || typesBusy || !hasOverride}
                onCheckedChange={async (v) => {
                  if (!firestore) return;
                  if (!hasOverride) return;
                  setTypesBusy(true);
                  try {
                    const next = { ...effectiveTypes, [row.key]: v, replyPreview: (row.key === 'text' ? v : effectiveTypes.text) };
                    await updateDoc(doc(firestore, 'conversations', conversation.id), {
                      e2eeEncryptedDataTypesOverride: next,
                    });
                  } finally {
                    setTypesBusy(false);
                  }
                }}
                aria-label={`E2EE: ${row.title}`}
              />
            </div>
          ))}
          {!hasOverride ? (
            <p className="text-xs text-zinc-500">
              Чтобы изменить для конкретного чата, включите «Переопределить».
            </p>
          ) : null}
        </div>
      </div>
    </div>
  );
}
