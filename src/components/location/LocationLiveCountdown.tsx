'use client';

import { useEffect, useState } from 'react';
import { Timer } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

function formatRemaining(ms: number): string {
  if (ms <= 0) return '0:00';
  const totalSec = Math.floor(ms / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  if (h > 0) {
    return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }
  return `${m}:${String(s).padStart(2, '0')}`;
}

type LocationLiveCountdownProps = {
  /** ISO-время окончания трансляции (Firestore / сообщение). */
  expiresAtIso: string | null | undefined;
  /** Компактный вид для превью в пузыре. */
  compact?: boolean;
  className?: string;
};

/**
 * Обратный отсчёт до окончания ограниченной по времени геолокации.
 */
export function LocationLiveCountdown({
  expiresAtIso,
  compact = false,
  className,
}: LocationLiveCountdownProps) {
  const { t } = useI18n();
  const [remainingMs, setRemainingMs] = useState<number | null>(null);

  useEffect(() => {
    if (!expiresAtIso) {
      setRemainingMs(null);
      return;
    }
    const end = new Date(expiresAtIso).getTime();
    const tick = () => setRemainingMs(end - Date.now());
    tick();
    if (Number.isNaN(end)) {
      setRemainingMs(null);
      return;
    }
    const id = window.setInterval(tick, 1000);
    return () => window.clearInterval(id);
  }, [expiresAtIso]);

  if (!expiresAtIso || remainingMs == null || remainingMs <= 0) return null;

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full border border-border/80 bg-background/90 font-medium text-foreground shadow-sm backdrop-blur-sm',
        compact ? 'px-2 py-0.5 text-[10px]' : 'px-3 py-1 text-xs',
        className,
      )}
    >
      <Timer className={compact ? 'h-2.5 w-2.5 shrink-0' : 'h-3.5 w-3.5 shrink-0'} />
      {compact ? (
        <span className="tabular-nums">{formatRemaining(remainingMs)}</span>
      ) : (
        <span>
          <span className="text-muted-foreground">{t('liveLocation.remaining')}</span>
          <span className="tabular-nums">{formatRemaining(remainingMs)}</span>
        </span>
      )}
    </span>
  );
}
