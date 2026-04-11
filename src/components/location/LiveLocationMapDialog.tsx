'use client';

import React, { useMemo } from 'react';
import { ExternalLink, X } from 'lucide-react';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc } from 'firebase/firestore';
import type { User } from '@/lib/types';
import { buildGoogleMapsEmbedUrl, buildGoogleMapsPlaceUrl } from '@/lib/google-maps';
import { isLiveShareVisible } from '@/lib/live-location-utils';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { Sheet, SheetContent } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { LocationLiveCountdown } from '@/components/location/LocationLiveCountdown';
import { cn } from '@/lib/utils';

const MAP_SHEET_Z = 'z-[10100]';

const floatBtn =
  'flex h-11 w-11 items-center justify-center rounded-full border-0 bg-transparent text-white shadow-none backdrop-blur-0 transition-colors hover:bg-white/15 active:scale-[0.98] [&_svg]:drop-shadow-md';

interface LiveLocationMapDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string;
  displayName: string;
}

export function LiveLocationMapDialog({
  open,
  onOpenChange,
  userId,
  displayName,
}: LiveLocationMapDialogProps) {
  const firestore = useFirestore();
  const ref = useMemoFirebase(
    () => (firestore && userId ? doc(firestore, 'users', userId) : null),
    [firestore, userId],
  );
  const { data: profileUser } = useDoc<User>(ref);

  const live = profileUser?.liveLocationShare;
  const visible = !!(live && isLiveShareVisible(live));

  const mapsUrl = useMemo(() => {
    if (!live?.lat || !live?.lng) return '';
    return buildGoogleMapsPlaceUrl(live.lat, live.lng);
  }, [live?.lat, live?.lng]);

  const embedUrl = useMemo(() => {
    if (!live?.lat || !live?.lng) return '';
    return buildGoogleMapsEmbedUrl(live.lat, live.lng);
  }, [live?.lat, live?.lng]);

  const updatedLabel = useMemo(() => {
    if (!live?.updatedAt) return null;
    try {
      return format(parseISO(live.updatedAt), 'HH:mm:ss', { locale: ru });
    } catch {
      return null;
    }
  }, [live?.updatedAt]);

  const mapReady = visible && !!live?.lat && !!live?.lng && !!embedUrl;

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
        <div className="relative flex min-h-0 flex-1 flex-col">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className={cn(
              floatBtn,
              'absolute left-[max(0.75rem,env(safe-area-inset-left))] top-[max(0.75rem,env(safe-area-inset-top))] z-30 text-zinc-100',
            )}
            aria-label="Закрыть"
            onClick={() => onOpenChange(false)}
          >
            <X className="h-6 w-6" strokeWidth={2} />
          </Button>

          {!mapReady ? (
            <div className="flex flex-1 flex-col items-center justify-center gap-2 bg-zinc-950 px-6 pb-24 pt-16 text-center text-sm text-zinc-400">
              <p className="text-zinc-200">Нет актуальных данных карты</p>
              <p className="max-w-xs text-xs">{displayName}</p>
            </div>
          ) : (
            <div className="relative min-h-0 flex-1 bg-muted">
              <iframe
                key={`${live!.lat}-${live!.lng}-${live!.updatedAt ?? ''}`}
                title="Карта: живая геолокация"
                src={embedUrl}
                className="absolute inset-0 h-full w-full border-0"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                allowFullScreen
              />
              {live?.expiresAt ? (
                <div
                  className={cn(
                    'absolute left-[max(0.75rem,env(safe-area-inset-left))] z-20 max-w-[min(100%-6rem,280px)]',
                    'top-[max(3.75rem,env(safe-area-inset-top)+2.75rem)]',
                  )}
                >
                  <LocationLiveCountdown
                    compact
                    expiresAtIso={live.expiresAt}
                    className="border-zinc-500/50 bg-black/50 text-zinc-100"
                  />
                </div>
              ) : null}
              {mapsUrl ? (
                <a
                  href={mapsUrl}
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
              ) : null}
              {updatedLabel ? (
                <p className="pointer-events-none absolute bottom-3 left-3 z-10 rounded-md bg-black/45 px-2 py-1 text-[11px] text-zinc-200 backdrop-blur-[2px]">
                  Обновлено {updatedLabel}
                </p>
              ) : null}
            </div>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}
