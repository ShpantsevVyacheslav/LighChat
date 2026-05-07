'use client';

import * as React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowLeft, ChevronRight, ListChecks, Lightbulb } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import {
  ACCENT_CLASSES,
  FEATURE_TOPICS,
  type FeatureTopic,
} from './features-data';
import { FeatureMockFrame } from './feature-mock-frame';
import { getFeaturesContent } from './features-content';

export function FeaturesTopicView({ topic }: { topic: FeatureTopic }) {
  const router = useRouter();
  const { locale } = useI18n();
  const content = React.useMemo(() => getFeaturesContent(locale), [locale]);
  const t = content.topics[topic.id];
  const accent = ACCENT_CLASSES[topic.accent];

  const related = FEATURE_TOPICS.filter((x) => x.id !== topic.id).slice(0, 3);

  return (
    <article className="space-y-10">
      <button
        type="button"
        onClick={() => router.push('/dashboard/features')}
        className="inline-flex items-center gap-1.5 rounded-full border border-black/5 bg-background/60 px-3 py-1.5 text-xs font-semibold text-muted-foreground hover:text-foreground hover:bg-background dark:border-white/10"
      >
        <ArrowLeft className="h-3.5 w-3.5" aria-hidden />
        {content.backToList}
      </button>

      {/* Hero */}
      <header className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-700">
        <div className={cn('inline-flex items-center gap-2 rounded-full px-3 py-1', accent.tint)}>
          <topic.icon className={cn('h-4 w-4', accent.text)} aria-hidden />
          <span className={cn('text-xs font-semibold', accent.text)}>{t.tagline}</span>
        </div>
        <h1 className="font-headline text-4xl font-bold leading-tight tracking-tight sm:text-5xl">
          {t.title}
        </h1>
        <p className="max-w-2xl text-base text-muted-foreground sm:text-lg">{t.summary}</p>
        {topic.ctaHref ? (
          <Button asChild variant="default" size="lg" className="mt-2">
            <Link href={topic.ctaHref}>{t.ctaLabel}</Link>
          </Button>
        ) : null}
      </header>

      {/* Mock */}
      <section className="animate-in fade-in slide-in-from-bottom-3 duration-700" style={{ animationDelay: '80ms' }}>
        {/* Топик-мокап: даём гарантированную минимальную высоту, чтобы
            тяжёлые композиции (multi-device, E2EE) не обрезались на mobile. */}
        <FeatureMockFrame
          ratio="aspect-[5/4] sm:aspect-[16/9]"
          className="mx-auto min-h-[320px] max-w-4xl sm:min-h-[420px]"
        >
          <topic.Mock />
        </FeatureMockFrame>
      </section>

      {/* What you get */}
      <section className="space-y-4">
        <h2 className="flex items-center gap-2 font-headline text-2xl font-bold">
          <Lightbulb className={cn('h-5 w-5', accent.text)} aria-hidden />
          {content.helpfulTitle}
        </h2>
        <div className="grid gap-4 md:grid-cols-2">
          {t.sections.map((s, i) => (
            <Card
              key={i}
              className="p-5 animate-in fade-in slide-in-from-bottom-3 duration-700"
              style={{ animationDelay: `${120 + i * 60}ms` }}
            >
              <h3 className="text-lg font-bold leading-tight">{s.title}</h3>
              <p className="mt-2 text-sm text-muted-foreground">{s.body}</p>
              {s.bullets ? (
                <ul className="mt-3 space-y-1.5">
                  {s.bullets.map((b) => (
                    <li key={b} className="flex items-start gap-2 text-sm">
                      <span className={cn('mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full', accent.text.replace('text-', 'bg-'))} />
                      <span className="text-foreground/90">{b}</span>
                    </li>
                  ))}
                </ul>
              ) : null}
            </Card>
          ))}
        </div>
      </section>

      {/* How to */}
      <section className="space-y-4">
        <h2 className="flex items-center gap-2 font-headline text-2xl font-bold">
          <ListChecks className={cn('h-5 w-5', accent.text)} aria-hidden />
          {content.howToTitle}
        </h2>
        <ol className="grid gap-2 sm:grid-cols-3">
          {t.howTo.map((step, i) => (
            <li
              key={i}
              className="flex items-start gap-3 rounded-2xl border border-black/5 dark:border-white/10 bg-background/60 p-4"
            >
              <span className={cn('flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-sm font-bold', accent.tint, accent.text)}>
                {i + 1}
              </span>
              <span className="text-sm leading-snug text-foreground">{step}</span>
            </li>
          ))}
        </ol>
      </section>

      {/* Related */}
      <section className="space-y-4 pb-2">
        <h2 className="font-headline text-2xl font-bold">{content.relatedTitle}</h2>
        <div className="grid gap-3 sm:grid-cols-3">
          {related.map((r) => {
            const rContent = content.topics[r.id];
            const rAccent = ACCENT_CLASSES[r.accent];
            return (
              <Link key={r.id} href={`/dashboard/features/${r.id}`} className="group">
                <Card className="flex h-full items-center gap-3 p-3 transition-transform group-hover:-translate-y-0.5">
                  <div className={cn('flex h-10 w-10 shrink-0 items-center justify-center rounded-xl', rAccent.tint)}>
                    <r.icon className={cn('h-4.5 w-4.5', rAccent.text)} aria-hidden />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-bold">{rContent.title}</p>
                    <p className="truncate text-[11px] text-muted-foreground">{rContent.tagline}</p>
                  </div>
                  <ChevronRight className="h-4 w-4 text-muted-foreground/60" aria-hidden />
                </Card>
              </Link>
            );
          })}
        </div>
      </section>
    </article>
  );
}
