'use client';

import { useEffect, useState } from 'react';
import type { ChatAttachment } from '@/lib/types';
import { isHeicHeifAttachment, fetchUrlAndConvertHeicToPngObjectUrl } from '@/lib/heic-heif-convert';
import { useElectronCachedUrl } from '@/hooks/use-electron-cached-url';
import { isElectron } from '@/lib/utils';

const resolvedHeicDisplayUrlCache = new Map<string, string>();
const inFlightHeicDisplayUrlCache = new Map<string, Promise<string | null>>();

/**
 * Для HEIC/HEIF возвращает object URL сконвертированного PNG после загрузки;
 * иначе — исходный `att.url`.
 */
export function useChatAttachmentDisplaySrc(att: ChatAttachment | null | undefined): string {
  const rawUrl = att?.url ?? '';
  const cachedUrl = useElectronCachedUrl(att?.url);
  const [src, setSrc] = useState(() => {
    const initialUrl = cachedUrl || rawUrl;
    return resolvedHeicDisplayUrlCache.get(initialUrl) ?? initialUrl;
  });

  useEffect(() => {
    if (!att?.url) {
      setSrc('');
      return;
    }

    const isHeic = isHeicHeifAttachment(att);
    const preferredUrl = cachedUrl || att.url;
    const cachedHeicDisplayUrl = resolvedHeicDisplayUrlCache.get(preferredUrl);
    setSrc(cachedHeicDisplayUrl ?? preferredUrl);
    if (!isHeic) return;

    if (cachedHeicDisplayUrl) return;

    // In Electron we wait for protocol-backed cached URL to avoid Firebase CORS limits.
    if (isElectron() && !cachedUrl) return;

    let cancelled = false;

    void (async () => {
      let inFlight = inFlightHeicDisplayUrlCache.get(preferredUrl);
      if (!inFlight) {
        inFlight = fetchUrlAndConvertHeicToPngObjectUrl(preferredUrl);
        inFlightHeicDisplayUrlCache.set(preferredUrl, inFlight);
      }

      const objectUrl = await inFlight;
      if (cancelled || !objectUrl) return;

      resolvedHeicDisplayUrlCache.set(preferredUrl, objectUrl);
      setSrc(objectUrl);
    })().finally(() => {
      inFlightHeicDisplayUrlCache.delete(preferredUrl);
    });

    return () => {
      cancelled = true;
    };
  }, [att?.url, att?.name, att?.type, cachedUrl]);

  return src;
}
