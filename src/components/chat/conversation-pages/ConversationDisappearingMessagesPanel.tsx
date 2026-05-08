'use client';

import { useCallback, useState } from 'react';
import { useFirestore } from '@/firebase';
import { doc } from 'firebase/firestore';
import { updateDocumentNonBlocking } from '@/firebase/non-blocking-updates';
import type { Conversation } from '@/lib/types';
import {
  DISAPPEARING_MESSAGE_TTL_PRESETS,
  formatDisappearingTtlSummary,
} from '@/lib/disappearing-messages-presets';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import { cn } from '@/lib/utils';

type ConversationDisappearingMessagesPanelProps = {
  conversation: Conversation;
  currentUserId: string;
  /** В группе — только админ/создатель может менять таймер. */
  canEdit: boolean;
};

export function ConversationDisappearingMessagesPanel({
  conversation,
  currentUserId,
  canEdit,
}: ConversationDisappearingMessagesPanelProps) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  const [saving, setSaving] = useState(false);

  const current =
    conversation.disappearingMessageTtlSec != null &&
    conversation.disappearingMessageTtlSec > 0 &&
    Number.isFinite(conversation.disappearingMessageTtlSec)
      ? conversation.disappearingMessageTtlSec
      : null;

  const handleSelect = useCallback(
    (ttlSec: number | null) => {
      if (!firestore || !canEdit || saving) return;
      setSaving(true);
      const now = new Date().toISOString();
      const ref = doc(firestore, 'conversations', conversation.id);
      updateDocumentNonBlocking(ref, {
        disappearingMessageTtlSec: ttlSec,
        disappearingMessagesUpdatedAt: now,
        disappearingMessagesUpdatedBy: currentUserId,
      });
      toast({
        title: ttlSec == null ? t('chat.disappearing.toastDisabledTitle') : t('chat.disappearing.toastTimerUpdatedTitle'),
        description:
          ttlSec == null
            ? t('chat.disappearing.toastDisabledDesc')
            : t('chat.disappearing.toastTimerUpdatedDesc').replace('{ttl}', formatDisappearingTtlSummary(ttlSec)),
      });
      queueMicrotask(() => setSaving(false));
    },
    [firestore, canEdit, saving, conversation.id, currentUserId, toast],
  );

  return (
    <div className="text-zinc-100">
      <p className="mb-4 text-sm text-zinc-400">
        {t('chat.disappearing.description')}
      </p>
      {!canEdit ? (
        <p className="rounded-lg border border-zinc-700 bg-zinc-900/40 px-3 py-2 text-sm text-zinc-400">
          {t('chat.disappearing.adminOnly')}{' '}
          <span className="font-medium text-zinc-200">{formatDisappearingTtlSummary(current)}</span>.
        </p>
      ) : (
        <ul className="space-y-1">
          {DISAPPEARING_MESSAGE_TTL_PRESETS.map((p) => {
            const active = p.ttlSec === current;
            return (
              <li key={p.label}>
                <button
                  type="button"
                  disabled={saving}
                  onClick={() => handleSelect(p.ttlSec)}
                  className={cn(
                    'flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-left text-sm transition-colors',
                    active
                      ? 'bg-emerald-600/25 text-emerald-100 ring-1 ring-emerald-500/50'
                      : 'bg-zinc-900/50 text-zinc-200 hover:bg-zinc-800/80',
                  )}
                >
                  <span>{p.ttlSec == null ? t('chat.disappearing.off') : p.label}</span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
