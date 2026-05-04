'use client';

import * as React from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { Sparkles, ShieldCheck, Timer, Gamepad2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/hooks/use-auth';
import { useI18n } from '@/hooks/use-i18n';
import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';
import { getFeaturesContent } from './features-content';
import { MockHero } from './illustrations/hero';

const STORAGE_KEY = 'lc_features_welcome_v1';
const PWA_ONBOARDING_KEY = 'pwa_onboarding_shown';

function readShown(): boolean {
  try {
    return typeof window !== 'undefined' && window.localStorage.getItem(STORAGE_KEY) === 'true';
  } catch {
    return false;
  }
}

function isPwaOnboardingDone(): boolean {
  try {
    if (typeof window === 'undefined') return false;
    if (window.localStorage.getItem(PWA_ONBOARDING_KEY) !== 'true') return false;
    // Если права уведомлений ещё в `default`, PwaOnboarding покажется снова —
    // не лезем поверх него.
    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

export function FeaturesWelcomeOverlay() {
  const router = useRouter();
  const pathname = usePathname();
  const { user, isAuthenticated, isLoading } = useAuth();
  const { locale } = useI18n();
  const content = React.useMemo(() => getFeaturesContent(locale), [locale]);

  const [visible, setVisible] = React.useState(false);

  const eligible =
    !isLoading &&
    isAuthenticated &&
    !!user &&
    isRegistrationProfileComplete(user) &&
    pathname !== '/dashboard/features' &&
    !pathname?.startsWith('/dashboard/features/');

  React.useEffect(() => {
    if (!eligible) {
      setVisible(false);
      return;
    }
    if (readShown()) {
      setVisible(false);
      return;
    }
    if (!isPwaOnboardingDone()) {
      setVisible(false);
      return;
    }
    // Небольшой запас, чтобы не наезжать на анимацию входа в дашборд.
    const handle = window.setTimeout(() => setVisible(true), 600);
    return () => window.clearTimeout(handle);
  }, [eligible, pathname]);

  const markShown = React.useCallback(() => {
    try {
      window.localStorage.setItem(STORAGE_KEY, 'true');
    } catch {
      /* ignore */
    }
  }, []);

  const handlePrimary = () => {
    markShown();
    setVisible(false);
    router.push('/dashboard/features?source=welcome');
  };

  const handleSecondary = () => {
    markShown();
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="lc-features-welcome-title"
      className="fixed inset-0 z-[290] flex items-center justify-center bg-background/80 p-4 backdrop-blur-md animate-in fade-in duration-500"
    >
      <Card className="relative w-full max-w-md overflow-hidden rounded-[2.5rem] shadow-2xl">
        <div className="pointer-events-none absolute right-3 top-3 opacity-10">
          <Sparkles className="h-20 w-20 text-primary" aria-hidden />
        </div>
        <div className="relative h-44 w-full sm:h-52">
          <div className="absolute inset-0 bg-gradient-to-br from-primary/15 via-violet-400/10 to-transparent" />
          <MockHero className="absolute inset-0 scale-[0.78] origin-center" />
        </div>
        <CardHeader className="text-center pt-2">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10">
            <Sparkles className="h-6 w-6 text-primary" aria-hidden />
          </div>
          <CardTitle id="lc-features-welcome-title" className="text-2xl font-bold">
            {content.welcomeOverlay.title}
          </CardTitle>
          <CardDescription>{content.welcomeOverlay.subtitle}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-2.5 py-2">
          {[
            { icon: ShieldCheck, label: content.welcomeOverlay.bullets[0], color: 'text-emerald-400 bg-emerald-400/10' },
            { icon: Timer, label: content.welcomeOverlay.bullets[1], color: 'text-violet-400 bg-violet-400/10' },
            { icon: Gamepad2, label: content.welcomeOverlay.bullets[2], color: 'text-amber-400 bg-amber-400/10' },
          ].map((b) => {
            const Icon = b.icon;
            return (
              <div key={b.label} className="flex items-center gap-3 rounded-2xl border border-black/5 bg-background/60 px-3 py-2 dark:border-white/10">
                <span className={`flex h-8 w-8 items-center justify-center rounded-xl ${b.color}`}>
                  <Icon className="h-4 w-4" aria-hidden />
                </span>
                <p className="text-sm font-semibold leading-tight">{b.label}</p>
              </div>
            );
          })}
        </CardContent>
        <CardFooter className="flex-col gap-2 px-8 pb-8 pt-2">
          <Button
            type="button"
            variant="default"
            onClick={handlePrimary}
            className="h-12 w-full rounded-2xl text-base font-bold shadow-xl shadow-primary/20"
          >
            {content.welcomeOverlay.primaryCta}
          </Button>
          <Button
            type="button"
            variant="ghost"
            onClick={handleSecondary}
            className="text-muted-foreground hover:bg-transparent"
          >
            {content.welcomeOverlay.secondaryCta}
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
}
