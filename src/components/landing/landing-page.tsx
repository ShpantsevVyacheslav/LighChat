'use client';

import * as React from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowRight,
  CheckCircle2,
  ListChecks,
  Lightbulb,
  ShieldCheck,
  Sparkles,
} from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useI18n } from '@/hooks/use-i18n';
import { cn } from '@/lib/utils';
import { PublicLanguageMenu } from '@/components/i18n/public-language-menu';
import {
  AuthBrandWordmarkBlock,
  AuthBrandWordmarkTitle,
} from '@/components/auth/auth-brand-wordmark';
import {
  ACCENT_CLASSES,
  FEATURE_TOPICS,
} from '@/components/features/features-data';
import { FeatureMockFrame } from '@/components/features/feature-mock-frame';
import { MockHero } from '@/components/features/illustrations/hero';
import { getFeaturesContent } from '@/components/features/features-content';
import { StoreBadge } from './store-badges';
import { getLandingContent } from './landing-content';
import { CookieBanner } from './cookie-banner';
import { LegalFooterLinks } from './legal-footer-links';

const BRAND_LOGO_SRC = '/brand/lighchat-mark.png';
const BRAND_LOGO_SIZE = 575;

export function LandingPage() {
  const { locale } = useI18n();
  const features = React.useMemo(() => getFeaturesContent(locale), [locale]);
  const landing = React.useMemo(() => getLandingContent(locale), [locale]);

  const flagships = FEATURE_TOPICS.filter((t) => t.highlight);
  const others = FEATURE_TOPICS.filter((t) => !t.highlight);

  return (
    <div className="relative h-dvh w-full overflow-x-hidden overflow-y-auto bg-background text-foreground select-text">
      {/* Декоративный фон — мягкие радиальные пятна и сетка. */}
      <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 bg-slate-50 dark:bg-[#070b14]" />
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 -z-10 bg-gradient-to-br from-sky-100/70 via-indigo-50/50 to-violet-100/70 dark:from-[#0f172a] dark:via-[#1e1b4b] dark:to-[#0c4a6e]"
      />
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 -z-10 bg-[radial-gradient(ellipse_80%_55%_at_50%_-20%,hsl(var(--primary)/0.30),transparent_55%)]"
      />

      <LandingHeader loginCta={landing.loginCta} registerCta={landing.registerCta} />

      <main className="mx-auto w-full max-w-6xl px-4 pb-20 pt-8 sm:px-6 lg:px-8">
        {/* HERO */}
        <section className="grid gap-10 lg:grid-cols-[1.1fr_1fr] lg:items-center">
          <div className="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-700">
            <div className="inline-flex items-center gap-1.5 rounded-full border border-primary/30 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
              <Sparkles className="h-3.5 w-3.5" aria-hidden />
              {landing.heroBadge}
            </div>

            <div className="flex items-center gap-4">
              <Image
                src={BRAND_LOGO_SRC}
                alt="LighChat"
                width={BRAND_LOGO_SIZE}
                height={BRAND_LOGO_SIZE}
                className="h-16 w-16 shrink-0 object-contain drop-shadow-[0_6px_20px_rgba(0,0,0,0.12)] dark:drop-shadow-[0_8px_28px_rgba(0,0,0,0.35)] sm:h-20 sm:w-20"
                priority
              />
              <AuthBrandWordmarkBlock className="text-left">
                <AuthBrandWordmarkTitle size="hero" className="text-3xl sm:text-4xl" />
              </AuthBrandWordmarkBlock>
            </div>

            <h1 className="font-headline text-4xl font-bold leading-tight tracking-tight sm:text-5xl lg:text-6xl">
              {landing.heroTitle}
            </h1>
            <p className="max-w-xl text-base text-muted-foreground sm:text-lg">
              {landing.heroSubtitle}
            </p>

            <div className="flex flex-wrap items-center gap-3">
              <Button asChild variant="default" size="lg" className="shadow-md shadow-primary/25">
                <Link href="/auth">{landing.loginCta}</Link>
              </Button>
              <Button asChild variant="outline" size="lg">
                <Link href="/auth">
                  {landing.registerCta}
                  <ArrowRight className="ml-1 h-4 w-4" aria-hidden />
                </Link>
              </Button>
            </div>

            <div className="space-y-3 pt-1">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                {landing.storesEyebrow}
              </p>
              <div className="flex flex-wrap items-center gap-3">
                <StoreBadge
                  variant="apple"
                  ariaLabel="App Store"
                  line1={landing.appStoreLine1}
                  line2={landing.appStoreLine2}
                />
                <StoreBadge
                  variant="google"
                  ariaLabel="Google Play"
                  line1={landing.googlePlayLine1}
                  line2={landing.googlePlayLine2}
                />
              </div>
              <p className="text-xs text-muted-foreground">{landing.storesNote}</p>
            </div>
          </div>

          <div className="relative h-[280px] sm:h-[360px] lg:h-[440px]">
            <MockHero />
          </div>
        </section>

        {/* HIGHLIGHTS */}
        <section className="mt-20 space-y-5">
          <header>
            <h2 className="font-headline text-2xl font-bold sm:text-3xl">
              {landing.highlightsTitle}
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">{landing.highlightsSubtitle}</p>
          </header>
          <div className="grid gap-4 sm:grid-cols-2">
            {flagships.map((topic, i) => {
              const tContent = features.topics[topic.id];
              const accent = ACCENT_CLASSES[topic.accent];
              return (
                <Card
                  key={topic.id}
                  className="relative h-full overflow-hidden animate-in fade-in slide-in-from-bottom-3 duration-700"
                  style={{ animationDelay: `${i * 60}ms` }}
                >
                  <div
                    className={cn(
                      'pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r',
                      accent.gradient
                    )}
                  />
                  <FeatureMockFrame
                    ratio="aspect-[16/10]"
                    className="rounded-none border-0 shadow-none"
                  >
                    <topic.Mock />
                  </FeatureMockFrame>
                  <div className="flex items-start gap-3 p-5">
                    <div
                      className={cn(
                        'flex h-9 w-9 shrink-0 items-center justify-center rounded-2xl',
                        accent.tint
                      )}
                    >
                      <topic.icon className={cn('h-4 w-4', accent.text)} aria-hidden />
                    </div>
                    <div className="min-w-0 flex-1">
                      <h3 className="font-headline text-lg font-bold leading-tight">
                        {tContent.title}
                      </h3>
                      <p className="mt-1 text-sm text-muted-foreground">{tContent.tagline}</p>
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>
        </section>

        {/* MORE */}
        <section className="mt-16 space-y-5">
          <header>
            <h2 className="font-headline text-2xl font-bold sm:text-3xl">{landing.moreTitle}</h2>
            <p className="mt-1 text-sm text-muted-foreground">{landing.moreSubtitle}</p>
          </header>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {others.map((topic, i) => {
              const tContent = features.topics[topic.id];
              const accent = ACCENT_CLASSES[topic.accent];
              return (
                <Card
                  key={topic.id}
                  className="flex h-full flex-col overflow-hidden animate-in fade-in slide-in-from-bottom-3 duration-700"
                  style={{ animationDelay: `${(i + 5) * 50}ms` }}
                >
                  <FeatureMockFrame
                    ratio="aspect-[16/9]"
                    className="rounded-none border-0 shadow-none"
                  >
                    <topic.Mock compact />
                  </FeatureMockFrame>
                  <div className="flex items-start gap-3 p-4">
                    <div
                      className={cn(
                        'flex h-8 w-8 shrink-0 items-center justify-center rounded-xl',
                        accent.tint
                      )}
                    >
                      <topic.icon className={cn('h-4 w-4', accent.text)} aria-hidden />
                    </div>
                    <div className="min-w-0 flex-1">
                      <h3 className="text-sm font-bold leading-tight">{tContent.title}</h3>
                      <p className="mt-0.5 text-[12px] text-muted-foreground">{tContent.tagline}</p>
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>
        </section>

        {/* DETAILS */}
        <section className="mt-20 space-y-8">
          <header className="max-w-2xl">
            <h2 className="font-headline text-3xl font-bold sm:text-4xl">{landing.detailsTitle}</h2>
            <p className="mt-2 text-sm text-muted-foreground sm:text-base">
              {landing.detailsSubtitle}
            </p>
          </header>

          <div className="space-y-16">
            {FEATURE_TOPICS.map((topic, idx) => {
              const tContent = features.topics[topic.id];
              const accent = ACCENT_CLASSES[topic.accent];
              const reversed = idx % 2 === 1;

              return (
                <article
                  key={topic.id}
                  id={topic.id}
                  className={cn(
                    'grid gap-8 lg:grid-cols-2 lg:items-center',
                    reversed && 'lg:[&>:first-child]:order-2'
                  )}
                >
                  <div className="space-y-4">
                    <div
                      className={cn('inline-flex items-center gap-2 rounded-full px-3 py-1', accent.tint)}
                    >
                      <topic.icon className={cn('h-4 w-4', accent.text)} aria-hidden />
                      <span className={cn('text-xs font-semibold', accent.text)}>
                        {tContent.tagline}
                      </span>
                    </div>
                    <h3 className="font-headline text-2xl font-bold leading-tight sm:text-3xl">
                      {tContent.title}
                    </h3>
                    <p className="text-sm text-muted-foreground sm:text-base">{tContent.summary}</p>

                    <div className="space-y-3 pt-2">
                      <h4 className="flex items-center gap-2 text-sm font-bold">
                        <Lightbulb className={cn('h-4 w-4', accent.text)} aria-hidden />
                        {landing.whatYouGetTitle}
                      </h4>
                      <ul className="space-y-3">
                        {tContent.sections.map((section) => (
                          <li
                            key={section.title}
                            className="rounded-2xl border border-black/5 bg-background/60 p-4 dark:border-white/10"
                          >
                            <p className="text-sm font-semibold leading-tight">{section.title}</p>
                            <p className="mt-1.5 text-[13px] leading-relaxed text-muted-foreground">
                              {section.body}
                            </p>
                            {section.bullets ? (
                              <ul className="mt-2.5 space-y-1.5">
                                {section.bullets.map((b) => (
                                  <li key={b} className="flex items-start gap-2 text-[13px]">
                                    <CheckCircle2
                                      className={cn('mt-0.5 h-3.5 w-3.5 shrink-0', accent.text)}
                                      aria-hidden
                                    />
                                    <span className="text-foreground/90">{b}</span>
                                  </li>
                                ))}
                              </ul>
                            ) : null}
                          </li>
                        ))}
                      </ul>
                    </div>

                    <div className="space-y-3 pt-2">
                      <h4 className="flex items-center gap-2 text-sm font-bold">
                        <ListChecks className={cn('h-4 w-4', accent.text)} aria-hidden />
                        {landing.howToTitle}
                      </h4>
                      <ol className="grid gap-2 sm:grid-cols-3">
                        {tContent.howTo.map((step, i) => (
                          <li
                            key={i}
                            className="flex items-start gap-3 rounded-2xl border border-black/5 bg-background/60 p-3 dark:border-white/10"
                          >
                            <span
                              className={cn(
                                'flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold',
                                accent.tint,
                                accent.text
                              )}
                            >
                              {i + 1}
                            </span>
                            <span className="text-[12px] leading-snug text-foreground">{step}</span>
                          </li>
                        ))}
                      </ol>
                    </div>
                  </div>

                  <div className="lg:pl-4">
                    <FeatureMockFrame
                      ratio="aspect-[16/10]"
                      className="mx-auto max-w-xl"
                    >
                      <topic.Mock />
                    </FeatureMockFrame>
                  </div>
                </article>
              );
            })}
          </div>
        </section>

        {/* BOTTOM CTA */}
        <section className="mt-24">
          <Card className="relative overflow-hidden p-8 sm:p-12">
            <div
              aria-hidden
              className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_15%_15%,hsl(var(--primary)/0.25),transparent_55%),radial-gradient(circle_at_85%_85%,hsl(var(--accent)/0.18),transparent_55%)]"
            />
            <div className="relative z-10 grid gap-8 lg:grid-cols-[1.4fr_1fr] lg:items-center">
              <div className="space-y-3">
                <h2 className="font-headline text-3xl font-bold sm:text-4xl">{landing.ctaTitle}</h2>
                <p className="max-w-xl text-sm text-muted-foreground sm:text-base">
                  {landing.ctaSubtitle}
                </p>
                <div className="flex items-center gap-2 pt-1 text-xs font-semibold text-primary">
                  <ShieldCheck className="h-4 w-4" aria-hidden />
                  {landing.ctaTagline}
                </div>
              </div>
              <div className="space-y-3">
                <Button asChild variant="default" size="lg" className="w-full shadow-md shadow-primary/25">
                  <Link href="/auth">{landing.loginCta}</Link>
                </Button>
                <div className="flex flex-wrap justify-stretch gap-3">
                  <StoreBadge
                    variant="apple"
                    ariaLabel="App Store"
                    line1={landing.appStoreLine1}
                    line2={landing.appStoreLine2}
                    className="flex-1"
                  />
                  <StoreBadge
                    variant="google"
                    ariaLabel="Google Play"
                    line1={landing.googlePlayLine1}
                    line2={landing.googlePlayLine2}
                    className="flex-1"
                  />
                </div>
              </div>
            </div>
          </Card>
        </section>

        <p className="mt-10 text-center text-xs text-muted-foreground">{landing.privacyFootnote}</p>
      </main>

      <footer className="border-t border-black/5 bg-background/60 px-4 py-6 text-center dark:border-white/10">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-3">
          <LegalFooterLinks />
          <p className="text-xs text-muted-foreground">
            © {new Date().getFullYear()} LighChat · {landing.copyrightSuffix}
          </p>
        </div>
      </footer>
      <CookieBanner />
    </div>
  );
}

function LandingHeader({ loginCta, registerCta }: { loginCta: string; registerCta: string }) {
  return (
    <header className="sticky top-0 z-30 border-b border-black/5 bg-background/70 backdrop-blur-xl dark:border-white/10">
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-3 px-4 py-3 sm:px-6 lg:px-8">
        <Link href="/" className="flex items-center gap-2">
          <Image
            src={BRAND_LOGO_SRC}
            alt="LighChat"
            width={BRAND_LOGO_SIZE}
            height={BRAND_LOGO_SIZE}
            className="h-8 w-8 object-contain"
            priority
          />
          <AuthBrandWordmarkTitle as="span" size="inline" className="hidden text-lg sm:inline" />
        </Link>
        <div className="flex items-center gap-2">
          <PublicLanguageMenu className="hidden sm:block" />
          <Button asChild variant="ghost" size="sm" className="hidden sm:inline-flex">
            <Link href="/auth">{registerCta}</Link>
          </Button>
          <Button asChild variant="default" size="sm" className="shadow-sm shadow-primary/30">
            <Link href="/auth">{loginCta}</Link>
          </Button>
        </div>
      </div>
    </header>
  );
}
