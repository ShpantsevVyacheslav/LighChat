'use client';

/**
 * QR-pairing UI для E2EE v2 (Phase 9 gap #1, web).
 *
 * Изолированный диалог, накрывает два сценария:
 *  1. Initiator (новое устройство) — генерит сессию, рендерит QR, ждёт donor.
 *     После получения donor-payload показывает 6-значный код сверки; при
 *     подтверждении записывает полученный PKCS#8 в локальный IndexedDB, и
 *     фиксирует Firestore-сессию как `completed`.
 *  2. Donor (старое устройство с ключом) — принимает QR-строку (камера на web
 *     не используется, чтобы не тащить ещё одну зависимость), расшифровывает
 *     приватник под общий AES и кладёт обратно в документ. Пользователь
 *     вручную сверяет 6-значный код.
 *
 * Протокол живёт в `src/lib/e2ee/v2/pairing-qr.ts` и полностью идентичен
 * mobile. Документ — `users/{uid}/e2eePairingSessions/{id}`. Видимость — только
 * для владельца, контролирует firestore.rules.
 *
 * Зависимости: `qrcode.react` (16 KB gzip) — чистый canvas-рендер без камеры.
 *
 * Этот компонент не трогает существующую `E2eeRecoveryPanel`; подключать
 * предлагается отдельной кнопкой.
 */

import * as React from 'react';
import { QRCodeCanvas } from 'qrcode.react';
import { doc, getDoc } from 'firebase/firestore';
import { useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { useToast } from '@/hooks/use-toast';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2, Copy, Check } from 'lucide-react';
import {
  initiatePairingSessionV2,
  watchPairingSessionV2,
  consumeDonorPayloadV2,
  donorRespondToPairingV2,
  rejectPairingSessionV2,
  parseQrPayload,
  getOrCreateDeviceIdentityV2,
  readStoredIdentityPkcs8V2,
  replaceIdentityFromBackupV2,
  type InitiatorSession,
  type PairingQrPayload,
} from '@/lib/e2ee';
import { useI18n } from '@/hooks/use-i18n';
import type { E2eePairingSessionDocV2 } from '@/lib/types';

type Mode = 'pick' | 'initiator' | 'donor';
type InitiatorStage = 'waiting' | 'awaiting-accept' | 'completed' | 'error';
type DonorStage = 'input' | 'confirming' | 'done' | 'error';

