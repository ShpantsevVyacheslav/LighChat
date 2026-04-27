'use client';

import { useEffect, useMemo, useState } from 'react';
import { cn } from '@/lib/utils';
import { getExpireAtMillisFromUnknown } from '@/lib/message-expire-at';

function formatRuRemaining(ms: number): string {
  if (ms <= 0) return '';
  const sec = Math.max(1, Math.floor(ms / 1000));
  if (sec < 120) return 'скоро';
  if (sec < 3600) return `${Math.ceil(sec / 60)} мин`;
  if (sec < 86400) return `${Math.ceil(sec / 3600)} ч`;
  if (sec < 604800) return `${Math.ceil(sec / 86400)} дн`;
  return `${Math.ceil(sec / 604800)} нед`;
}

type MessageDisappearingEtaProps = {
  expireAt: unknown;
  /** `inline` — рядом со временем; `bare` — как у MessageStatus bare; `muted` — подпись под медиа */
  variant?: 'inline' | 'bare' | 'muted';
  className?: string;
};

export function MessageDisappearingEta({
  expireAt,
  variant = 'inline',
  className,
}: MessageDisappearingEtaProps) {
  const endMs = useMemo(() => getExpireAtMillisFromUnknown(expireAt), [expireAt]);
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    if (endMs == null) return undefined;
    const tick = () => setNow(Date.now());
    const id = window.setInterval(tick, 30_000);
    return () => window.clearInterval(id);
  }, [endMs]);

  if (endMs == null) return null;
  const remaining = endMs - now;
  if (remaining <= 0) return null;

  const bit = formatRuRemaining(remaining);
  const text = bit === 'скоро' ? 'исчезнет скоро' : `исчезнет через ${bit}`;

  return (
    <span
      className={cn(
        'select-none whitespace-nowrap',
        variant === 'bare' &&
          'text-[11px] font-medium text-white/70 [text-shadow:0_1px_2px_rgba(0,0,0,0.85)]',
        variant === 'inline' && 'text-[10px] text-muted-foreground/80',
        variant === 'muted' && 'text-[10px] text-white/70',
        className,
      )}
      title="Сообщение удалится из чата по таймеру исчезающих сообщений"
    >
      {text}
    </span>
  );
}
