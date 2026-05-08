'use client';

import React, { useEffect, useReducer, useState } from 'react';
import { useI18n } from '@/hooks/use-i18n';
import { MapPin } from 'lucide-react';
import type { ChatLocationShare, UserLiveLocationShare } from '@/lib/types';
import { cn } from '@/lib/utils';
import { isChatLiveLocationMessageStillStreaming } from '@/lib/live-location-utils';
import { CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX } from '@/lib/chat-media-preview-max';
import { SharedLocationMapDialog } from '@/components/location/SharedLocationMapDialog';
import { LocationLiveCountdown } from '@/components/location/LocationLiveCountdown';
import { MessageStatus } from '@/components/chat/parts/MessageStatus';

interface MessageLocationCardProps {
  share: ChatLocationShare;
  isCurrentUser: boolean;
  createdAt: string;
  /** Профиль отправителя: актуальная трансляция из `users/{senderId}.liveLocationShare`. */
  senderLiveShare?: UserLiveLocationShare | null;
  /** false — пока нет снимка участника в `allUsers`: только таймер сообщения, без мигания «завершено». */
  senderProfileResolved?: boolean;
  deliveryStatus?: 'sending' | 'sent' | 'failed';
  readAt: string | null;
  showTimestamps?: boolean;
}

export function MessageLocationCard({
  share,
  isCurrentUser,
  createdAt,
  senderLiveShare = null,
  senderProfileResolved = false,
  deliveryStatus,
  readAt,
  showTimestamps = true,
}: MessageLocationCardProps) {
  const { t } = useI18n();
  const [mapOpen, setMapOpen] = useState(false);
  const [, bump] = useReducer((x: number) => x + 1, 0);
  const externalHref = share.mapsUrl || `https://www.google.com/maps?q=${share.lat},${share.lng}`;

  const stillStreamingLive =
    !!share.liveSession &&
    isChatLiveLocationMessageStillStreaming(share, createdAt, senderLiveShare, senderProfileResolved);

  useEffect(() => {
    if (!share.liveSession?.expiresAt) return;
    const ms = new Date(share.liveSession.expiresAt).getTime() - Date.now();
    if (ms <= 0) return;
    const t = window.setTimeout(bump, Math.min(ms + 100, 86_400_000));
    return () => window.clearTimeout(t);
  }, [share.liveSession?.expiresAt]);

  const expiredLive = !!share.liveSession && !stillStreamingLive;

  if (expiredLive) {
    return (
      <div
        className="rounded-2xl border border-border/50 bg-muted/25 px-3 py-2.5 text-left text-sm leading-snug text-muted-foreground"
        style={{ maxWidth: CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX }}
      >
        {isCurrentUser ? (
          <>{t('chat.locationCard.liveEndedOwn')}</>
        ) : (
          <>{t('chat.locationCard.liveEndedOther')}</>
        )}
      </div>
    );
  }

  const openMap = () => setMapOpen(true);
  const liveExpiresAt = share.liveSession?.expiresAt ?? null;

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
            aria-label={t('chat.locationCard.openMap')}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={share.staticMapUrl}
              alt={t('chat.locationCard.mapAlt')}
              className="h-auto w-full max-h-[180px] object-cover bg-muted"
              loading="lazy"
            />
            {liveExpiresAt ? (
              <div className="pointer-events-none absolute bottom-2 left-2">
                <LocationLiveCountdown compact expiresAtIso={liveExpiresAt} />
              </div>
            ) : null}
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
            className={cn(
              'relative flex w-full min-h-[6.75rem] items-center gap-2 px-3 py-3 pr-14 text-left',
              'text-sm text-muted-foreground focus:outline-none focus-visible:ring-2 focus-visible:ring-ring',
              'focus-visible:ring-offset-2 focus-visible:ring-offset-background',
            )}
            aria-label={t('chat.locationCard.openMap')}
          >
            <MapPin className="h-5 w-5 shrink-0 text-primary" />
            <span className="min-w-0">
              <span className="font-medium text-foreground">{t('chat.locationCard.locationLabel')}</span>
              {share.accuracyM != null ? (
                <span className="mt-0.5 block text-[11px] opacity-80">
                  {t('chat.locationCard.accuracyMeters', { accuracy: Math.round(share.accuracyM) })}
                </span>
              ) : null}
            </span>
            {liveExpiresAt ? (
              <span className="pointer-events-none absolute bottom-2 left-2">
                <LocationLiveCountdown compact expiresAtIso={liveExpiresAt} />
              </span>
            ) : null}
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
        liveExpiresAt={liveExpiresAt}
      />
    </>
  );
}
