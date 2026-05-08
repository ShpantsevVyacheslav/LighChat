'use client';

import React, { useEffect, useRef, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { MapPin, Loader2 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import type { ChatLocationSendMeta, ChatLocationShare } from '@/lib/types';
import { buildGoogleMapsPlaceUrl, buildGoogleStaticMapUrl } from '@/lib/google-maps';
import {
  GEOLOCATION_CLIENT_LOG,
  GeolocationUnsupportedError,
  geolocationErrorCodeName,
  requestCurrentPositionForShare,
} from '@/lib/geolocation-client';
import {
  LIVE_LOCATION_DURATION_OPTIONS,
  type LiveLocationDurationId,
  expiresAtForDurationId,
} from '@/lib/live-location-durations';

export type ChatLocationSharePayload = {
  share: ChatLocationShare;
  meta: ChatLocationSendMeta;
};

interface ChatAttachLocationDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onShare: (payload: ChatLocationSharePayload) => void | Promise<void>;
}

function geolocationErrorKey(err: GeolocationPositionError): string {
  if (err.code === 1) return 'chat.location.errorDenied';
  if (err.code === 2) return 'chat.location.errorUnavailable';
  return 'chat.location.errorTimeout';
}

function metaForDurationId(id: LiveLocationDurationId): ChatLocationSendMeta {
  if (id === 'once') return { kind: 'once' };
  return { kind: 'live', expiresAt: expiresAtForDurationId(id) };
}

export function ChatAttachLocationDialog({ open, onOpenChange, onShare }: ChatAttachLocationDialogProps) {
  const { t } = useI18n();
  const [loading, setLoading] = useState(false);
  const [durationId, setDurationId] = useState<LiveLocationDurationId>('once');
  const inFlightRef = useRef(false);
  const { toast } = useToast();

  useEffect(() => {
    if (!open) {
      setLoading(false);
      inFlightRef.current = false;
      setDurationId('once');
    }
  }, [open]);

  const requestAndShare = async () => {
    if (inFlightRef.current) {
      console.warn(GEOLOCATION_CLIENT_LOG, 'dialog.skip', { reason: 'запрос уже выполняется' });
      return;
    }
    inFlightRef.current = true;
    setLoading(true);
    try {
      const pos = await requestCurrentPositionForShare();
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const staticMapUrl = buildGoogleStaticMapUrl(lat, lng, 400, 200);
      const meta = metaForDurationId(durationId);
      console.log(GEOLOCATION_CLIENT_LOG, 'share.build', {
        mapsUrl: buildGoogleMapsPlaceUrl(lat, lng),
        staticMapPreview: staticMapUrl ? 'есть (Static Maps)' : 'нет (без ключа или ошибка сборки URL)',
        mode: meta.kind,
        liveExpiresAt: meta.kind === 'live' ? meta.expiresAt : undefined,
      });

      const share: ChatLocationShare = {
        lat,
        lng,
        accuracyM: pos.coords.accuracy,
        mapsUrl: buildGoogleMapsPlaceUrl(lat, lng),
        staticMapUrl,
        capturedAt: new Date().toISOString(),
        ...(meta.kind === 'live' ? { liveSession: { expiresAt: meta.expiresAt } } : {}),
      };

      console.log(GEOLOCATION_CLIENT_LOG, 'onShare.invoke');
      try {
        await onShare({ share, meta });
        console.log(GEOLOCATION_CLIENT_LOG, 'onShare.done');
        onOpenChange(false);
      } catch (e) {
        console.error(GEOLOCATION_CLIENT_LOG, 'onShare.failed', e);
        toast({ variant: 'destructive', title: t('chat.location.sendFailed') });
      }
    } catch (e) {
      if (e instanceof GeolocationUnsupportedError) {
        toast({ variant: 'destructive', title: t('chat.location.notSupported') });
      } else {
        const err = e as GeolocationPositionError;
        if (typeof err?.code === 'number') {
          console.error(GEOLOCATION_CLIENT_LOG, 'final.failure', {
            code: err.code,
            codeName: geolocationErrorCodeName(err.code),
            message: err.message,
          });
          toast({ variant: 'destructive', title: t(geolocationErrorKey(err)) });
        } else {
          console.error(GEOLOCATION_CLIENT_LOG, 'unexpected', e);
          toast({ variant: 'destructive', title: t('chat.location.errorGeneric') });
        }
      }
    } finally {
      inFlightRef.current = false;
      setLoading(false);
      console.log(GEOLOCATION_CLIENT_LOG, 'dialog.loading.off');
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) {
          inFlightRef.current = false;
          setLoading(false);
        }
        onOpenChange(v);
      }}
    >
      <DialogContent className="max-h-[min(90vh,640px)] overflow-y-auto rounded-2xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-primary" />
            {t('chat.location.shareTitle')}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-2 py-1">
          <Label htmlFor="location-share-mode" className="text-sm font-semibold">
            {t('chat.location.shareMode')}
          </Label>
          <Select
            value={durationId}
            onValueChange={(v) => setDurationId(v as LiveLocationDurationId)}
            disabled={loading}
          >
            <SelectTrigger
              id="location-share-mode"
              className="w-full rounded-xl border-0 bg-muted/40 shadow-none ring-offset-background focus:ring-2 focus:ring-ring focus:ring-offset-2"
            >
              <SelectValue placeholder={t('chat.location.selectMode')} />
            </SelectTrigger>
            <SelectContent className="z-[200] max-h-[min(60vh,320px)] rounded-xl border-0 shadow-lg">
              {LIVE_LOCATION_DURATION_OPTIONS.map((opt) => (
                <SelectItem key={opt.id} value={opt.id} className="rounded-lg py-2.5 text-left leading-snug">
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <DialogFooter className="gap-2 sm:gap-0">
          <Button
            type="button"
            variant="ghost"
            onClick={() => {
              inFlightRef.current = false;
              setLoading(false);
              onOpenChange(false);
            }}
          >
            {t('common.cancel')}
          </Button>
          <Button type="button" onClick={() => void requestAndShare()} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <MapPin className="mr-2 h-4 w-4" />}
            {t('chat.location.send')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
