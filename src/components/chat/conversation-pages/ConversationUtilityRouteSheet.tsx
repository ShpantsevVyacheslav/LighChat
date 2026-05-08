'use client';

import type { ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { useI18n } from '@/hooks/use-i18n';
import { ArrowLeft } from 'lucide-react';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { WA_CONVERSATION_UTILITY_SHEET_CONTENT_CLASS } from '@/components/chat/profile/ParticipantProfileWhatsAppLayout';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';

/**
 * Правая шторка для утилитных маршрутов чата (`/dashboard/chat/:id/...`).
 * Закрытие возвращает к открытому чату с тем же `conversationId`.
 */
export function ConversationUtilityRouteSheet({
  title,
  conversationId,
  children,
  description,
  /** Обернуть тело в `ScrollArea` + `p-4` (как у медиа/избранного). */
  paddedScroll = true,
}: {
  title: string;
  conversationId: string;
  children: ReactNode;
  description?: string;
  paddedScroll?: boolean;
}) {
  const router = useRouter();
  const { t } = useI18n();
  const handleClose = () => router.push(buildDashboardChatOpenUrl(conversationId));

  return (
    <Sheet open onOpenChange={(next) => { if (!next) handleClose(); }}>
      <SheetContent
        side="right"
        showCloseButton={false}
        className={cn(WA_CONVERSATION_UTILITY_SHEET_CONTENT_CLASS, 'z-[100]')}
        overlayClassName="z-[100]"
      >
        <SheetHeader className="sr-only">
          <SheetTitle>{title}</SheetTitle>
          {description ? <SheetDescription>{description}</SheetDescription> : null}
        </SheetHeader>
        <div className="flex shrink-0 items-center gap-2 border-b border-zinc-800/90 px-2 py-3">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="shrink-0 rounded-full text-zinc-100 hover:bg-zinc-800"
            onClick={handleClose}
            aria-label={t('chat.pages.backToChat')}
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h2 className="min-w-0 flex-1 truncate text-base font-semibold text-zinc-100">{title}</h2>
        </div>
        {paddedScroll ? (
          <ScrollArea className="min-h-0 flex-1">
            <div className="p-4">{children}</div>
          </ScrollArea>
        ) : (
          children
        )}
      </SheetContent>
    </Sheet>
  );
}
