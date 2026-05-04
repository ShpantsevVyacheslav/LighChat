import * as React from 'react';
import { MapPin, Square } from 'lucide-react';
import { cn } from '@/lib/utils';

export function MockLiveLocation({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full overflow-hidden', className)}>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_30%,#9be7c4_0%,#6ec5e8_45%,#3a4f86_100%)] dark:bg-[radial-gradient(circle_at_30%_30%,#3b6857_0%,#1f4566_45%,#0e1a3a_100%)]" />
      <svg className="absolute inset-0 h-full w-full opacity-30" viewBox="0 0 400 240" preserveAspectRatio="none">
        <path d="M0,160 C60,140 120,180 180,150 C240,120 300,160 400,130" fill="none" stroke="white" strokeWidth="1" />
        <path d="M0,90 C80,80 160,110 220,90 C280,70 340,100 400,80" fill="none" stroke="white" strokeWidth="1" />
        <path d="M40,0 L40,240 M180,0 L180,240 M320,0 L320,240" stroke="white" strokeWidth="0.5" opacity="0.4" />
      </svg>
      <div className="relative flex h-full w-full flex-col justify-between p-3">
        {!compact ? (
          <div className="self-start rounded-full bg-rose-500 px-3 py-1 text-[11px] font-bold text-white shadow-lg">
            Делитесь геолокацией · ещё 14 мин
          </div>
        ) : null}
        <div className="relative mx-auto h-20 w-20">
          <span className="absolute inset-0 animate-ping rounded-full bg-rose-500/40" />
          <span className="absolute inset-2 rounded-full bg-rose-500/60" />
          <span className="absolute inset-5 rounded-full bg-white/95 shadow-lg flex items-center justify-center">
            <MapPin className="h-5 w-5 text-rose-500" aria-hidden />
          </span>
        </div>
        {!compact ? (
          <div className="flex items-center gap-2 rounded-2xl border border-rose-400/30 bg-rose-500/15 px-3 py-2 backdrop-blur-md">
            <Square className="h-3.5 w-3.5 fill-rose-500 text-rose-500" aria-hidden />
            <div className="flex-1 leading-tight text-[11px]">
              <p className="font-semibold text-white">Остановить трансляцию</p>
              <p className="text-white/80">Останется 14 минут — нажмите, чтобы прекратить</p>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
