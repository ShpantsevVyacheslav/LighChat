'use client';

import { useEffect, useState } from 'react';
import type { ChatAttachment } from '@/lib/types';
import { isHeicHeifAttachment, fetchUrlAndConvertHeicToPngObjectUrl } from '@/lib/heic-heif-convert';

/**
 * Для HEIC/HEIF возвращает object URL сконвертированного PNG после загрузки;
 * иначе — исходный `att.url`.
 */
export function useChatAttachmentDisplaySrc(att: ChatAttachment | null | undefined): string {
  const rawUrl = att?.url ?? '';
  const [src, setSrc] = useState(rawUrl);

  useEffect(() => {
    if (!att?.url) {
      setSrc('');
      return;
    }
    setSrc(att.url);
    if (!isHeicHeifAttachment(att)) return;

    let revoked: string | null = null;
    let cancelled = false;

    void (async () => {
      const objectUrl = await fetchUrlAndConvertHeicToPngObjectUrl(att.url);
      if (cancelled || !objectUrl) return;
      revoked = objectUrl;
      setSrc(objectUrl);
    })();

    return () => {
      cancelled = true;
      if (revoked) URL.revokeObjectURL(revoked);
    };
  }, [att?.url, att?.name, att?.type]);

  return src;
}
