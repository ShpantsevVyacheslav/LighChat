'use client';

import React from 'react';
import { ExternalLink, X } from 'lucide-react';
import { buildGoogleMapsEmbedUrl, buildGoogleMapsPlaceUrl } from '@/lib/google-maps';
import { Sheet, SheetContent } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { LocationLiveCountdown } from '@/components/location/LocationLiveCountdown';
import { cn } from '@/lib/utils';

/** Выше плавающего якоря чата (`ChatAnchor`, z-[10050]). */
const MAP_SHEET_Z = 'z-[10100]';

export interface SharedLocationMapDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lat: number;
  lng: number;
  /** Запасная внешняя ссылка (как в сообщении); иначе собирается из lat/lng. */
  externalMapsUrl?: string | null;
  /** Окончание временной трансляции из сообщения (`liveSession.expiresAt`). */
  liveExpiresAt?: string | null;
}

export function SharedLocationMapDialog({
  open,
  onOpenChange,
  lat,
  lng,
  externalMapsUrl,
  liveExpiresAt,
}: SharedLocationMapDialogProps) {
  const embedUrl = buildGoogleMapsEmbedUrl(lat, lng);
  const external =
    (externalMapsUrl && externalMapsUrl.trim()) || buildGoogleMapsPlaceUrl(lat, lng);

  const floatBtn =
    'flex h-11 w-11 items-center justify-center rounded-full border-0 bg-transparent text-white shadow-none backdrop-blur-0 transition-colors hover:bg-white/15 active:scale-[0.98] [&_svg]:drop-shadow-md';

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="right"
        showCloseButton={false}
        overlayClassName={MAP_SHEET_Z}
        className={cn(
          MAP_SHEET_Z,
          'flex h-full max-h-[100dvh] w-full max-w-full flex-col gap-0 border-0 p-0 shadow-2xl',
          'rounded-none data-[state=open]:duration-300 sm:max-w-[min(100vw-0px,440px)] sm:rounded-l-3xl md:max-w-[480px]',
        )}
      >
        <div className="relative min-h-0 flex-1 bg-muted">
          <iframe
            title="Карта: выбранная точка"
            src={embedUrl}
            className="absolute inset-0 h-full w-full border-0"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            allowFullScreen
          />
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className={cn(
              floatBtn,
              'absolute left-[max(0.75rem,env(safe-area-inset-left))] top-[max(0.75rem,env(safe-area-inset-top))] z-20',
            )}
            aria-label="Закрыть"
            onClick={() => onOpenChange(false)}
          >
            <X className="h-6 w-6" strokeWidth={2} />
          </Button>
          {liveExpiresAt ? (
            <div
              className={cn(
                'absolute left-[max(0.75rem,env(safe-area-inset-left))] z-20 max-w-[min(100%-6rem,280px)]',
                'top-[max(3.75rem,env(safe-area-inset-top)+2.75rem)]',
              )}
            >
              <LocationLiveCountdown
                compact
                expiresAtIso={liveExpiresAt}
                className="border-zinc-500/50 bg-black/50 text-zinc-100"
              />
            </div>
          ) : null}
          <a
            href={external}
            target="_blank"
            rel="noopener noreferrer"
            className={cn(
              floatBtn,
              'absolute right-[max(1rem,env(safe-area-inset-right))] top-[max(1rem,env(safe-area-inset-top))] z-20',
            )}
            aria-label="Открыть в браузере"
          >
            <ExternalLink className="h-5 w-5" strokeWidth={2} />
          </a>
        </div>
      </SheetContent>
    </Sheet>
  );
}
