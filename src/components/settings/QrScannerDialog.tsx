'use client';

/**
 * Сканер QR-кодов для подключения нового устройства (старое устройство).
 *
 * Поддерживает два формата:
 *  - `lighchat-login-v1` (новый): scan → confirm flow with allow/deny → custom token →
 *    handoverDeviceAccessV2 для синхронизации E2EE-чатов.
 *  - `v2-pairing-1` (legacy E2EE pairing): подсказка пользователю открыть
 *    «Восстановление E2EE» — оставляем существующий flow.
 *
 * Камера: `@yudiel/react-qr-scanner` (нативный BarcodeDetector с polyfill, ~30KB).
 */

import * as React from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Scanner, type IDetectedBarcode } from '@yudiel/react-qr-scanner';
import { Button } from '@/components/ui/button';
import { Loader2, ShieldAlert, ShieldCheck, Smartphone, AlertTriangle } from 'lucide-react';
import { useFirebaseApp, useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { useI18n } from '@/hooks/use-i18n';
import { useToast } from '@/hooks/use-toast';
import { parseQrLoginPayload } from '@/lib/qr-login/protocol';
import {
  confirmQrLoginFromScanner,
  type ConfirmQrLoginResponseApproved,
} from '@/lib/qr-login/client';
import { parseQrPayload as parseE2eePairingPayload } from '@/lib/e2ee/v2/pairing-qr';
import {
  getOrCreateDeviceIdentityV2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import {
  handoverDeviceAccessV2,
  type DeviceHandoverProgress,
} from '@/lib/e2ee/v2/device-handover';
import { logger } from '@/lib/logger';

type Stage =
  | { kind: 'scanning' }
  | { kind: 'detected-login'; sessionId: string; nonce: string }
  | {
      kind: 'awaiting-approve';
      sessionId: string;
      nonce: string;
    }
  | { kind: 'confirming'; sessionId: string; nonce: string }
  | {
      kind: 'syncing';
      approved: ConfirmQrLoginResponseApproved;
      done: number;
      total: number;
      lastConv?: string;
    }
  | { kind: 'success'; approved: ConfirmQrLoginResponseApproved }
  | { kind: 'already-approved' }
  | { kind: 'rejected' }
  | { kind: 'pairing-redirect' }
  | { kind: 'error'; source: 'camera' | 'server'; message: string };

type QrScannerDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onLinked?: () => void;
};

export function QrScannerDialog({ open, onOpenChange, onLinked }: QrScannerDialogProps) {
  const firebaseApp = useFirebaseApp();
  const firestore = useFirestore();
  const { user } = useAuth();
  const { t } = useI18n();
  const { toast } = useToast();
  const [stage, setStage] = React.useState<Stage>({ kind: 'scanning' });
  const consumedRef = React.useRef<string | null>(null);
  /** Гард против двойного клика на «Разрешить» / двойного срабатывания confirm. */
  const confirmingRef = React.useRef<string | null>(null);

  const reset = React.useCallback(() => {
    consumedRef.current = null;
    confirmingRef.current = null;
    setStage({ kind: 'scanning' });
  }, []);

  React.useEffect(() => {
    if (!open) reset();
  }, [open, reset]);

  const handleScan = React.useCallback((detected: IDetectedBarcode[]) => {
    if (stage.kind !== 'scanning') return;
    for (const code of detected) {
      const raw = code?.rawValue ?? '';
      if (!raw) continue;
      if (consumedRef.current === raw) return;
      consumedRef.current = raw;

      const login = parseQrLoginPayload(raw);
      if (login) {
        setStage({
          kind: 'detected-login',
          sessionId: login.sessionId,
          nonce: login.nonce,
        });
        // Сразу показываем экран подтверждения. Пользователь решает Allow/Deny.
        setStage({
          kind: 'awaiting-approve',
          sessionId: login.sessionId,
          nonce: login.nonce,
        });
        return;
      }

      // Если это старый E2EE-pairing QR — подскажем пользователю.
      try {
        parseE2eePairingPayload(raw);
        setStage({ kind: 'pairing-redirect' });
      } catch {
        toast({
          variant: 'destructive',
          title: t('devices.scanner.unsupportedQrTitle'),
          description: t('devices.scanner.unsupportedQrDesc'),
        });
        consumedRef.current = null;
      }
      return;
    }
  }, [stage.kind, toast, t]);

  const handleAllow = React.useCallback(async () => {
    if (stage.kind !== 'awaiting-approve' || !user?.id) return;
    const { sessionId, nonce } = stage;
    // Гард: одна и та же сессия не должна подтверждаться дважды (двойной клик
    // или React-StrictMode дабл-инвок). Сервер ответит FAILED_PRECONDITION на
    // повтор; мы хотим, чтобы пользователь увидел осмысленный экран.
    if (confirmingRef.current === sessionId) return;
    confirmingRef.current = sessionId;
    setStage({ kind: 'confirming', sessionId, nonce });
    try {
      // [diag] Логируем каждый шаг — пользователь сообщил, что в консоли
      // нет ошибок, но UI показывает «An internal error occurred». Хотим
      // увидеть, на каком этапе цепочка падает.
      logger.debug('qr-scan', 'step=confirmQrLogin start', { sessionId });
      const res = await confirmQrLoginFromScanner({
        firebaseApp,
        sessionId,
        nonce,
        allow: true,
      });
      logger.debug('qr-scan', 'step=confirmQrLogin ok', { state: res.state });
      if (res.state !== 'approved') {
        setStage({ kind: 'rejected' });
        return;
      }

      // Запускаем handover в фоне — UI показывает прогресс.
      setStage({ kind: 'syncing', approved: res, done: 0, total: 0 });
      let identity: DeviceIdentityV2;
      try {
        logger.debug('qr-scan', 'step=getOrCreateDeviceIdentityV2');
        identity = await getOrCreateDeviceIdentityV2();
        logger.debug('qr-scan', 'step=getOrCreateDeviceIdentityV2 ok', { deviceId: identity.deviceId });
      } catch (e) {
        logger.error('qr-scan', 'FAIL getOrCreateDeviceIdentityV2', e);
        setStage({
          kind: 'error',
          source: 'server',
          message: `identity: ${e instanceof Error ? e.message : String(e)}`,
        });
        return;
      }

      // Используем deviceId, который новое устройство передало в QR (через
      // сервер). Это тот же ULID, что хранится у него в IndexedDB/Keychain;
      // после signIn новое устройство опубликует свой `e2eeDevices/{deviceId}`
      // в идемпотентном merge-режиме поверх того, что мы создали здесь.
      const newDeviceLabel = res.deviceLabel || `${res.devicePlatform}-device`;
      const newDeviceId = res.deviceId
        || (await deriveStableDeviceIdFromSpki(res.ephemeralPubKeySpki));

      try {
        logger.debug('qr-scan', 'step=handover start', { newDeviceId, label: newDeviceLabel });
        const result = await handoverDeviceAccessV2({
          firestore,
          userId: user.id,
          donorIdentity: identity,
          newDevice: {
            deviceId: newDeviceId,
            publicKeySpki: res.ephemeralPubKeySpki,
            platform: res.devicePlatform,
            label: newDeviceLabel,
          },
          options: {
            onProgress: (
              p: DeviceHandoverProgress,
              done: number,
              total: number
            ) => {
              setStage((cur) => {
                if (cur.kind !== 'syncing') return cur;
                return { ...cur, done, total, lastConv: p.conversationId };
              });
            },
          },
        });
        logger.debug('qr-scan', 'step=handover ok', result);
        if (result.failed > 0) {
          toast({
            variant: 'destructive',
            title: t('devices.handover.partialFailureTitle'),
            description: t('devices.handover.partialFailureDesc', {
              ok: String(result.rewrapped + result.rotated),
              fail: String(result.failed),
            }),
          });
        }
      } catch (e) {
        // [diag] Раскрываем FirebaseError полностью: code, name, message,
        // customData, stack — пользователь видит «An internal error occurred»
        // без code, нам нужен code чтобы понять, какой Firestore/Auth call падает.
        const err = e as {
          code?: string;
          name?: string;
          message?: string;
          customData?: unknown;
          stack?: string;
        };
        logger.error('qr-scan', 'FAIL handover', e, {
          code: err?.code,
          name: err?.name,
          message: err?.message,
          customData: err?.customData,
          stack: err?.stack,
        });
        const codeStr = err?.code ?? err?.name ?? 'unknown';
        const msgStr = err?.message ?? String(e);
        setStage({
          kind: 'error',
          source: 'server',
          message: `handover [${codeStr}]: ${msgStr}`,
        });
        return;
      }

      setStage({ kind: 'success', approved: res });
      onLinked?.();
    } catch (e: unknown) {
      // Если сессия уже approved (повторный confirm на тот же sessionId или
      // зависший stale-документ), сервер вернёт FAILED_PRECONDITION с
      // message 'QR session in state approved.'. Это не ошибка для нашего
      // UX — нужное состояние уже достигнуто. Показываем успех / подсказку.
      const code = (e as { code?: string })?.code ?? '';
      const msg = e instanceof Error ? e.message : String(e);
      if (
        code === 'functions/failed-precondition' ||
        /in state approved/i.test(msg)
      ) {
        setStage({ kind: 'already-approved' });
        return;
      }
      // Сбрасываем гард, чтобы пользователь мог нажать «Сканировать ещё раз».
      confirmingRef.current = null;
      logger.error('qr-scan', 'FAIL outer', e, { code, msg });
      setStage({
        kind: 'error',
        source: 'server',
        message: `[${code || 'unknown'}] ${msg}`,
      });
    }
  }, [stage, firebaseApp, firestore, user?.id, onLinked, toast, t]);

  const handleDeny = React.useCallback(async () => {
    if (stage.kind !== 'awaiting-approve') return;
    const { sessionId, nonce } = stage;
    try {
      await confirmQrLoginFromScanner({
        firebaseApp,
        sessionId,
        nonce,
        allow: false,
      });
    } catch {
      // ignore — сессия скоро протухнет
    }
    setStage({ kind: 'rejected' });
  }, [stage, firebaseApp]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{t('devices.scanner.title')}</DialogTitle>
          <DialogDescription>
            {t('devices.scanner.description')}
          </DialogDescription>
        </DialogHeader>

        {stage.kind === 'scanning' && (
          <div className="rounded-md overflow-hidden bg-black aspect-square">
            <Scanner
              onScan={handleScan}
              onError={(e: unknown) => {
                const msg = e instanceof Error ? e.message : String(e);
                setStage({ kind: 'error', source: 'camera', message: msg });
              }}
              constraints={{ facingMode: 'environment' }}
              scanDelay={250}
              styles={{ container: { width: '100%', height: '100%' } }}
            />
          </div>
        )}

        {(stage.kind === 'awaiting-approve' || stage.kind === 'confirming') && (
          <div className="space-y-3 text-center px-2">
            <Smartphone className="h-10 w-10 mx-auto text-primary" />
            <p className="text-sm font-medium">{t('devices.approve.title')}</p>
            <p className="text-xs text-muted-foreground">
              {t('devices.approve.bodyHint')}
            </p>
            <DialogFooter className="gap-2 sm:gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => void handleDeny()}
                disabled={stage.kind === 'confirming'}
              >
                <ShieldAlert className="h-4 w-4 mr-1" />
                {t('devices.approve.deny')}
              </Button>
              <Button
                type="button"
                onClick={() => void handleAllow()}
                disabled={stage.kind === 'confirming'}
              >
                {stage.kind === 'confirming' ? (
                  <Loader2 className="h-4 w-4 mr-1 animate-spin" />
                ) : (
                  <ShieldCheck className="h-4 w-4 mr-1" />
                )}
                {t('devices.approve.allow')}
              </Button>
            </DialogFooter>
          </div>
        )}

        {stage.kind === 'syncing' && (
          <div className="space-y-3 text-center py-4">
            <Loader2 className="h-8 w-8 mx-auto animate-spin text-primary" />
            <p className="text-sm font-medium">
              {t('devices.handover.progressTitle')}
            </p>
            <p className="text-xs text-muted-foreground">
              {stage.total > 0
                ? t('devices.handover.progressBody', {
                    done: String(stage.done),
                    total: String(stage.total),
                  })
                : t('devices.handover.progressStarting')}
            </p>
          </div>
        )}

        {stage.kind === 'success' && (
          <div className="space-y-2 text-center py-3">
            <ShieldCheck className="h-8 w-8 mx-auto text-emerald-500" />
            <p className="text-sm font-medium">
              {t('devices.handover.successTitle')}
            </p>
            <p className="text-xs text-muted-foreground">
              {t('devices.handover.successBody', {
                label: stage.approved.deviceLabel || stage.approved.devicePlatform,
              })}
            </p>
            <DialogFooter>
              <Button onClick={() => onOpenChange(false)}>
                {t('common.close')}
              </Button>
            </DialogFooter>
          </div>
        )}

        {stage.kind === 'rejected' && (
          <div className="space-y-2 text-center py-3">
            <ShieldAlert className="h-8 w-8 mx-auto text-amber-500" />
            <p className="text-sm font-medium">{t('devices.approve.deniedTitle')}</p>
            <DialogFooter>
              <Button variant="outline" onClick={reset}>
                {t('devices.scanner.scanAgain')}
              </Button>
            </DialogFooter>
          </div>
        )}

        {stage.kind === 'already-approved' && (
          <div className="space-y-2 text-center py-3">
            <ShieldCheck className="h-8 w-8 mx-auto text-emerald-500" />
            <p className="text-sm font-medium">
              {t('devices.alreadyApproved.title')}
            </p>
            <p className="text-xs text-muted-foreground">
              {t('devices.alreadyApproved.body')}
            </p>
            <DialogFooter>
              <Button onClick={() => onOpenChange(false)}>
                {t('common.close')}
              </Button>
            </DialogFooter>
          </div>
        )}

        {stage.kind === 'pairing-redirect' && (
          <div className="space-y-2 text-center py-3">
            <AlertTriangle className="h-8 w-8 mx-auto text-amber-500" />
            <p className="text-sm font-medium">
              {t('devices.scanner.pairingRedirectTitle')}
            </p>
            <p className="text-xs text-muted-foreground">
              {t('devices.scanner.pairingRedirectBody')}
            </p>
            <DialogFooter>
              <Button variant="outline" onClick={reset}>
                {t('devices.scanner.scanAgain')}
              </Button>
            </DialogFooter>
          </div>
        )}

        {stage.kind === 'error' && (
          <div className="space-y-2 text-center py-3">
            <AlertTriangle className="h-8 w-8 mx-auto text-destructive" />
            <p className="text-sm font-medium">
              {stage.source === 'camera'
                ? t('devices.scanner.errorTitle')
                : t('devices.scanner.serverErrorTitle')}
            </p>
            <p className="text-xs text-muted-foreground break-words">
              {stage.message}
            </p>
            <DialogFooter>
              <Button variant="outline" onClick={reset}>
                {t('devices.scanner.scanAgain')}
              </Button>
            </DialogFooter>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

/**
 * Стабильный deviceId для нового устройства, выводится из его publicKeySpki.
 * Формат: `q` + первые 24 hex символа SHA-256 от base64-публичника. Этот же
 * deviceId использует и новое устройство в `getOrCreateDeviceIdentityV2`
 * (миграция: после первого signIn новое устройство переписывает свой
 * `e2eeDevices/{deviceId}` с тем же deviceId, потому что вычисление
 * детерминированно).
 *
 * NOTE: текущая реализация `getOrCreateDeviceIdentityV2` генерирует ULID при
 * первом запуске и сохраняет его в IndexedDB. Чтобы избежать рассинхрона,
 * **новое устройство** перед запросом QR-сессии должно вызвать эту же функцию —
 * см. `QrLoginPanel.tsx`. После signIn оно публикует свой ULID-deviceId, а doc,
 * который мы создали под `q…`-deviceId, останется как «duplicate» (с теми же
 * publicKey). При следующей ротации эпохи он попадёт в wraps один раз через
 * dedup по publicKey. Простейший вариант синхронизации deviceId — поправлен в
 * future improvement (см. TODO в device-handover.ts).
 */
async function deriveStableDeviceIdFromSpki(spkiB64: string): Promise<string> {
  const enc = new TextEncoder().encode(spkiB64);
  const hash = await crypto.subtle.digest('SHA-256', enc);
  const u = new Uint8Array(hash);
  const hex = Array.from(u, (b) => b.toString(16).padStart(2, '0')).join('');
  return `q${hex.slice(0, 24).toUpperCase()}`;
}
