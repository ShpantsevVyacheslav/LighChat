'use client';

import { MapPin, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLiveLocationControl } from '@/components/location/LiveLocationProvider';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

/** Полоса «идёт трансляция геолокации» + кнопка отзыва. */
export function LiveLocationStopBanner({ className }: { className?: string }) {
  const { t } = useI18n();
  const { isSharing, stopSharing } = useLiveLocationControl();
  if (!isSharing) return null;

  return (
    <div
      className={cn(
        'pointer-events-auto flex items-center gap-2 rounded-2xl border border-emerald-500/40 bg-emerald-950/90 px-3 py-2 text-sm text-emerald-50 shadow-lg backdrop-blur-md dark:bg-emerald-950/80',
        className
      )}
      role="status"
    >
      <MapPin className="h-4 w-4 shrink-0 animate-pulse text-emerald-300" aria-hidden />
      <span className="min-w-0 flex-1 font-medium">{t('liveLocation.sharingBanner')}</span>
      <Button
        type="button"
        size="sm"
        variant="secondary"
        className="h-8 shrink-0 gap-1 rounded-xl bg-white/15 text-white hover:bg-white/25"
        onClick={() => void stopSharing()}
      >
        <X className="h-3.5 w-3.5" />
        {t('liveLocation.stop')}
      </Button>
    </div>
  );
}
