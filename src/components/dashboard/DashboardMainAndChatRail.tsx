'use client';

import * as React from 'react';
import { Suspense, useLayoutEffect, useCallback, useRef, useState } from 'react';
import { Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { DashboardBottomNav } from '@/components/dashboard/DashboardBottomNav';
import { DashboardChatListColumn } from '@/components/dashboard/DashboardChatListColumn';
import { DashboardOpenChatView } from '@/components/dashboard/DashboardOpenChatView';
import { DashboardMainColumnScopeProvider } from '@/contexts/dashboard-main-column-scope';
import { useDashboardConversationUrl } from '@/hooks/use-dashboard-conversation-url';
import { useIsMobile } from '@/hooks/use-mobile';
import { isDashboardChatUtilityPath } from '@/lib/dashboard-conversation-url';

/** Нижняя навигация на мобильном скрыта в открытой переписке (полноэкранный чат). `useSearchParams` → только внутри Suspense. */
function DashboardMobileBottomNavGate() {
  const isMobile = useIsMobile();
  const { effectiveConversationId, pathname } = useDashboardConversationUrl();
  const openChat =
    isMobile &&
    !!effectiveConversationId &&
    pathname === '/dashboard/chat';
  if (openChat) return null;
  return (
    <div className="shrink-0 md:hidden">
      <DashboardBottomNav variant="fullWidth" />
    </div>
  );
}

/** Оболочка как у левой колонки, чтобы не прыгала вёрстка при первом кадре Suspense. */
function DashboardChatListColumnSuspenseFallback() {
  return (
    <div className="flex h-full min-h-[200px] w-full min-w-0 items-center justify-center border-border bg-muted/15 md:min-h-0 md:w-full">
      <Loader2 className="h-7 w-7 animate-spin text-muted-foreground" aria-hidden />
    </div>
  );
}

function DashboardMainColumnSuspenseFallback() {
  return (
    <div className="flex min-h-0 min-w-0 flex-1 items-center justify-center text-muted-foreground">
      <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
    </div>
  );
}

function DashboardChatListBranch() {
  const { effectiveConversationId, setConversationInUrl } = useDashboardConversationUrl();
  return (
    <DashboardChatListColumn
      openConversationId={effectiveConversationId}
      onOpenConversation={setConversationInUrl}
    />
  );
}

function DashboardMainColumnBranch({
  mainColumnRef,
  children,
}: {
  mainColumnRef: React.MutableRefObject<HTMLDivElement | null>;
  children: React.ReactNode;
}) {
  const { effectiveConversationId, setConversationInUrl, pathname } = useDashboardConversationUrl();
  const isMobile = useIsMobile();
  const [messageSearchBlurLeftPx, setMessageSearchBlurLeftPx] = useState(0);

  const showMobileChatList =
    isMobile &&
    pathname === '/dashboard/chat' &&
    !isDashboardChatUtilityPath(pathname) &&
    !effectiveConversationId;

  const syncMessageSearchBlurLeft = useCallback(() => {
    const el = mainColumnRef.current;
    if (!el || typeof window === 'undefined') return;
    setMessageSearchBlurLeftPx(Math.max(0, Math.round(el.getBoundingClientRect().left)));
  }, [mainColumnRef]);

  useLayoutEffect(() => {
    syncMessageSearchBlurLeft();
  }, [syncMessageSearchBlurLeft, effectiveConversationId, pathname]);

  React.useEffect(() => {
    if (typeof window === 'undefined') return;
    window.addEventListener('resize', syncMessageSearchBlurLeft);
    return () => window.removeEventListener('resize', syncMessageSearchBlurLeft);
  }, [syncMessageSearchBlurLeft]);

  return (
    <div
      ref={mainColumnRef}
      className={cn(
        'flex min-h-0 min-w-0 flex-1 flex-col',
        effectiveConversationId
          ? 'overflow-hidden'
          : 'custom-scrollbar overflow-x-hidden overflow-y-auto'
      )}
    >
      {effectiveConversationId ? (
        <DashboardOpenChatView
          conversationId={effectiveConversationId}
          onBack={() => setConversationInUrl(null)}
          onSelectConversation={(id) => setConversationInUrl(id)}
          messageSearchBlurInsetLeftPx={messageSearchBlurLeftPx}
        />
      ) : showMobileChatList ? (
        <DashboardChatListColumn
          openConversationId={effectiveConversationId}
          onOpenConversation={setConversationInUrl}
          omitEmbeddedBottomNav
        />
      ) : (
        <div className="box-border flex h-full min-h-0 min-w-0 flex-1 flex-col px-4 py-2 md:px-6 md:py-6">
          {children}
        </div>
      )}
    </div>
  );
}

export function DashboardMainAndChatRail({ children }: { children: React.ReactNode }) {
  const mainColumnRef = useRef<HTMLDivElement | null>(null);

  return (
    <DashboardMainColumnScopeProvider mainColumnRef={mainColumnRef}>
      <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
        <div className="flex min-h-0 flex-1 flex-col overflow-hidden md:flex-row">
          {/* Список чатов: только md+; на узком экране — полноширинный контент и нижняя панель. */}
          <div className="hidden h-full min-h-0 shrink-0 flex-row border-border md:flex md:max-w-[50vw] md:border-b-0 md:border-r">
            <Suspense fallback={<DashboardChatListColumnSuspenseFallback />}>
              <DashboardChatListBranch />
            </Suspense>
          </div>

          <Suspense fallback={<DashboardMainColumnSuspenseFallback />}>
            <DashboardMainColumnBranch mainColumnRef={mainColumnRef}>{children}</DashboardMainColumnBranch>
          </Suspense>
        </div>
        <Suspense fallback={null}>
          <DashboardMobileBottomNavGate />
        </Suspense>
      </div>
    </DashboardMainColumnScopeProvider>
  );
}
