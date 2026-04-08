'use client';

import React, { useEffect, useReducer, useState } from 'react';
import { MapPin } from 'lucide-react';
import type { ChatLocationShare } from '@/lib/types';
import { cn } from '@/lib/utils';
import { isChatLiveLocationShareExpired } from '@/lib/live-location-utils';
import { CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX } from '@/lib/chat-media-preview-max';
import { SharedLocationMapDialog } from '@/components/location/SharedLocationMapDialog';
import { MessageStatus } from '@/components/chat/parts/MessageStatus';

interface MessageLocationCardProps {
  share: ChatLocationShare;
  isCurrentUser: boolean;
  createdAt: string;
  deliveryStatus?: 'sending' | 'sent' | 'failed';
  readAt: string | null;
  showTimestamps?: boolean;
}

export function MessageLocationCard({
  share,
  isCurrentUser,
  createdAt,
  deliveryStatus,
  readAt,
  showTimestamps = true,
}: MessageLocationCardProps) {
  const [mapOpen, setMapOpen] = useState(false);
  const [, bump] = useReducer((x: number) => x + 1, 0);
  const externalHref = share.mapsUrl || `https://www.google.com/maps?q=${share.lat},${share.lng}`;

  useEffect(() => {
    if (!share.liveSession?.expiresAt) return;
    const ms = new Date(share.liveSession.expiresAt).getTime() - Date.now();
    if (ms <= 0) return;
    const t = window.setTimeout(bump, Math.min(ms + 100, 86_400_000));
    return () => window.clearTimeout(t);
  }, [share.liveSession?.expiresAt]);

  const expiredLive = !!share.liveSession && isChatLiveLocationShareExpired(share);

  if (expiredLive) {
    return (
      <div
        className="rounded-2xl border border-border/50 bg-muted/25 px-3 py-2.5 text-left text-sm leading-snug text-muted-foreground"
        style={{ maxWidth: CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX }}
      >
        {isCurrentUser ? (
          <>
            Трансляция геолокации завершена. Собеседник больше не видит ваше актуальное
            местоположение.
          </>
        ) : (
          <>Трансляция геолокации у этого контакта завершена. Актуальная позиция недоступна.</>
        )}
      </div>
    );
  }

  const openMap = () => setMapOpen(true);

  return (
    <>
      <div
        className="relative w-full shrink-0 overflow-hidden rounded-2xl bg-muted/20"
        style={{ maxWidth: CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX }}
      >
        {share.staticMapUrl ? (
          <button
            type="button"
            onClick={openMap}
            className="relative block w-full cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
            aria-label="Открыть карту"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={share.staticMapUrl}
              alt="Карта"
              className="h-auto w-full max-h-[120px] object-cover bg-muted"
              loading="lazy"
            />
            {showTimestamps && (
              <MessageStatus
                timestamp={createdAt}
                isCurrentUser={isCurrentUser}
                deliveryStatus={deliveryStatus}
                readAt={readAt}
                overlay
                isColoredBubble={false}
              />
            )}
          </button>
        ) : (
          <button
            type="button"
            onClick={openMap}
            className="relative flex w-full min-h-[4.5rem] items-center gap-2 px-3 py-3 pr-14 text-left text-sm text-muted-foreground focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
            aria-label="Открыть карту"
          >
            <MapPin className="h-5 w-5 shrink-0 text-primary" />
            <span>
              {share.lat.toFixed(5)}, {share.lng.toFixed(5)}
              {share.accuracyM != null && (
                <span className="block text-[11px] opacity-80">±{Math.round(share.accuracyM)} м</span>
              )}
            </span>
            {showTimestamps && (
              <MessageStatus
                timestamp={createdAt}
                isCurrentUser={isCurrentUser}
                deliveryStatus={deliveryStatus}
                readAt={readAt}
                overlay
                isColoredBubble={false}
              />
            )}
          </button>
        )}
      </div>
      <SharedLocationMapDialog
        open={mapOpen}
        onOpenChange={setMapOpen}
        lat={share.lat}
        lng={share.lng}
        externalMapsUrl={externalHref}
      />
    </>
  );
}
