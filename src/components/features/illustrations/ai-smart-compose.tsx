'use client';

import * as React from 'react';
import { Mic, Paperclip, Smile, Sparkles, Undo2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Мокап AI Smart Compose:
 *  – мини-чат с одним черновиком в инпуте;
 *  – над инпутом всплывает sparkle-кнопка + preview-pill переписанного текста;
 *  – внизу маленький style-picker (11 стилей; активный — Friendly).
 *
 * Точно повторяет реальный `SmartComposeStrip` mobile-композера:
 * sparkle с pulse-анимацией, preview-pill чуть выше с лёгким shadow,
 * кнопка Undo справа от sparkle (показывается после применения).
 */

const STYLES: { id: string; label: { ru: string; en: string }; active?: boolean }[] = [
  { id: 'friendly', label: { ru: 'Дружелюбный', en: 'Friendly' }, active: true },
  { id: 'formal', label: { ru: 'Формальный', en: 'Formal' } },
  { id: 'youth', label: { ru: 'Молодёжный', en: 'Youth' } },
  { id: 'strict', label: { ru: 'Строгий', en: 'Strict' } },
  { id: 'funny', label: { ru: 'Смешной', en: 'Funny' } },
  { id: 'romantic', label: { ru: 'Романтика', en: 'Romantic' } },
  { id: 'shorter', label: { ru: 'Короче', en: 'Shorter' } },
  { id: 'proofread', label: { ru: 'Проверка', en: 'Proofread' } },
];

export function MockAiSmartCompose({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  const isRu = locale !== 'en';

  const draft = isRu ? 'привет, хочу спросить про встречу' : 'hi, wanted to ask about the meeting';
  const rewritten = isRu
    ? 'Привет! Хотел спросить про сегодняшнюю встречу — есть пара уточнений.'
    : 'Hi! Wanted to check about today’s meeting — I have a couple of questions.';
  const onDevice = isRu ? 'Apple Intelligence · На устройстве' : 'Apple Intelligence · On-device';

  return (
    <div className={cn('relative flex h-full w-full flex-col p-3', className)}>
      <div className="flex items-center gap-1.5 self-start rounded-full border border-violet-400/30 bg-violet-400/10 px-2.5 py-0.5 text-[10px] font-bold text-violet-500 dark:text-violet-300">
        <Sparkles className="h-3 w-3 animate-feat-lock-cycle" aria-hidden />
        {onDevice}
      </div>

      {/* Preview-pill переписанного текста */}
      <div
        className="relative mt-3 flex items-start gap-2 rounded-2xl border border-violet-400/30 bg-violet-400/[0.08] px-3 py-2 shadow-sm animate-feat-bubble-in"
        style={{ animationDelay: '120ms' }}
      >
        <Sparkles className="mt-0.5 h-3.5 w-3.5 shrink-0 text-violet-500" aria-hidden />
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-bold uppercase tracking-wider text-violet-500 dark:text-violet-300">
            {isRu ? 'Переписано · Дружелюбный' : 'Rewritten · Friendly'}
          </p>
          <p className="mt-0.5 text-[12px] leading-snug text-foreground">
            {rewritten}
          </p>
        </div>
      </div>

      {/* Sparkle над композером + Undo */}
      <div className="mt-2 flex items-center gap-2">
        <button
          type="button"
          className="relative flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-violet-400 to-violet-600 text-white shadow-[0_0_16px_rgba(167,139,250,0.55)]"
          aria-label="Smart compose"
        >
          <Sparkles className="h-4 w-4" aria-hidden />
          <span className="pointer-events-none absolute inset-0 rounded-full bg-violet-400/35 animate-feat-pin-pulse" />
        </button>
        <button
          type="button"
          className="flex h-7 items-center gap-1 rounded-full border border-black/5 dark:border-white/10 bg-background/70 px-2 text-[10px] font-bold text-foreground/85 animate-feat-bubble-in"
          style={{ animationDelay: '600ms' }}
          aria-label="Undo"
        >
          <Undo2 className="h-3 w-3" aria-hidden />
          {isRu ? 'Отменить' : 'Undo'}
        </button>
      </div>

      {/* Имитация композера */}
      <div className="mt-2 flex items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-2 py-1.5">
        <Paperclip className="h-3.5 w-3.5 text-muted-foreground" aria-hidden />
        <span className="flex-1 truncate text-[12px] text-foreground/70">
          {draft}
          <span className="ml-0.5 inline-block h-3 w-px bg-foreground/70 animate-feat-caret align-middle" />
        </span>
        <Smile className="h-3.5 w-3.5 text-muted-foreground" aria-hidden />
        <span className="flex h-6 w-6 items-center justify-center rounded-full bg-primary text-primary-foreground">
          <Mic className="h-3 w-3" aria-hidden />
        </span>
      </div>

      {/* Style picker — 8 видимых из 11 (compact-режим скрывает) */}
      {!compact ? (
        <div className="mt-3">
          <p className="px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
            {t.aiPickerTitle}
          </p>
          <div className="mt-1 flex flex-wrap gap-1">
            {STYLES.map((s, i) => (
              <span
                key={s.id}
                className={cn(
                  'rounded-full border px-2 py-0.5 text-[10px] font-bold animate-feat-bubble-in',
                  s.active
                    ? 'border-violet-400/50 bg-violet-400/15 text-violet-500 dark:text-violet-300'
                    : 'border-black/5 dark:border-white/10 bg-background/55 text-muted-foreground',
                )}
                style={{ animationDelay: `${300 + i * 50}ms` }}
              >
                {s.label[isRu ? 'ru' : 'en']}
              </span>
            ))}
            <span className="rounded-full border border-black/5 dark:border-white/10 bg-background/55 px-2 py-0.5 text-[10px] font-bold text-muted-foreground">
              +3
            </span>
          </div>
        </div>
      ) : null}
    </div>
  );
}
