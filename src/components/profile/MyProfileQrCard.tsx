'use client';

import * as React from 'react';
import { QRCodeCanvas } from 'qrcode.react';
import { Copy, QrCode } from 'lucide-react';

import { buildProfileQrPayload } from '@/lib/profile-qr-link';
import { Button } from '@/components/ui/button';
import { useI18n } from '@/hooks/use-i18n';

export function MyProfileQrCard(props: { userId: string; username?: string | null }) {
  const { t } = useI18n();
  const payload = React.useMemo(
    () => buildProfileQrPayload({ userId: props.userId, username: props.username }),
    [props.userId, props.username]
  );

  const canShow = payload.trim().length > 0;

  return (
    <div className="rounded-2xl border border-border/60 bg-background/60 p-4 sm:p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <QrCode className="h-5 w-5 text-primary" aria-hidden />
            <div className="text-base font-semibold">{t('profile.qrCard.title')}</div>
          </div>
          <div className="mt-1 text-xs text-muted-foreground">
            {t('profile.qrCard.description')}
          </div>
        </div>

        <Button
          type="button"
          variant="outline"
          size="sm"
          className="shrink-0 gap-2 rounded-xl"
          disabled={!canShow}
          onClick={async () => {
            if (!canShow) return;
            await navigator.clipboard.writeText(payload);
          }}
        >
          <Copy className="h-4 w-4" aria-hidden />
          {t('profile.qrCard.copyLink')}
        </Button>
      </div>

      <div className="mt-4 flex flex-col items-center gap-3">
        <div className="relative rounded-2xl border border-border/60 bg-white p-3">
          <QRCodeCanvas value={payload} size={210} includeMargin level="H" />
          <div className="pointer-events-none absolute left-1/2 top-1/2 h-10 w-10 -translate-x-1/2 -translate-y-1/2 rounded-[10px] bg-white" />
          <div className="pointer-events-none absolute left-1/2 top-1/2 h-8 w-8 -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-full bg-[#1E3A5F] p-[3px] shadow-[0_1px_6px_rgba(0,0,0,0.4)]">
            <img src="/brand/lighchat-mark.png" alt="" className="h-full w-full object-contain" />
          </div>
        </div>
        <div className="max-w-full truncate text-center text-xs text-muted-foreground">{payload}</div>
      </div>
    </div>
  );
}
