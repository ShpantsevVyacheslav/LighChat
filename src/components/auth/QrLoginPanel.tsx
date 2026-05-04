'use client';

/**
 * Панель QR-входа на экране авторизации (Telegram-style).
 *
 *  - Запрашивает у сервера sessionId+nonce, кодирует в QR.
 *  - Подписывается на `qrLoginSessions/{sessionId}` через Firestore.
 *  - При state='approved' — забирает customToken, делает signInWithCustomToken,
 *    удаляет документ.
 *  - Авторефреш QR за 5 секунд до истечения TTL (≈55 секунд).
 *
 * Криптографически собственный ключ устройства: используем уже существующий
 * `getOrCreateDeviceIdentityV2()`, чей publicKeySpki передаётся серверу. После
 * успешного signIn это устройство будет видно в `e2eeDevices/{deviceId}` как
 * самостоятельная единица; история E2EE-чатов догрузится в фоне (см.
 * `device-handover.ts`, который запустит старое устройство по подтверждению).
 */

import * as React from 'react';
import { QRCodeCanvas } from 'qrcode.react';
import { Loader2, RefreshCw, ScanLine, ShieldCheck } from 'lucide-react';
import { signInWithCustomToken } from 'firebase/auth';

import { useFirebaseApp, useFirestore, useAuth as useFirebaseAuth } from '@/firebase';
import { useI18n } from '@/hooks/use-i18n';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import {
  buildLoginQrEncodedPayload,
  deleteQrLoginSession,
  requestQrLoginSession,
  watchQrLoginSession,
  type QrLoginSessionDoc,
  type RequestQrLoginResponse,
} from '@/lib/qr-login/client';
import { getOrCreateDeviceIdentityV2 } from '@/lib/e2ee/v2/device-identity-v2';

function detectPlatform(): 'web' | 'ios' | 'android' {
  if (typeof navigator === 'undefined') return 'web';
  const ua = navigator.userAgent || '';
  if (/(iPhone|iPad|iPod)/i.test(ua)) return 'ios';
  if (/Android/i.test(ua)) return 'android';
  return 'web';
}

function buildDefaultLabel(): string {
  if (typeof navigator === 'undefined') return 'web-browser';
  const ua = navigator.userAgent || '';
  const platform = detectPlatform();
  // Возьмём короткий «Chrome/macOS» — достаточно для UX подтверждения.
  const browserMatch = ua.match(/(Chrome|Firefox|Safari|Edge|OPR)\/[\d.]+/);
  const browser = browserMatch ? browserMatch[1] : 'Browser';
  return `${browser} / ${platform}`;
}

type Phase =
  | { kind: 'loading' }
  | { kind: 'ready'; resp: RequestQrLoginResponse; encoded: string }
  | { kind: 'approving' }
  | { kind: 'rejected' }
  | { kind: 'error'; message: string };

export type QrLoginPanelProps = {
  className?: string;
  onOtherMethodClick?: () => void;
  onSignedIn?: () => void;
};

