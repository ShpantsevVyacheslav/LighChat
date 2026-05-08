'use client';

import { useEffect, useMemo, useState } from 'react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getExpireAtMillisFromUnknown } from '@/lib/message-expire-at';

function formatRemaining(ms: number, labels: { soon: string; min: string; h: string; d: string; w: string }): string {
  if (ms <= 0) return '';
  const sec = Math.max(1, Math.floor(ms / 1000));
  if (sec < 120) return labels.soon;
  if (sec < 3600) return `${Math.ceil(sec / 60)} ${labels.min}`;
  if (sec < 86400) return `${Math.ceil(sec / 3600)} ${labels.h}`;
  if (sec < 604800) return `${Math.ceil(sec / 86400)} ${labels.d}`;
  return `${Math.ceil(sec / 604800)} ${labels.w}`;
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
  const { t } = useI18n();
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

  const timeLabels = {
    soon: t('chat.disappearingEta.soon'),
    min: t('chat.disappearingEta.min'),
    h: t('chat.disappearingEta.h'),
    d: t('chat.disappearingEta.d'),
    w: t('chat.disappearingEta.w'),
  };
  const bit = formatRemaining(remaining, timeLabels);
  const text = bit === timeLabels.soon
    ? t('chat.disappearingEta.disappearsSoon')
    : t('chat.disappearingEta.disappearsIn').replace('{time}', bit);

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
      title={t('chat.disappearingEta.tooltip')}
    >
      {text}
    </span>
  );
}
