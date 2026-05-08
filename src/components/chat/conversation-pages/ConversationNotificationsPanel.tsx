'use client';

import { useI18n } from '@/hooks/use-i18n';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useSettings } from '@/hooks/use-settings';

export function ConversationNotificationsPanel({ conversationId, userId }: { conversationId: string; userId: string }) {
  const { t } = useI18n();
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
        {t('chat.notificationsPanel.settingsNote')}
      </p>
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-base">{t('chat.notificationsPanel.muteLabel')}</Label>
            <p className="text-xs text-zinc-500">{t('chat.notificationsPanel.muteDesc')}</p>
          </div>
          <Switch
            checked={muted}
            onCheckedChange={(v) => updatePrefs({ notificationsMuted: v })}
            className="data-[state=checked]:bg-emerald-600"
          />
        </div>
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <Label className="text-base">{t('chat.notificationsPanel.showPreviewLabel')}</Label>
            <p className="text-xs text-zinc-500">
              {t('chat.notificationsPanel.showPreviewDesc')}
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
