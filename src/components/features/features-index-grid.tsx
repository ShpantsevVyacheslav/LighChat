'use client';

import * as React from 'react';
import Link from 'next/link';
import { ArrowUpRight, Play, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { ACCENT_CLASSES, FEATURE_TOPICS } from './features-data';
import { FeatureMockFrame } from './feature-mock-frame';
import { MockHero } from './illustrations/hero';
import { getFeaturesContent } from './features-content';
import { FeaturesShowreel } from './showreel/features-showreel';
import { SHOWREEL_TOTAL_MS } from './showreel/showreel-scenes';

export function FeaturesIndexGrid({ source }: { source?: string }) {
  const { locale } = useI18n();
  const content = React.useMemo(() => getFeaturesContent(locale), [locale]);
  const [showreelOpen, setShowreelOpen] = React.useState(false);

  const flagships = FEATURE_TOPICS.filter((t) => t.highlight);
  const others = FEATURE_TOPICS.filter((t) => !t.highlight);
  const totalMin = Math.round(SHOWREEL_TOTAL_MS / 60000);

  return (
    <div className="space-y-12">
      {/* Hero */}
      <section className="relative grid gap-8 lg:grid-cols-[1.1fr_1fr] lg:items-center">
        <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-700">
          {source === 'welcome' ? (
            <div className="inline-flex items-center gap-1.5 rounded-full border border-primary/30 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
              <Sparkles className="h-3.5 w-3.5" aria-hidden />
              {content.fromWelcomeBadge}
            </div>
          ) : null}
          <h1 className="font-headline text-4xl font-bold leading-tight tracking-tight sm:text-5xl lg:text-6xl">
            {content.pageHeroPrimary}
          </h1>
          <p className="max-w-xl text-base text-muted-foreground sm:text-lg">
            {content.pageHeroSecondary}
          </p>
          {/* CTA «Watch the tour» — открывает showreel-плеер */}
          <Button
            type="button"
            variant="default"
            size="lg"
            onClick={() => setShowreelOpen(true)}
            className="mt-3 gap-2 shadow-lg shadow-primary/25"
          >
            <Play className="h-4 w-4 fill-current" aria-hidden />
            {content.showreelCta}
            <span className="text-xs font-medium opacity-80">· {totalMin} min</span>
          </Button>
        </div>
        <div className="relative h-[260px] sm:h-[340px] lg:h-[400px]">
          <MockHero />
        </div>
      </section>

      <FeaturesShowreel open={showreelOpen} onClose={() => setShowreelOpen(false)} />

      {/* Highlights */}
      <section className="space-y-4">
        <header className="flex items-end justify-between gap-2">
          <div>
            <h2 className="font-headline text-2xl font-bold sm:text-3xl">{content.highlightTitle}</h2>
            <p className="mt-1 text-sm text-muted-foreground">{content.highlightSubtitle}</p>
          </div>
        </header>
        <div className="grid gap-4 sm:grid-cols-2">
          {flagships.map((topic, i) => {
            const tContent = content.topics[topic.id];
            const accent = ACCENT_CLASSES[topic.accent];
            return (
              <Link
                key={topic.id}
                href={`/dashboard/features/${topic.id}`}
                className="group focus-visible:outline-none"
                style={{ animationDelay: `${i * 60}ms` }}
              >
                <Card
                  className={cn(
                    'relative h-full overflow-hidden transition-transform duration-300 group-hover:-translate-y-0.5',
                    'animate-in fade-in slide-in-from-bottom-3 duration-700',
                    'group-focus-visible:ring-2 group-focus-visible:ring-ring'
                  )}
                >
                  <div
                    className={cn(
                      'pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r',
                      accent.gradient
                    )}
                  />
                  <FeatureMockFrame ratio="aspect-[16/10]" className="rounded-none border-0 shadow-none">
                    <topic.Mock />
                  </FeatureMockFrame>
                  <div className="flex items-start gap-3 p-5">
                    <div className={cn('flex h-9 w-9 shrink-0 items-center justify-center rounded-2xl', accent.tint)}>
                      <topic.icon className={cn('h-4.5 w-4.5', accent.text)} aria-hidden />
                    </div>
                    <div className="min-w-0 flex-1">
                      <h3 className="font-headline text-lg font-bold leading-tight">{tContent.title}</h3>
                      <p className="mt-1 text-sm text-muted-foreground">{tContent.tagline}</p>
                    </div>
                    <ArrowUpRight className="h-4 w-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" aria-hidden />
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      </section>

      {/* Others */}
      <section className="space-y-4">
        <header>
          <h2 className="font-headline text-2xl font-bold sm:text-3xl">{content.moreTitle}</h2>
          <p className="mt-1 text-sm text-muted-foreground">{content.moreSubtitle}</p>
        </header>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {others.map((topic, i) => {
            const tContent = content.topics[topic.id];
            const accent = ACCENT_CLASSES[topic.accent];
            return (
              <Link
                key={topic.id}
                href={`/dashboard/features/${topic.id}`}
                className="group focus-visible:outline-none"
                style={{ animationDelay: `${(i + 5) * 50}ms` }}
              >
                <Card className="flex h-full flex-col overflow-hidden transition-transform duration-300 group-hover:-translate-y-0.5 animate-in fade-in slide-in-from-bottom-3 duration-700">
                  <FeatureMockFrame ratio="aspect-[16/9]" className="rounded-none border-0 shadow-none">
                    <topic.Mock compact />
                  </FeatureMockFrame>
                  <div className="flex items-start gap-3 p-4">
                    <div className={cn('flex h-8 w-8 shrink-0 items-center justify-center rounded-xl', accent.tint)}>
                      <topic.icon className={cn('h-4 w-4', accent.text)} aria-hidden />
                    </div>
                    <div className="min-w-0 flex-1">
                      <h3 className="text-sm font-bold leading-tight">{tContent.title}</h3>
                      <p className="mt-0.5 text-[12px] text-muted-foreground">{tContent.tagline}</p>
                    </div>
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      </section>
    </div>
  );
}
