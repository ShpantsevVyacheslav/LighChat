'use client';

import * as React from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { SidebarProvider } from '@/components/ui/sidebar';
import AppHeader from '@/components/app-header';
import { Icons } from '@/components/icons';
import { AudioCallOverlay } from '@/components/chat/AudioCallOverlay';
import { useBadge } from '@/hooks/use-badge';
import { cn } from '@/lib/utils';
import { PwaOnboarding } from '@/components/pwa-onboarding';
import { FeaturesWelcomeOverlay } from '@/components/features/features-welcome-overlay';
import { LiveLocationProvider } from '@/components/location/LiveLocationProvider';
import { LiveLocationStopBanner } from '@/components/location/LiveLocationStopBanner';
import { useIsMobile } from '@/hooks/use-mobile';
import { MobileChatOpenProvider } from '@/contexts/mobile-chat-open-context';
import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';
import { DashboardMainAndChatRail } from '@/components/dashboard/DashboardMainAndChatRail';
import { useVisualViewportCssVars } from '@/hooks/use-visual-viewport-css-vars';

function AuthenticatedLayoutBody({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const isMobile = useIsMobile();
  const isChatPage =
    pathname === '/dashboard/chat' || pathname.startsWith('/dashboard/chat/');
  /** Колонка переписки / пустой слот чата: фон под статус-бар (см. `ChatWindow`). */
  const relaxMainTopSafeArea = isMobile && isChatPage;

  return (
    <>
      <div className="relative z-10 flex h-full w-full min-w-0 flex-col">
        <main
          className={cn(
            'relative flex min-h-0 flex-1 flex-col overflow-hidden bg-transparent min-w-0',
            !relaxMainTopSafeArea && 'pt-[env(safe-area-inset-top)]'
          )}
        >
          <AppHeader />
          <DashboardMainAndChatRail>{children}</DashboardMainAndChatRail>
        </main>
      </div>
      <div
        className={cn(
          'pointer-events-none fixed inset-x-0 z-[190] flex justify-center px-3',
          'bottom-[calc(1rem+env(safe-area-inset-bottom))]'
        )}
      >
        <LiveLocationStopBanner className="pointer-events-auto w-full max-w-md" />
      </div>
    </>
  );
}

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isGuest, isLoading, user } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [callsOverlayEnabled, setCallsOverlayEnabled] = React.useState(false);
  const isChatPage =
    pathname === '/dashboard/chat' || pathname.startsWith('/dashboard/chat/');
  const isMobile = useIsMobile();
  /** Видимая высота экрана при клавиатуре (iOS); шапка/колонка не тянут 100dvh под клавиатуру. */
  useVisualViewportCssVars(Boolean(isMobile && isChatPage));

  useBadge(user?.id, true);

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

  /**
   * Гость видеоконференции (Firebase Anonymous Auth) не должен попадать в дашборд
   * и тем более редактировать `/dashboard/profile`. После выхода из митинга
   * `MeetingRoom` шлёт на `/dashboard/meetings` — здесь мы перехватываем и
   * выкидываем на главную, чтобы guest не оказался в анкете «дозаполнения профиля».
   */
  React.useEffect(() => {
    if (!isLoading && isGuest) {
      router.replace('/');
    }
  }, [isLoading, isGuest, router]);

  React.useEffect(() => {
    if (
      !isLoading &&
      isAuthenticated &&
      user &&
      !isRegistrationProfileComplete(user)
    ) {
      // Allow incomplete users to reach profile completion UI.
      if (pathname !== '/dashboard/profile') {
        router.replace('/dashboard/profile');
      }
    }
  }, [isLoading, isAuthenticated, user, router, pathname]);

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

  if (isLoading || !isAuthenticated || !user || isGuest) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-background">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!isRegistrationProfileComplete(user) && pathname !== '/dashboard/profile') {
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
          <div
            className={cn(
              'relative flex w-full min-h-0 overflow-hidden bg-background',
              isMobile && isChatPage ? 'h-[var(--lc-visual-vh,100dvh)]' : 'h-[100dvh]'
            )}
          >
            <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden">
              <div className="absolute left-[-5%] top-[-5%] h-[40%] w-[40%] rounded-full bg-primary/5 blur-[60px] dark:bg-primary/10" />
              <div className="absolute bottom-[-5%] right-[-5%] h-[40%] w-[40%] rounded-full bg-accent/5 blur-[60px] dark:bg-accent/10" />
            </div>

            <AuthenticatedLayoutBody>{children}</AuthenticatedLayoutBody>
          </div>
          {callsOverlayEnabled ? <AudioCallOverlay currentUser={user} /> : null}
          <PwaOnboarding />
          <FeaturesWelcomeOverlay />
        </SidebarProvider>
      </LiveLocationProvider>
    </MobileChatOpenProvider>
  );
}
