'use client';

import { useEffect, useState } from 'react';
import type { ChatAttachment } from '@/lib/types';
import { isHeicHeifAttachment, fetchUrlAndConvertHeicToPngObjectUrl } from '@/lib/heic-heif-convert';

const resolvedHeicDisplayUrlCache = new Map<string, string>();
const inFlightHeicDisplayUrlCache = new Map<string, Promise<string | null>>();

/**
 * Для HEIC/HEIF возвращает object URL сконвертированного PNG после загрузки;
 * иначе — исходный `att.url`.
 *
 * Раньше дополнительно проходил через `useElectronCachedUrl` для подмены на
 * `lighchat-media://...` локальный кэш — после декомиссии Electron-shell
 * (desktop теперь Flutter) этот путь убран; HEIC конвертится напрямую из
 * Firebase Storage URL, поддержка Storage CORS обязательна.
 */
export function useChatAttachmentDisplaySrc(att: ChatAttachment | null | undefined): string {
  const rawUrl = att?.url ?? '';
  const [src, setSrc] = useState(() => resolvedHeicDisplayUrlCache.get(rawUrl) ?? rawUrl);

  useEffect(() => {
    if (!att?.url) {
      setSrc('');
      return;
    }

    const isHeic = isHeicHeifAttachment(att);
    const cachedHeicDisplayUrl = resolvedHeicDisplayUrlCache.get(att.url);
    setSrc(cachedHeicDisplayUrl ?? att.url);
    if (!isHeic) return;
    if (cachedHeicDisplayUrl) return;

    let cancelled = false;

    void (async () => {
      let inFlight = inFlightHeicDisplayUrlCache.get(att.url!);
      if (!inFlight) {
        inFlight = fetchUrlAndConvertHeicToPngObjectUrl(att.url!);
        inFlightHeicDisplayUrlCache.set(att.url!, inFlight);
      }

      const objectUrl = await inFlight;
      if (cancelled || !objectUrl) return;

      resolvedHeicDisplayUrlCache.set(att.url!, objectUrl);
      setSrc(objectUrl);
    })().finally(() => {
      inFlightHeicDisplayUrlCache.delete(att.url!);
    });

    return () => {
      cancelled = true;
    };
  }, [att?.url, att?.name, att?.type, att]);

  return src;
}
