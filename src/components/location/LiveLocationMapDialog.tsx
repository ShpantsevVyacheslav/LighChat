'use client';

import React, { useMemo } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { MapPin, ExternalLink } from 'lucide-react';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc } from 'firebase/firestore';
import type { User } from '@/lib/types';
import { buildGoogleMapsPlaceUrl, buildGoogleStaticMapUrl } from '@/lib/google-maps';
import { isLiveShareVisible } from '@/lib/live-location-utils';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';

interface LiveLocationMapDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string;
  displayName: string;
}

export function LiveLocationMapDialog({ open, onOpenChange, userId, displayName }: LiveLocationMapDialogProps) {
  const firestore = useFirestore();
  const ref = useMemoFirebase(
    () => (firestore && userId ? doc(firestore, 'users', userId) : null),
    [firestore, userId]
  );
  const { data: profileUser } = useDoc<User>(ref);

  const live = profileUser?.liveLocationShare;
  const visible = !!(live && isLiveShareVisible(live));

  const mapsUrl = useMemo(() => {
    if (!live?.lat || !live?.lng) return '';
    return buildGoogleMapsPlaceUrl(live.lat, live.lng);
  }, [live?.lat, live?.lng]);

  const staticUrl = useMemo(() => {
    if (!live?.lat || !live?.lng) return null;
    return buildGoogleStaticMapUrl(live.lat, live.lng, 560, 280);
  }, [live?.lat, live?.lng]);

  const updatedLabel = useMemo(() => {
    if (!live?.updatedAt) return null;
    try {
      return format(parseISO(live.updatedAt), 'HH:mm:ss', { locale: ru });
    } catch {
      return null;
    }
  }, [live?.updatedAt]);

  const untilLabel = useMemo(() => {
    if (!live?.expiresAt) return 'без ограничения по времени';
    try {
      return `до ${format(parseISO(live.expiresAt), 'd MMM, HH:mm', { locale: ru })}`;
    } catch {
      return null;
    }
  }, [live?.expiresAt]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg rounded-2xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-emerald-600" />
            Геолокация: {displayName}
          </DialogTitle>
          <DialogDescription>
            {visible
              ? `Трансляция активна (${untilLabel}). Координаты обновляются автоматически.`
              : 'Пользователь сейчас не делится геолокацией или срок истёк.'}
          </DialogDescription>
        </DialogHeader>

        {!visible || !live ? (
          <p className="text-sm text-muted-foreground">Нет актуальных данных карты.</p>
        ) : (
          <div className="space-y-3">
            {staticUrl ? (
              <a
                href={mapsUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="block overflow-hidden rounded-xl border bg-muted"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={staticUrl} alt="Карта" className="h-auto w-full max-h-56 object-cover" />
              </a>
            ) : (
              <div className="rounded-xl border bg-muted/50 p-4 text-sm">
                <p>
                  {live.lat.toFixed(5)}, {live.lng.toFixed(5)}
                </p>
                {live.accuracyM != null && (
                  <p className="text-muted-foreground">±{Math.round(live.accuracyM)} м</p>
                )}
              </div>
            )}
            {updatedLabel && (
              <p className="text-center text-[11px] text-muted-foreground">Обновлено {updatedLabel}</p>
            )}
            <Button className="w-full gap-2" asChild>
              <a href={mapsUrl} target="_blank" rel="noopener noreferrer">
                Открыть в Google Maps
                <ExternalLink className="h-4 w-4" />
              </a>
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
