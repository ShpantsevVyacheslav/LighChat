import * as React from 'react';
import { ShieldCheck } from 'lucide-react';
import { cn } from '@/lib/utils';
import { FeatureMockFrame } from '../feature-mock-frame';
import { MockEncryption } from './encryption';
import { MockGames } from './games';
import { MockMeetings } from './meetings';

/**
 * Hero-композит для оглавления и welcome-оверлея: коллаж из трёх ключевых
 * мокапов внахлёст. Статичная композиция, никаких анимаций.
 */
export function MockHero({ className }: { className?: string }) {
  return (
    <div className={cn('relative h-full w-full', className)}>
      <FeatureMockFrame
        ratio="aspect-[16/10]"
        className="absolute left-[6%] top-[8%] w-[58%] -rotate-3"
      >
        <MockEncryption />
      </FeatureMockFrame>
      <FeatureMockFrame
        ratio="aspect-[4/3]"
        className="absolute right-[3%] top-[2%] w-[42%] rotate-2"
      >
        <MockMeetings />
      </FeatureMockFrame>
      <FeatureMockFrame
        ratio="aspect-[5/4]"
        className="absolute bottom-[4%] right-[14%] w-[40%] -rotate-1"
      >
        <MockGames />
      </FeatureMockFrame>
      <div className="pointer-events-none absolute -left-3 -top-3 flex items-center gap-1.5 rounded-full border border-emerald-400/30 bg-emerald-400/15 px-3 py-1 text-[11px] font-semibold text-emerald-300 shadow-lg backdrop-blur-md">
        <ShieldCheck className="h-3.5 w-3.5" aria-hidden />
        E2EE
      </div>
    </div>
  );
}
