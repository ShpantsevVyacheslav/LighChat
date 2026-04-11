'use client';

import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useSettings } from '@/hooks/use-settings';

export function ConversationNotificationsPanel({ conversationId, userId }: { conversationId: string; userId: string }) {
  const globalNotify = useSettings().notificationSettings;
  const { prefs, updatePrefs } = useChatConversationPrefs(userId, conversationId);
  const muted = prefs?.notificationsMuted === true;
  const preview =
    prefs?.notificationShowPreview === null || prefs?.notificationShowPreview === undefined
      ? globalNotify.showPreview
      : prefs.notificationShowPreview;

  return (
    <div className="text-zinc-100 [&_label]:text-zinc-100">
      <p className="mb-6 text-sm text-zinc-400">
        Настройки ниже действуют только для этой беседы и не меняют общие уведомления приложения.
      </p>
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-base">Без звука и скрытые оповещения</Label>
            <p className="text-xs text-zinc-500">Не беспокоить по этому чату на этом устройстве.</p>
          </div>
          <Switch
            checked={muted}
            onCheckedChange={(v) => updatePrefs({ notificationsMuted: v })}
            className="data-[state=checked]:bg-emerald-600"
          />
        </div>
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-base">Показывать превью текста</Label>
            <p className="text-xs text-zinc-500">
              Если выключено — заголовок без фрагмента сообщения (где это поддерживается).
            </p>
          </div>
          <Switch
            checked={preview}
            onCheckedChange={(v) => updatePrefs({ notificationShowPreview: v })}
            className="data-[state=checked]:bg-emerald-600"
          />
        </div>
      </div>
    </div>
  );
}
