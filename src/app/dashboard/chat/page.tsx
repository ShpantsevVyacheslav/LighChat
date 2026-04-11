'use client';

import { MessageSquare } from 'lucide-react';
import { ChatWallpaperLayer } from '@/components/chat/ChatWallpaperLayer';
import { useSettings } from '@/hooks/use-settings';

/**
 * Пустой слот чатов (в основном десктоп): на мобильном на `/dashboard/chat` без `conversationId`
 * список диалогов рендерится в `DashboardMainColumnBranch`.
 */
export default function ChatPage() {
  const { chatSettings } = useSettings();

  return (
    <div className="relative -mx-4 -my-2 flex min-h-0 w-full min-w-0 flex-1 flex-col md:-mx-6 md:-my-6">
      <ChatWallpaperLayer wallpaper={chatSettings.chatWallpaper} />
      <div className="relative z-10 flex min-h-0 w-full min-w-0 flex-1 flex-col items-center justify-center p-6">
        <div className="max-w-sm rounded-2xl border border-border/50 bg-card/75 px-6 py-8 text-center text-muted-foreground shadow-sm backdrop-blur-md">
          <MessageSquare className="mx-auto h-12 w-12 opacity-30 text-foreground" />
          <h3 className="mt-4 text-lg font-semibold text-foreground">Выберите чат</h3>
          <p className="mt-1 text-sm">
            Нажмите на диалог в списке чатов, чтобы начать общение.
          </p>
                    </div>
                </div>
    </div>
  );
}