export function QrLoginPanel({ className, onOtherMethodClick, onSignedIn }: QrLoginPanelProps) {
  const firebaseApp = useFirebaseApp();
  const firestore = useFirestore();
  const auth = useFirebaseAuth();
  const { t } = useI18n();

  const [phase, setPhase] = React.useState<Phase>({ kind: 'loading' });
  const [secondsLeft, setSecondsLeft] = React.useState<number>(0);

  const refreshTimeoutRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  const tickerRef = React.useRef<ReturnType<typeof setInterval> | null>(null);
  const unsubRef = React.useRef<(() => void) | null>(null);
  const sessionIdRef = React.useRef<string | null>(null);
  const consumingRef = React.useRef<boolean>(false);

  const cleanupListeners = React.useCallback(() => {
    if (unsubRef.current) {
      unsubRef.current();
      unsubRef.current = null;
    }
    if (refreshTimeoutRef.current) {
      clearTimeout(refreshTimeoutRef.current);
      refreshTimeoutRef.current = null;
    }
    if (tickerRef.current) {
      clearInterval(tickerRef.current);
      tickerRef.current = null;
    }
  }, []);

  const handleApprovedSession = React.useCallback(
    async (data: QrLoginSessionDoc) => {
      if (consumingRef.current) return;
      if (!data.customToken || !auth) return;
      consumingRef.current = true;
      setPhase({ kind: 'approving' });
      try {
        await signInWithCustomToken(auth, data.customToken);
        if (firestore) {
          await deleteQrLoginSession(firestore, data.sessionId);
        }
        cleanupListeners();
        onSignedIn?.();
      } catch (e) {
        consumingRef.current = false;
        setPhase({
          kind: 'error',
          message: e instanceof Error ? e.message : String(e),
        });
      }
    },
    [auth, firestore, cleanupListeners, onSignedIn]
  );

  const startSession = React.useCallback(async () => {
    cleanupListeners();
    consumingRef.current = false;
    setPhase({ kind: 'loading' });
    try {
      const id = await getOrCreateDeviceIdentityV2();
      const resp = await requestQrLoginSession({
        firebaseApp,
        ephemeralPubKeySpki: id.publicKeySpkiB64,
        devicePlatform: detectPlatform(),
        deviceLabel: buildDefaultLabel(),
        deviceId: id.deviceId,
      });
      const encoded = buildLoginQrEncodedPayload(resp);
      sessionIdRef.current = resp.sessionId;

      // Listener
      unsubRef.current = watchQrLoginSession(firestore, resp.sessionId, (doc) => {
        if (!doc) return;
        if (doc.state === 'approved') {
          void handleApprovedSession(doc);
        } else if (doc.state === 'rejected') {
          setPhase({ kind: 'rejected' });
          // Авторефреш QR через 2 секунды.
          refreshTimeoutRef.current = setTimeout(() => {
            void startSession();
          }, 2000);
        }
      });

      // Tick
      const expiresAtMs = new Date(resp.expiresAt).getTime();
      const refreshAtMs = Math.max(Date.now() + 5000, expiresAtMs - 5000);
      const tick = () => {
        const left = Math.max(0, Math.floor((expiresAtMs - Date.now()) / 1000));
        setSecondsLeft(left);
      };
      tick();
      tickerRef.current = setInterval(tick, 1000);

      // Авторефреш
      refreshTimeoutRef.current = setTimeout(() => {
        void startSession();
      }, Math.max(1000, refreshAtMs - Date.now()));

      setPhase({ kind: 'ready', resp, encoded });
    } catch (e) {
      setPhase({
        kind: 'error',
        message: e instanceof Error ? e.message : String(e),
      });
    }
  }, [firebaseApp, firestore, cleanupListeners, handleApprovedSession]);

  React.useEffect(() => {
    void startSession();
    return () => {
      cleanupListeners();
    };
    // startSession уже мемоизирован.
  }, [startSession, cleanupListeners]);

  return (
    <div className={cn('flex flex-col items-center gap-4', className)}>
      <div className="text-center space-y-1">
        <h2 className="text-base font-semibold text-slate-800 dark:text-white/90">
          {t('auth.qr.title')}
        </h2>
        <p className="text-xs text-slate-600 dark:text-white/55 max-w-[18rem] mx-auto leading-snug">
          {t('auth.qr.hint')}
        </p>
      </div>

      <div className="relative w-[208px] h-[208px] flex items-center justify-center rounded-[20px] border border-white/55 bg-white/55 shadow-inner shadow-black/5 backdrop-blur-md p-3 dark:border-white/15 dark:bg-white/[0.08]">
        {phase.kind === 'loading' && (
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
        )}
        {phase.kind === 'ready' && (
          <>
            <QRCodeCanvas
              value={phase.encoded}
              size={184}
              includeMargin={false}
              level="M"
              bgColor="transparent"
              fgColor="currentColor"
              className="text-slate-900 dark:text-white"
            />
            {/* Анимированная рамка-«сканлайн» — чисто декоративная */}
            <div className="pointer-events-none absolute inset-2 rounded-[14px] border border-primary/40 animate-pulse" />
          </>
        )}
        {phase.kind === 'approving' && (
          <div className="flex flex-col items-center gap-2 text-center text-xs text-slate-700 dark:text-white/75">
            <ShieldCheck className="h-7 w-7 text-emerald-500" />
            <span>{t('auth.qr.approving')}</span>
          </div>
        )}
        {phase.kind === 'rejected' && (
          <div className="flex flex-col items-center gap-2 text-center text-xs text-slate-700 dark:text-white/75">
            <ScanLine className="h-7 w-7 text-amber-500" />
            <span>{t('auth.qr.rejected')}</span>
          </div>
        )}
        {phase.kind === 'error' && (
          <div className="flex flex-col items-center gap-2 text-center text-[11px] text-destructive max-w-[170px]">
            <span>{phase.message}</span>
            <Button
              size="sm"
              variant="outline"
              onClick={() => void startSession()}
              className="h-7 px-2"
            >
              <RefreshCw className="h-3 w-3 mr-1" /> {t('auth.qr.retry')}
            </Button>
          </div>
        )}
      </div>

      {phase.kind === 'ready' && secondsLeft > 0 && (
        <p className="text-[10px] uppercase tracking-wide text-slate-500/80 dark:text-white/45">
          {t('auth.qr.refreshIn', { sec: String(secondsLeft) })}
        </p>
      )}

      {onOtherMethodClick && (
        <Button
          type="button"
          variant="ghost"
          onClick={onOtherMethodClick}
          className="h-9 rounded-full text-xs font-semibold text-primary hover:bg-primary/10 dark:text-sky-300 dark:hover:bg-white/10 dark:hover:text-sky-200"
        >
          {t('auth.qr.otherMethod')}
        </Button>
      )}
    </div>
  );
}
