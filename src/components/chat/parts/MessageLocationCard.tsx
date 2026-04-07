'use client';

import React from 'react';
import { MapPin, ExternalLink, Activity } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import type { ChatLocationShare } from '@/lib/types';
import { cn } from '@/lib/utils';

interface MessageLocationCardProps {
  share: ChatLocationShare;
  isCurrentUser: boolean;
}

export function MessageLocationCard({ share, isCurrentUser }: MessageLocationCardProps) {
  const href = share.mapsUrl || `https://www.google.com/maps?q=${share.lat},${share.lng}`;

  return (
    <div
      className={cn(
        'mt-1 overflow-hidden rounded-xl border bg-background/60 backdrop-blur-md',
        isCurrentUser ? 'border-white/25' : 'border-black/10 dark:border-white/10'
      )}
    >
      {share.staticMapUrl ? (
        <a href={href} target="_blank" rel="noopener noreferrer" className="block">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={share.staticMapUrl}
            alt="Карта"
            className="h-auto w-full max-h-40 object-cover bg-muted"
            loading="lazy"
          />
        </a>
      ) : (
        <div className="flex items-center gap-2 px-3 py-4 text-sm text-muted-foreground">
          <MapPin className="h-5 w-5 shrink-0 text-primary" />
          <span>
            {share.lat.toFixed(5)}, {share.lng.toFixed(5)}
            {share.accuracyM != null && (
              <span className="block text-[11px] opacity-80">±{Math.round(share.accuracyM)} м</span>
            )}
          </span>
        </div>
      )}
      <div className="flex items-center justify-between gap-2 border-t border-black/5 px-2 py-1.5 dark:border-white/10">
        <span className="flex flex-wrap items-center gap-1.5 px-1 text-[11px] font-medium text-muted-foreground">
          <MapPin className="h-3.5 w-3.5 text-primary" />
          Геолокация
          {share.liveSession && (
            <Badge
              variant="outline"
              className="h-5 gap-0.5 border-emerald-500/40 bg-emerald-500/10 px-1.5 text-[9px] font-bold uppercase tracking-wide text-emerald-700 dark:text-emerald-300"
            >
              <Activity className="h-2.5 w-2.5 animate-pulse" aria-hidden />
              Живое
            </Badge>
          )}
        </span>
        <Button variant="ghost" size="sm" className="h-8 shrink-0 gap-1 rounded-lg text-xs" asChild>
          <a href={href} target="_blank" rel="noopener noreferrer">
            Google Maps
            <ExternalLink className="h-3 w-3 opacity-70" />
          </a>
        </Button>
      </div>
    </div>
  );
}
