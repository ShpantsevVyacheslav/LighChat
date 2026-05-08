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
import { useI18n } from '@/hooks/use-i18n';
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
  const { t } = useI18n();
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
      toast({ title: t('chat.encryption.toastEnabled'), description: t('chat.encryption.toastEnabledDesc') });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.warn('[e2ee] enable from profile failed', e);
      toast({
        variant: 'destructive',
        title: t('chat.encryption.toastEnableError'),
        description:
          message.includes('E2EE_NO_DEVICE') || message.includes('E2EE_NO_PUBLIC_KEY') || message.includes('нет ключа')
            ? t('chat.encryption.toastEnableNoKey')
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
        title: t('chat.encryption.toastDisabled'),
        description: t('chat.encryption.toastDisabledDesc'),
      });
    } catch (e) {
      console.warn('[e2ee] disable from profile failed', e);
      toast({ variant: 'destructive', title: t('chat.encryption.toastDisableError') });
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
        {t('chat.encryption.description')}
      </p>
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <Label className="text-base">{t('chat.encryption.label')}</Label>
          <p className="text-xs text-zinc-500">
            {e2eeOn
              ? t('chat.encryption.enabledHint').replace('{epoch}', String(conversation.e2eeKeyEpoch ?? 0))
              : t('chat.encryption.disabledHint')}
          </p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          {busy ? <Loader2 className="h-5 w-5 animate-spin text-zinc-400" aria-hidden /> : null}
          <Switch
            checked={e2eeOn}
            disabled={busy || !firestore}
            onCheckedChange={onSwitchChecked}
            className="data-[state=checked]:bg-emerald-600"
            aria-label={t('chat.encryption.ariaLabel')}
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
              {t('chat.encryption.fingerprintHint')}
            </p>
          </div>
        );
      })() : null}

      <AlertDialog open={disableOpen} onOpenChange={setDisableOpen}>
        <AlertDialogContent className="rounded-2xl border-border sm:rounded-2xl">
          <AlertDialogHeader>
            <AlertDialogTitle>{t('chat.encryption.disableConfirmTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {t('chat.encryption.disableConfirmDesc')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={busy}>{t('chat.encryption.cancelBtn')}</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={(ev) => {
                ev.preventDefault();
                void runDisable();
              }}
            >
              {t('chat.encryption.disableBtn')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <div className="mt-6 border-t border-zinc-800 pt-4">
        <p className="text-sm font-medium text-zinc-200">{t('chat.encryption.dataTypesTitle')}</p>
        <p className="mt-1 text-xs text-zinc-500">
          {t('chat.encryption.dataTypesDesc')}
        </p>

        <div className="mt-3 flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-sm">{t('chat.encryption.overrideLabel')}</Label>
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
              aria-label={t('chat.encryption.overrideAriaLabel')}
            />
          </div>
        </div>

        <div className={`mt-4 space-y-3 rounded-lg border border-zinc-800 bg-zinc-950/30 p-4 ${!hasOverride ? 'opacity-60' : ''}`}>
          {([
            {
              key: 'text' as const,
              titleKey: 'chat.encryption.textLabel',
            },
            {
              key: 'media' as const,
              titleKey: 'chat.encryption.mediaLabel',
            },
          ] as const).map((row) => (
            <div key={row.key} className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <Label className="text-sm">{t(row.titleKey)}</Label>
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
                aria-label={`E2EE: ${t(row.titleKey)}`}
              />
            </div>
          ))}
          {!hasOverride ? (
            <p className="text-xs text-zinc-500">
              {t('chat.encryption.overrideHint')}
            </p>
          ) : null}
        </div>
      </div>
    </div>
  );
}