export function E2eeQrPairingDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const firestore = useFirestore();
  const { user } = useAuth();
  const { toast } = useToast();
  const { t } = useI18n();

  const [mode, setMode] = React.useState<Mode>('pick');
  // Initiator state
  const [initSession, setInitSession] = React.useState<InitiatorSession | null>(null);
  const [initStage, setInitStage] = React.useState<InitiatorStage>('waiting');
  const [initCode, setInitCode] = React.useState<string | null>(null);
  const [initBusy, setInitBusy] = React.useState(false);
  const [initError, setInitError] = React.useState<string | null>(null);
  const [donorDocSnapshot, setDonorDocSnapshot] = React.useState<E2eePairingSessionDocV2 | null>(
    null
  );
  // Donor state
  const [donorQrString, setDonorQrString] = React.useState('');
  const [donorStage, setDonorStage] = React.useState<DonorStage>('input');
  const [donorCode, setDonorCode] = React.useState<string | null>(null);
  const [donorError, setDonorError] = React.useState<string | null>(null);
  const [copied, setCopied] = React.useState(false);

  // Корректный cleanup: initiator должен отменить сессию, если диалог закрыли до завершения.
  // Держим session id в ref, чтобы не зависеть от состояния на размонтировании.
  const sessionToCleanupRef = React.useRef<{ sessionId: string; userId: string } | null>(null);

  const resetAll = React.useCallback(() => {
    setMode('pick');
    setInitSession(null);
    setInitStage('waiting');
    setInitCode(null);
    setInitBusy(false);
    setInitError(null);
    setDonorDocSnapshot(null);
    setDonorQrString('');
    setDonorStage('input');
    setDonorCode(null);
    setDonorError(null);
    setCopied(false);
  }, []);

  const handleClose = React.useCallback(() => {
    // Если диалог закрыли без завершения — отменяем сессию.
    const cleanup = sessionToCleanupRef.current;
    if (cleanup && firestore) {
      void rejectPairingSessionV2(firestore, cleanup.userId, cleanup.sessionId).catch(() => {
        /* silent — idempotent */
      });
    }
    sessionToCleanupRef.current = null;
    resetAll();
    onOpenChange(false);
  }, [firestore, onOpenChange, resetAll]);

  // ---------- INITIATOR ----------

  const startInitiator = React.useCallback(async () => {
    if (!firestore || !user?.id) return;
    setMode('initiator');
    setInitStage('waiting');
    setInitError(null);
    try {
      const session = await initiatePairingSessionV2(firestore, user.id);
      setInitSession(session);
      sessionToCleanupRef.current = { sessionId: session.sessionId, userId: user.id };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setInitError(msg);
      setInitStage('error');
    }
  }, [firestore, user?.id]);

  // Подписка на Firestore-сессию: ждём смену state на awaiting_accept.
  React.useEffect(() => {
    if (!firestore || !user?.id || !initSession) return;
    const unsub = watchPairingSessionV2(
      firestore,
      user.id,
      initSession.sessionId,
      async (data) => {
        if (!data) {
          // Документ удалён (TTL / manual reject) — закрываем диалог.
          if (initStage !== 'completed') {
            setInitError(t('settings.e2eeQr.sessionExpired'));
            setInitStage('error');
          }
          return;
        }
        if (data.state === 'awaiting_accept' && data.donorPayload) {
          setDonorDocSnapshot(data);
          // Предвычисляем 6-значный код сверки, но **не** применяем приватник:
          // пользователь ещё должен подтвердить.
          try {
            const res = await consumeDonorPayloadV2({
              firestore,
              userId: user.id,
              sessionId: initSession.sessionId,
              initiatorEphemeralPrivate: initSession.ephemeralPrivate,
              donorDoc: data,
            });
            setInitCode(res.pairingCode);
            setInitStage('awaiting-accept');
            // Приватник пока держим в local var через замыкание ниже.
            // `consumeDonorPayloadV2` пометит сессию completed, даже если юзер
            // не подтвердит — это OK, документ всё равно TTL-ится. Но чтобы
            // пользователь мог реально отклонить, запомним pkcs8 и применим
            // только после подтверждения.
            setPendingPkcs8({
              privateKeyPkcs8: res.privateKeyPkcs8,
              backupId:
                (data.donorPayload?.deviceDraft as { deviceId?: string } | undefined)
                  ?.deviceId ?? null,
            });
          } catch (e) {
            setInitError(e instanceof Error ? e.message : String(e));
            setInitStage('error');
          }
        }
      }
    );
    return () => unsub();
    // initStage не в depend-array намеренно: чтобы не перезапускать watch на каждой смене фазы.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [firestore, user?.id, initSession]);

  const [pendingPkcs8, setPendingPkcs8] = React.useState<
    { privateKeyPkcs8: Uint8Array; backupId: string | null } | null
  >(null);

  const confirmInitiator = React.useCallback(async () => {
    if (!firestore || !user?.id || !pendingPkcs8 || !pendingPkcs8.backupId) {
      toast({
        variant: 'destructive',
        title: t('settings.e2eeQr.noRestoreData'),
        description: t('settings.e2eeQr.noRestoreDataDesc'),
      });
      return;
    }
    setInitBusy(true);
    try {
      // Достаём публичник donor-устройства из `e2eeDevices/{deviceId}`.
      // Он совпадает с приватником, потому что donor переносит именно свою identity.
      const deviceRef = doc(firestore, 'users', user.id, 'e2eeDevices', pendingPkcs8.backupId);
      const deviceSnap = await getDoc(deviceRef);
      if (!deviceSnap.exists()) {
        throw new Error('E2EE_PAIRING_DEVICE_PUBKEY_MISSING');
      }
      const publicKeySpki = (deviceSnap.data() as { publicKeySpki?: string }).publicKeySpki;
      if (!publicKeySpki) {
        throw new Error('E2EE_PAIRING_DEVICE_PUBKEY_MISSING');
      }
      await replaceIdentityFromBackupV2({
        deviceId: pendingPkcs8.backupId,
        privateKeyPkcs8: pendingPkcs8.privateKeyPkcs8,
        publicKeySpkiB64: publicKeySpki,
      });
      sessionToCleanupRef.current = null;
      setInitStage('completed');
      toast({
        title: t('settings.e2eeQr.keyTransferred'),
        description: t('settings.e2eeQr.keyTransferredDesc'),
      });
    } catch (e) {
      setInitError(e instanceof Error ? e.message : String(e));
      setInitStage('error');
    } finally {
      setInitBusy(false);
    }
  }, [firestore, user?.id, pendingPkcs8, toast]);

  // ---------- DONOR ----------

  const submitDonor = React.useCallback(async () => {
    if (!firestore || !user?.id) return;
    setDonorStage('confirming');
    setDonorError(null);
    try {
      let payload: PairingQrPayload;
      try {
        payload = parseQrPayload(donorQrString.trim());
      } catch {
        throw new Error(t('settings.e2eeQr.invalidQrString'));
      }
      if (payload.uid !== user.id) {
        throw new Error(t('settings.e2eeQr.qrWrongAccount'));
      }
      // Нужен наш текущий PKCS#8 приватник — его и передаём новому устройству.
      await getOrCreateDeviceIdentityV2();
      const pkcs8 = await readStoredIdentityPkcs8V2();
      if (!pkcs8) throw new Error(t('settings.e2eeQr.noPrivateKey'));
      // Формируем deviceDraft из текущей identity, чтобы initiator получил deviceId.
      const myIdentity = await getOrCreateDeviceIdentityV2();
      const res = await donorRespondToPairingV2({
        firestore,
        userId: user.id,
        sessionId: payload.sessionId,
        initiatorEphPubSpkiB64: payload.initiatorEphPub,
        privateKeyPkcs8: pkcs8,
        // deviceDraft — поля как в Firestore-doc: deviceId/platform/label/publicKeySpki.
        // Initiator прочитает его из `donorPayload.deviceDraft`.
        deviceDraft: {
          deviceId: myIdentity.deviceId,
          platform: 'web',
          label: navigator.userAgent.split(' ').slice(-2).join(' '),
          publicKeySpki: myIdentity.publicKeySpkiB64,
        },
      });
      setDonorCode(res.pairingCode);
      setDonorStage('done');
    } catch (e) {
      setDonorError(e instanceof Error ? e.message : String(e));
      setDonorStage('error');
    }
  }, [firestore, user?.id, donorQrString]);

  const copyQr = React.useCallback(async () => {
    if (!initSession) return;
    try {
      await navigator.clipboard.writeText(initSession.qrEncoded);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* ignore */
    }
  }, [initSession]);

  // UI ---------------------------------------------------------------

  return (
    <Dialog open={open} onOpenChange={(o) => (o ? onOpenChange(true) : handleClose())}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>
            {mode === 'pick'
              ? t('settings.e2eeQr.title')
              : mode === 'initiator'
                ? t('settings.e2eeQr.qrForNewDevice')
                : t('settings.e2eeQr.scanQr')}
          </DialogTitle>
          <DialogDescription>
            {mode === 'pick'
              ? t('settings.e2eeQr.pickRoleDesc')
              : mode === 'initiator'
                ? t('settings.e2eeQr.initiatorDesc')
                : t('settings.e2eeQr.donorDesc')}
          </DialogDescription>
        </DialogHeader>

        {mode === 'pick' && (
          <div className="flex flex-col gap-3 py-2">
            <Button onClick={startInitiator} className="w-full">
              {t('settings.e2eeQr.newDeviceBtn')}
            </Button>
            <Button
              variant="outline"
              onClick={() => setMode('donor')}
              className="w-full"
            >
              {t('settings.e2eeQr.haveKeyBtn')}
            </Button>
          </div>
        )}

        {mode === 'initiator' && (
          <div className="flex flex-col items-center gap-3 py-2">
            {initStage === 'waiting' && initSession && (
              <>
                <div className="rounded-lg bg-white p-3">
                  <QRCodeCanvas value={initSession.qrEncoded} size={220} includeMargin={false} />
                </div>
                <p className="text-center text-sm text-muted-foreground">
                  {t('settings.e2eeQr.waitingScan')}
                </p>
                <Button variant="ghost" size="sm" onClick={copyQr}>
                  {copied ? (
                    <>
                      <Check className="mr-1 h-4 w-4" /> {t('settings.e2eeQr.copied')}
                    </>
                  ) : (
                    <>
                      <Copy className="mr-1 h-4 w-4" /> {t('settings.e2eeQr.copyQrString')}
                    </>
                  )}
                </Button>
              </>
            )}
            {initStage === 'waiting' && !initSession && (
              <Loader2 className="h-6 w-6 animate-spin" />
            )}
            {initStage === 'awaiting-accept' && (
              <>
                <p className="text-center text-sm">{t('settings.e2eeQr.verifyCode')}</p>
                <div className="text-3xl font-mono font-bold tracking-widest">{initCode}</div>
                {donorDocSnapshot?.donorPayload?.deviceDraft && (
                  <p className="text-xs text-muted-foreground">
                    {t('settings.e2eeQr.confirmTransfer')}&nbsp;
                    <code>
                      {(donorDocSnapshot.donorPayload.deviceDraft as { label?: string }).label ??
                        '—'}
                    </code>
                  </p>
                )}
                <div className="flex gap-2">
                  <Button variant="ghost" onClick={handleClose} disabled={initBusy}>
                    {t('settings.e2eeQr.cancelBtn')}
                  </Button>
                  <Button onClick={confirmInitiator} disabled={initBusy}>
                    {initBusy && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                    {t('settings.e2eeQr.codeMatches')}
                  </Button>
                </div>
              </>
            )}
            {initStage === 'completed' && (
              <p className="text-center text-sm text-emerald-500">
                {t('settings.e2eeQr.keyApplied')}
              </p>
            )}
            {initStage === 'error' && (
              <p className="text-center text-sm text-destructive">{initError}</p>
            )}
          </div>
        )}

        {mode === 'donor' && (
          <div className="flex flex-col gap-3 py-2">
            {donorStage === 'input' && (
              <>
                <Label htmlFor="qr-donor-input">{t('settings.e2eeQr.donorQrLabel')}</Label>
                <Input
                  id="qr-donor-input"
                  value={donorQrString}
                  onChange={(e) => setDonorQrString(e.target.value)}
                  placeholder="v2-pairing-1…"
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  {t('settings.e2eeQr.donorHint')}
                </p>
              </>
            )}
            {donorStage === 'confirming' && <Loader2 className="h-6 w-6 animate-spin" />}
            {donorStage === 'done' && (
              <>
                <p className="text-center text-sm">{t('settings.e2eeQr.verifyCodeDonor')}</p>
                <div className="mx-auto text-3xl font-mono font-bold tracking-widest">
                  {donorCode}
                </div>
                <p className="text-xs text-muted-foreground">
                  {t('settings.e2eeQr.donorCodeHint')}
                </p>
              </>
            )}
            {donorStage === 'error' && (
              <p className="text-sm text-destructive">{donorError}</p>
            )}
          </div>
        )}

        <DialogFooter>
          {mode === 'donor' && donorStage === 'input' && (
            <>
              <Button variant="ghost" onClick={() => setMode('pick')}>
                {t('settings.e2eeQr.backBtn')}
              </Button>
              <Button onClick={submitDonor} disabled={!donorQrString.trim()}>
                {t('settings.e2eeQr.continueBtn')}
              </Button>
            </>
          )}
          {!(mode === 'donor' && donorStage === 'input') && (
            <Button variant="ghost" onClick={handleClose}>
              {t('settings.e2eeQr.closeBtn')}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
