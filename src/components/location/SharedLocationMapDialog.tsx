'use client';

import React from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { MapPin, ExternalLink } from 'lucide-react';
import { buildGoogleMapsEmbedUrl, buildGoogleMapsPlaceUrl } from '@/lib/google-maps';

export interface SharedLocationMapDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lat: number;
  lng: number;
  /** Запасная внешняя ссылка (как в сообщении); иначе собирается из lat/lng. */
  externalMapsUrl?: string | null;
}

export function SharedLocationMapDialog({
  open,
  onOpenChange,
  lat,
  lng,
  externalMapsUrl,
}: SharedLocationMapDialogProps) {
  const embedUrl = buildGoogleMapsEmbedUrl(lat, lng);
  const external = (externalMapsUrl && externalMapsUrl.trim()) || buildGoogleMapsPlaceUrl(lat, lng);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-[min(100vw-1rem,32rem)] gap-3 rounded-2xl p-4 sm:max-w-lg">
        <DialogHeader className="space-y-1">
          <DialogTitle className="flex items-center gap-2 text-base">
            <MapPin className="h-5 w-5 shrink-0 text-primary" />
            Местоположение
          </DialogTitle>
          <DialogDescription className="text-xs">
            {lat.toFixed(5)}, {lng.toFixed(5)}
          </DialogDescription>
        </DialogHeader>
        <div className="overflow-hidden rounded-xl bg-muted">
          <iframe
            title="Карта: выбранная точка"
            src={embedUrl}
            className="h-[min(55vh,360px)] w-full border-0 sm:h-[380px]"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            allowFullScreen
          />
        </div>
        <div className="flex justify-end">
          <Button variant="outline" size="sm" className="gap-1.5" asChild>
            <a href={external} target="_blank" rel="noopener noreferrer">
              <ExternalLink className="h-3.5 w-3.5" />
              Открыть в браузере
            </a>
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
