'use client';

import * as React from 'react';
import { Check, KeyRound, Laptop, Smartphone } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * QR-код в виде SVG: статичный детерминированный «узор» с тремя угловыми
 * метками-finder'ами, как у настоящего QR. Поверх — анимированная
 * сканирующая полоса.
 */
function QrSvg({ className }: { className?: string }) {
  // Генерируем «модули» 21×21 с детерминированным узором.
  const modules: boolean[][] = Array.from({ length: 21 }, (_, r) =>
    Array.from({ length: 21 }, (_, c) => ((r * 7 + c * 13) % 17) < 7),
  );
  // Угловые finder-метки (7×7, чёрный квадрат с белой рамкой и центром).
  const finder = (rr: number, cc: number) => {
    for (let r = 0; r < 7; r += 1) {
      for (let c = 0; c < 7; c += 1) {
        const onEdge = r === 0 || r === 6 || c === 0 || c === 6;
        const innerCore = r >= 2 && r <= 4 && c >= 2 && c <= 4;
        modules[rr + r][cc + c] = onEdge || innerCore;
      }
    }
  };
  finder(0, 0);
  finder(0, 14);
  finder(14, 0);

  return (
    <div className={cn('relative overflow-hidden rounded-md bg-white p-1.5 shadow-[0_4px_14px_-4px_rgba(0,0,0,0.4)]', className)}>
      <svg viewBox="0 0 21 21" className="h-full w-full" shapeRendering="crispEdges" aria-hidden>
        {modules.map((row, r) =>
          row.map((on, c) => (on ? <rect key={`${r}-${c}`} x={c} y={r} width={1} height={1} fill="black" /> : null)),
        )}
      </svg>
      {/* Сканирующий луч */}
      <div className="pointer-events-none absolute inset-x-1.5 top-1.5 h-[3px] rounded-full bg-emerald-400/90 shadow-[0_0_12px_4px_rgba(52,211,153,0.55)] animate-feat-qr-scan" />
    </div>
  );
}

/**
 * Multi-device: телефон с QR + ноутбук с зелёной галочкой «подключено», между
 * ними — пунктирная линия, по которой бегут «ключи» (точки). Снизу — пилюля
 * «Резервная копия защищена паролем». Все тексты — мультиязычные.
 */
export function MockMultiDevice({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  return (
    <div className={cn('relative flex h-full w-full items-center justify-center p-4', className)}>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,hsl(var(--primary)/0.15),transparent_70%)]" />

      <div className="relative flex w-full max-w-md items-center justify-center gap-2 sm:gap-5">
        {/* Phone — масштабируется под высоту контейнера, не выходит за рамку */}
        <div className="relative h-32 w-[68px] shrink-0 rounded-[16px] border-[3px] border-foreground/85 bg-background shadow-xl sm:h-44 sm:w-[88px]">
          <div className="absolute left-1/2 top-1.5 h-1 w-7 -translate-x-1/2 rounded-full bg-foreground/40" />
          <div className="absolute inset-1 mt-2 flex flex-col items-center justify-between rounded-xl bg-gradient-to-br from-primary/25 via-primary/5 to-transparent p-1 sm:inset-1.5 sm:mt-3 sm:rounded-2xl sm:p-2">
            <div className="hidden items-center gap-1 text-[8.5px] font-semibold text-foreground sm:flex">
              <Smartphone className="h-3 w-3 text-primary" aria-hidden />
              {t.multiDevicePhone}
            </div>
            <QrSvg className="h-[44px] w-[44px] sm:h-[64px] sm:w-[64px]" />
            <div className="rounded-full bg-emerald-500/20 px-1.5 py-0.5 text-[8px] font-bold text-emerald-600 dark:text-emerald-300 sm:text-[8.5px]">
              {t.multiDevicePairing}
            </div>
          </div>
        </div>

        {/* Connector с бегущими «ключиками» */}
        <div className="relative flex h-1 flex-1 items-center" aria-hidden>
          <div className="absolute inset-x-0 top-1/2 h-px -translate-y-1/2 border-t border-dashed border-primary/40" />
          <div className="relative flex w-full items-center overflow-hidden">
            <div className="flex shrink-0 items-center gap-3 whitespace-nowrap pl-2 animate-feat-cipher-stream">
              {Array.from({ length: 12 }).map((_, i) => (
                <KeyRound
                  key={i}
                  className="h-3 w-3 text-primary/80"
                  aria-hidden
                />
              ))}
            </div>
          </div>
        </div>

        {/* Laptop с 6-digit verification code: реально это второй шаг pairing,
            который обе стороны видят и сравнивают (см. `E2eeQrPairingDialog`). */}
        <div className="relative shrink-0">
          {/* Bubble «verification code» над ноутбуком */}
          <div
            className="absolute -top-6 left-1/2 -translate-x-1/2 z-10 rounded-md border border-emerald-500/30 bg-emerald-500/15 px-2 py-0.5 font-mono text-[10px] font-bold tracking-[0.3em] text-emerald-600 dark:text-emerald-300 animate-feat-bubble-in"
            style={{ animationDelay: '500ms' }}
          >
            4F · 92 · BD
          </div>
          <div className="relative h-20 w-32 rounded-md border-[3px] border-foreground/85 bg-background shadow-xl sm:h-28 sm:w-48">
            <div className="absolute inset-1.5 rounded-sm bg-gradient-to-br from-violet-500/25 via-primary/15 to-transparent p-2">
              <div className="flex items-center gap-1 text-[9px] font-semibold text-foreground">
                <Laptop className="h-3 w-3" aria-hidden />
                LighChat · {t.multiDeviceDesktop}
              </div>
              <div className="mt-2 grid grid-cols-3 gap-1">
                <div className="col-span-1 h-10 rounded bg-foreground/10" />
                <div className="col-span-2 flex flex-col gap-1">
                  <div className="h-3 rounded bg-foreground/10" />
                  <div className="h-3 rounded bg-foreground/10" />
                  <div className="h-3 rounded bg-primary/30" />
                </div>
              </div>
            </div>
            {/* Зелёная галочка «подключено» */}
            <div className="absolute -right-1.5 -top-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-emerald-500 text-white shadow-lg animate-feat-bubble-in" style={{ animationDelay: '600ms' }}>
              <Check className="h-3.5 w-3.5" strokeWidth={3} aria-hidden />
            </div>
          </div>
          {/* Подставка ноутбука */}
          <div className="mx-auto mt-0.5 h-1.5 w-16 rounded-b-md bg-foreground/85 sm:w-24" />
        </div>
      </div>

      {/* Резервная копия */}
      {!compact ? (
        <div
          className="absolute bottom-3 left-3 right-3 flex items-center gap-2 rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 backdrop-blur-md animate-feat-bubble-in"
          style={{ animationDelay: '900ms' }}
        >
          <KeyRound className="h-4 w-4 shrink-0 text-emerald-600 dark:text-emerald-300" aria-hidden />
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate text-[11.5px] font-semibold text-emerald-700 dark:text-emerald-200">
              {t.multiDeviceBackup}
            </p>
            <p className="truncate text-[10.5px] text-emerald-700/85 dark:text-emerald-300/85">
              {t.multiDeviceBackupSub}
            </p>
          </div>
        </div>
      ) : null}
    </div>
  );
}
