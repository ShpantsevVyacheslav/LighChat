'use client';

import * as React from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { SidebarProvider } from '@/components/ui/sidebar';
import AppHeader from '@/components/app-header';
import { DashboardBottomNav } from '@/components/dashboard/DashboardBottomNav';
import { Icons } from '@/components/icons';
import { AudioCallOverlay } from '@/components/chat/AudioCallOverlay';
import { useBadge } from '@/hooks/use-badge';
import { cn } from '@/lib/utils';
import { PwaOnboarding } from '@/components/pwa-onboarding';
import { LiveLocationProvider } from '@/components/location/LiveLocationProvider';
import { LiveLocationStopBanner } from '@/components/location/LiveLocationStopBanner';
import { useIsMobile } from '@/hooks/use-mobile';
import {
  MobileChatOpenProvider,
  useMobileChatOpenOptional,
} from '@/contexts/mobile-chat-open-context';
import type { User } from '@/lib/types';

function AuthenticatedLayoutBody({
  children,
  user,
}: {
  children: React.ReactNode;
  user: User;
}) {
  const pathname = usePathname();
  const isMobile = useIsMobile();
  const isChatPage =
    pathname === '/dashboard/chat' || pathname.startsWith('/dashboard/chat/');
  /** Только корень чатов: колонка переписки сама рисует фон под статус-бар (см. `ChatWindow`). */
  const isMainChatShell = pathname === '/dashboard/chat';
  const relaxMainTopSafeArea = isMobile && isMainChatShell;
  const mobileChatCtx = useMobileChatOpenOptional();
  const hideNavForOpenMobileChat =
    isMainChatShell && isMobile && (mobileChatCtx?.mobileConversationOpen ?? false);
  const showGlobalBottomNav =
    (!isMainChatShell || isMobile) && !hideNavForOpenMobileChat;

  return (
    <>
      <div className="relative z-10 flex h-full w-full min-w-0 flex-col">
        <main
          className={cn(
            'relative flex min-h-0 flex-1 flex-col overflow-hidden bg-transparent min-w-0',
            !relaxMainTopSafeArea && 'pt-[env(safe-area-inset-top)]',
            showGlobalBottomNav && 'pb-[calc(3.5rem+env(safe-area-inset-bottom))]'
          )}
        >
          <AppHeader />
          {isChatPage ? (
            <div className="min-h-0 flex-1 overflow-y-hidden bg-transparent">{children}</div>
          ) : (
            <div className="min-h-0 flex-1 overflow-y-auto bg-transparent px-4 py-2 custom-scrollbar min-w-0 md:px-6 md:py-6">
              {children}
            </div>
          )}
        </main>
        {showGlobalBottomNav && (
          <div className="fixed bottom-0 left-0 right-0 z-[200]">
            <DashboardBottomNav variant="fullWidth" />
          </div>
        )}
      </div>
      <div
        className={cn(
          'pointer-events-none fixed inset-x-0 z-[190] flex justify-center px-3',
          showGlobalBottomNav
            ? 'bottom-[calc(4.75rem+env(safe-area-inset-bottom))]'
            : 'bottom-[calc(1rem+env(safe-area-inset-bottom))]'
        )}
      >
        <LiveLocationStopBanner className="pointer-events-auto w-full max-w-md" />
      </div>
    </>
  );
}

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, user } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [callsOverlayEnabled, setCallsOverlayEnabled] = React.useState(false);
  const isChatPage =
    pathname === '/dashboard/chat' || pathname.startsWith('/dashboard/chat/');
  const shouldTrackUnreadBadge = isChatPage;

  useBadge(user?.id, shouldTrackUnreadBadge);

  React.useEffect(() => {
    if (!isLoading && isAuthenticated && pathname === '/dashboard') {
      router.push('/dashboard/chat');
    }
  }, [isLoading, isAuthenticated, pathname, router]);

  React.useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isLoading, isAuthenticated, router]);

  React.useEffect(() => {
    let disposed = false;
    const timer = window.setTimeout(() => {
      if (!disposed) setCallsOverlayEnabled(true);
    }, 1200);

    return () => {
      disposed = true;
      window.clearTimeout(timer);
    };
  }, []);

  if (isLoading || !isAuthenticated || !user) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-background">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <MobileChatOpenProvider>
      <LiveLocationProvider>
        <SidebarProvider defaultOpen={!isChatPage}>
          <div className="relative flex h-[100dvh] w-full overflow-hidden bg-background">
            <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden">
              <div className="absolute left-[-5%] top-[-5%] h-[40%] w-[40%] rounded-full bg-primary/5 blur-[60px] dark:bg-primary/10" />
              <div className="absolute bottom-[-5%] right-[-5%] h-[40%] w-[40%] rounded-full bg-accent/5 blur-[60px] dark:bg-accent/10" />
            </div>

            <AuthenticatedLayoutBody user={user}>{children}</AuthenticatedLayoutBody>
          </div>
          {callsOverlayEnabled ? <AudioCallOverlay currentUser={user} /> : null}
          <PwaOnboarding />
        </SidebarProvider>
      </LiveLocationProvider>
    </MobileChatOpenProvider>
  );
}
