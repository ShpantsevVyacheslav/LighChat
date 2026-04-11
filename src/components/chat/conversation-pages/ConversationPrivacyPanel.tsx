'use client';

import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';

export function ConversationPrivacyPanel({ conversationId, userId }: { conversationId: string; userId: string }) {
  const { prefs, updatePrefs } = useChatConversationPrefs(userId, conversationId);
  const suppress = prefs?.suppressReadReceipts === true;

  return (
    <div className="text-zinc-100 [&_label]:text-zinc-100">
      <p className="mb-6 text-sm text-zinc-400">
        Параметры ниже действуют только в этой переписке и не заменяют глобальные настройки профиля.
      </p>
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <Label className="text-base">Не отправлять отметки «прочитано»</Label>
          <p className="text-xs text-zinc-500">
            Собеседник не увидит двойные галочки для новых входящих сообщений, которые вы просматриваете в этом чате.
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
