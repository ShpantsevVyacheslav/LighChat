'use client';

import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationPrivacyPanel({ conversationId, userId }: { conversationId: string; userId: string }) {
  const { t } = useI18n();
  const { prefs, updatePrefs } = useChatConversationPrefs(userId, conversationId);
  const suppress = prefs?.suppressReadReceipts === true;

  return (
    <div className="text-zinc-100 [&_label]:text-zinc-100">
      <p className="mb-6 text-sm text-zinc-400">
        {t('chat.conversationPrivacy.hint')}
      </p>
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <Label className="text-base">{t('chat.conversationPrivacy.suppressReadReceipts')}</Label>
          <p className="text-xs text-zinc-500">
            {t('chat.conversationPrivacy.suppressReadReceiptsDesc')}
          </p>
        </div>
        <Switch
          checked={suppress}
          onCheckedChange={(v) => updatePrefs({ suppressReadReceipts: v })}
          className="data-[state=checked]:bg-emerald-600"
        />
      </div>
    </div>
  );
}
