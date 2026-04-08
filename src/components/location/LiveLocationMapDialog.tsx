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
import { buildGoogleMapsEmbedUrl, buildGoogleMapsPlaceUrl } from '@/lib/google-maps';
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
            <div className="overflow-hidden rounded-xl bg-muted">
              <iframe
                key={`${live.lat}-${live.lng}-${live.updatedAt ?? ''}`}
                title="Карта: живая геолокация"
                src={embedUrl}
                className="h-56 w-full border-0 sm:h-64"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                allowFullScreen
              />
            </div>
            <p className="text-center text-[11px] text-muted-foreground">
              {live.lat.toFixed(5)}, {live.lng.toFixed(5)}
              {live.accuracyM != null && <> · ±{Math.round(live.accuracyM)} м</>}
            </p>
            {updatedLabel && (
              <p className="text-center text-[11px] text-muted-foreground">Обновлено {updatedLabel}</p>
            )}
            <Button variant="outline" className="w-full gap-2" asChild>
              <a href={mapsUrl} target="_blank" rel="noopener noreferrer">
                Открыть в браузере
                <ExternalLink className="h-4 w-4" />
              </a>
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
