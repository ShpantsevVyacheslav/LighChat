'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';

type StoreBadgeProps = {
  /** Куда вести по клику. Пока заглушка, поэтому `#`. */
  href?: string;
  /** Маленькая надпись сверху, например «Скачать в». */
  line1: string;
  /** Большая надпись снизу — название стора. */
  line2: string;
  className?: string;
  /** Метка для скринридера. */
  ariaLabel: string;
};

/** Логотип Apple — простая глифовая фигура яблока. */
function AppleLogo({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  );
}

/** «Треугольник» Google Play в фирменных цветах. */
function GooglePlayLogo({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden>
      <path
        d="M3.6 1.7C3.2 2 3 2.5 3 3.1v17.8c0 .6.2 1.1.6 1.4l9.5-9.6L3.6 1.7z"
        fill="#34A853"
      />
      <path
        d="M16.8 8.4 5.4 1.4c-.4-.2-.9-.3-1.3-.1L13.1 12.7l3.7-4.3z"
        fill="#FBBC04"
      />
      <path
        d="M16.8 16.6 13.1 12.3l-9 11.4c.4.2.9.1 1.3-.1L16.8 16.6z"
        fill="#EA4335"
      />
      <path
        d="m21 11.2-3.6-2-4 4.3 4 4 3.6-2c1.3-.7 1.3-2.6 0-3.3z"
        fill="#4285F4"
      />
    </svg>
  );
}

/** Обобщённый бейдж стора. */
export function StoreBadge({
  href = '#',
  line1,
  line2,
  className,
  ariaLabel,
  variant,
}: StoreBadgeProps & { variant: 'apple' | 'google' }) {
  const Icon = variant === 'apple' ? AppleLogo : GooglePlayLogo;
  return (
    <a
      href={href}
      onClick={(event) => {
        if (href === '#') event.preventDefault();
      }}
      aria-label={ariaLabel}
      aria-disabled={href === '#'}
      className={cn(
        'group inline-flex h-14 min-w-[180px] items-center gap-3 rounded-2xl bg-black/90 px-4 text-white shadow-lg shadow-black/20 transition-transform hover:-translate-y-0.5 hover:bg-black focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 focus-visible:ring-offset-2 dark:shadow-black/40',
        className
      )}
    >
      <Icon className="h-7 w-7 shrink-0" />
      <span className="flex flex-col items-start leading-none">
        <span className="text-[10px] font-medium uppercase tracking-wide opacity-80">
          {line1}
        </span>
        <span className="text-base font-semibold leading-tight">{line2}</span>
      </span>
    </a>
  );
}
