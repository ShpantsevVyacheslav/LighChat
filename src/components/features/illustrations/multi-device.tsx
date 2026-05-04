import * as React from 'react';
import { Monitor, Smartphone, KeyRound } from 'lucide-react';
import { cn } from '@/lib/utils';

function MiniQR() {
  return (
    <div className="grid h-16 w-16 grid-cols-8 grid-rows-8 gap-px rounded-md bg-white p-1.5 shadow-md">
      {Array.from({ length: 64 }).map((_, i) => {
        // детерминированный псевдо-узор: углы (метки) + редкие модули
        const row = Math.floor(i / 8);
        const col = i % 8;
        const isCorner =
          (row < 3 && col < 3) ||
          (row < 3 && col > 4) ||
          (row > 4 && col < 3);
        const cornerOuter = isCorner && (row === 0 || row === 2 || col === 0 || col === 2 || row === 6 || col === 6);
        const cornerInner = isCorner && row === 1 && col === 1;
        const sparse = ((i * 13) % 17) < 5;
        const black = cornerOuter || cornerInner || (!isCorner && sparse);
        return <span key={i} className={cn(black ? 'bg-black' : 'bg-white')} />;
      })}
    </div>
  );
}

export function MockMultiDevice({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full items-center justify-center p-4', className)}>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,hsl(var(--primary)/0.18),transparent_70%)]" />
      <div className="relative flex w-full max-w-md items-center justify-center gap-4">
        <div className="relative h-44 w-24 shrink-0 rounded-[24px] border-4 border-foreground/80 bg-background shadow-xl">
          <div className="absolute left-1/2 top-1.5 h-1 w-8 -translate-x-1/2 rounded-full bg-foreground/40" />
          <div className="absolute inset-2 mt-3 flex flex-col items-center justify-center gap-2 rounded-xl bg-gradient-to-br from-primary/30 to-primary/5 p-2">
            <Smartphone className="h-5 w-5 text-primary" aria-hidden />
            <span className="text-center text-[9px] font-semibold leading-tight">Подтвердите вход</span>
            <MiniQR />
          </div>
        </div>
        {!compact ? (
          <div className="flex flex-col items-center gap-1 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
            <span className="h-px w-10 bg-muted-foreground/40" />
            <span className="rounded-full bg-emerald-400/15 px-2 py-0.5 text-emerald-300">QR-паринг</span>
            <span className="h-px w-10 bg-muted-foreground/40" />
          </div>
        ) : null}
        <div className="relative h-32 w-48 shrink-0 rounded-xl border-2 border-foreground/80 bg-background shadow-xl">
          <div className="absolute inset-1.5 rounded-lg bg-gradient-to-br from-violet-500/30 to-primary/20 p-2">
            <div className="flex items-center gap-1 text-[9px] font-semibold text-foreground">
              <Monitor className="h-3 w-3" aria-hidden /> LighChat · Desktop
            </div>
            <div className="mt-2 grid grid-cols-3 gap-1">
              <div className="col-span-1 h-12 rounded bg-foreground/10" />
              <div className="col-span-2 h-12 rounded bg-foreground/10" />
            </div>
            <div className="mt-1 h-3 rounded bg-foreground/10" />
          </div>
          <div className="absolute -bottom-1 left-1/2 h-3 w-16 -translate-x-1/2 rounded-b-lg bg-foreground/80" />
        </div>
      </div>
      {!compact ? (
        <div className="absolute bottom-3 left-3 right-3 flex items-center gap-2 rounded-2xl border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-[11px] text-emerald-300">
          <KeyRound className="h-3.5 w-3.5" aria-hidden />
          <div className="flex-1 leading-tight">
            <p className="font-semibold">Резервная копия ключей · защищена паролем</p>
            <p className="opacity-80">Восстановите чаты на любом новом устройстве</p>
          </div>
        </div>
      ) : null}
    </div>
  );
}
