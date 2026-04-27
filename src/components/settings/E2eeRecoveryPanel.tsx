'use client';

/**
 * Панель "E2EE — резервирование" (Phase 6).
 *
 * Содержит два recovery-пути:
 *  1. Password backup — зашифровать приватник паролем и положить в
 *     `users/{uid}/e2eeBackups/{backupId}`. Полностью self-contained.
 *  2. QR-pairing (entry point) — протокол реализован в
 *     `src/lib/e2ee/v2/pairing-qr.ts`; здесь показываем только placeholder.
 *     Полный UI (рендер QR + сканер камеры) требует дополнительных зависимостей
 *     (`qrcode` + web-камера), которые будут добавлены отдельным деливери.
 *
 * Паритет с mobile `e2ee_recovery_screen.dart` — одинаковый формат backup'а
 * и одинаковый deviceId (= backupId), чтобы бэкапы с одного устройства
 * не конфликтовали с бэкапами другого.
 */

import * as React from 'react';
import { KeyRound, Lock, QrCode, RefreshCcw } from 'lucide-react';
import { E2eeQrPairingDialog } from '@/components/settings/E2eeQrPairingDialog';
import { useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import {
  createPasswordBackupV2,
  E2EE_BACKUP_MIN_PASSWORD_LENGTH,
  getOrCreateDeviceIdentityV2,
  hasAnyPasswordBackupV2,
  readStoredIdentityPkcs8V2,
  replaceIdentityFromBackupV2,
  restorePasswordBackupV2,
} from '@/lib/e2ee';

type DialogMode = null | 'create' | 'restore';

export function E2eeRecoveryPanel() {
  const firestore = useFirestore();
  const { user } = useAuth();
  const { toast } = useToast();
  const { t } = useI18n();

  const [hasBackup, setHasBackup] = React.useState<boolean | null>(null);
  const [mode, setMode] = React.useState<DialogMode>(null);
  const [busy, setBusy] = React.useState(false);
  const [password, setPassword] = React.useState('');
  const [confirm, setConfirm] = React.useState('');
  // Phase 9 gap #1: отдельный флаг для QR-pairing диалога. Изолирован от
  // password-backup state, чтобы один модуль UI не мешал другому.
  const [qrOpen, setQrOpen] = React.useState(false);

  const loadBackupFlag = React.useCallback(async () => {
    if (!firestore || !user?.id) return;
    try {
      const has = await hasAnyPasswordBackupV2(firestore, user.id);
      setHasBackup(has);
    } catch {
      setHasBackup(false);
    }
  }, [firestore, user?.id]);

  React.useEffect(() => {
    if (!firestore || !user?.id) return;
    void loadBackupFlag();
  }, [firestore, user?.id, loadBackupFlag]);

  function closeDialog() {
    setMode(null);
    setPassword('');
    setConfirm('');
    setBusy(false);
  }

  async function handleCreate() {
    if (!firestore || !user?.id) return;
    if (password.length < E2EE_BACKUP_MIN_PASSWORD_LENGTH) {
      toast({
        variant: 'destructive',
        title: t('e2eeRecovery.passwordTooShortTitle'),
        description: t('e2eeRecovery.passwordTooShortDesc', {
          min: E2EE_BACKUP_MIN_PASSWORD_LENGTH,
        }),
      });
      return;
    }
    if (password !== confirm) {
      toast({
        variant: 'destructive',
        title: t('e2eeRecovery.passwordsMismatchTitle'),
      });
      return;
    }
    setBusy(true);
    try {
      const identity = await getOrCreateDeviceIdentityV2();
      const pkcs8 = await readStoredIdentityPkcs8V2();
      if (!pkcs8) throw new Error('E2EE_IDENTITY_NOT_FOUND');
      await createPasswordBackupV2({
        firestore,
        userId: user.id,
        backupId: identity.deviceId,
        password,
        privateKeyPkcs8: pkcs8,
      });
      toast({
        title: t('e2eeRecovery.backupCreatedTitle'),
        description: t('e2eeRecovery.backupCreatedDesc'),
      });
      setHasBackup(true);
      closeDialog();
    } catch (e) {
      toast({
        variant: 'destructive',
        title: t('e2eeRecovery.backupCreateErrorTitle'),
        description: e instanceof Error ? e.message : String(e),
      });
    } finally {
      setBusy(false);
    }
  }

  async function handleRestore() {
    if (!firestore || !user?.id) return;
    if (!password) {
      toast({ variant: 'destructive', title: t('e2eeRecovery.enterPasswordTitle') });
      return;
    }
    setBusy(true);
    try {
      const restored = await restorePasswordBackupV2({
        firestore,
        userId: user.id,
        password,
      });
      // Publickey recovery: WebCrypto не умеет извлечь SPKI из PKCS#8-импорта
      // (невозможно в принципе для non-extractable ключа). Поэтому берём
      // публичник из уже опубликованного `users/{uid}/e2eeDevices/{backupId}` —
      // он совпадает с приватником, потому что backupId = deviceId устройства,
      // создавшего backup.
      const { doc: fsDoc, getDoc } = await import('firebase/firestore');
      const deviceSnap = await getDoc(
        fsDoc(firestore, 'users', user.id, 'e2eeDevices', restored.backupId)
      );
      if (!deviceSnap.exists()) {
        throw new Error('E2EE_BACKUP_DEVICE_PUBKEY_MISSING');
      }
      const publicKeySpkiB64 = (deviceSnap.data() as { publicKeySpki?: string })
        ?.publicKeySpki;
      if (!publicKeySpkiB64) {
        throw new Error('E2EE_BACKUP_DEVICE_PUBKEY_MISSING');
      }
      await replaceIdentityFromBackupV2({
        deviceId: restored.backupId,
        privateKeyPkcs8: restored.privateKeyPkcs8,
        publicKeySpkiB64,
      });
      toast({
        title: t('e2eeRecovery.keyRestoredTitle'),
        description: t('e2eeRecovery.keyRestoredDesc'),
      });
      closeDialog();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      toast({
        variant: 'destructive',
        title: t('e2eeRecovery.restoreErrorTitle'),
        description: msg.includes('E2EE_BACKUP_WRONG_PASSWORD')
          ? t('e2eeRecovery.wrongPassword')
          : msg.includes('E2EE_BACKUP_NOT_FOUND')
            ? t('e2eeRecovery.backupNotFound')
            : msg.includes('E2EE_BACKUP_DEVICE_PUBKEY_MISSING')
              ? t('e2eeRecovery.devicePubKeyMissing')
              : msg,
      });
    } finally {
      setBusy(false);
    }
  }

  if (!user?.id) return null;

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <KeyRound className="h-5 w-5" />
            {t('e2eeRecovery.cardTitle')}
          </CardTitle>
          <CardDescription>{t('e2eeRecovery.cardDescription')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex flex-col gap-2 rounded-lg border p-4">
            <div className="flex items-center gap-2 text-sm font-medium">
              <Lock className="h-4 w-4" /> {t('e2eeRecovery.passwordBackupTitle')}
            </div>
            <p className="text-sm text-muted-foreground">{t('e2eeRecovery.passwordBackupBody')}</p>
            <div className="flex gap-2">
              <Button onClick={() => setMode('create')} variant="default">
                {hasBackup ? t('e2eeRecovery.overwriteBackup') : t('e2eeRecovery.createBackup')}
              </Button>
              <Button
                onClick={() => setMode('restore')}
                variant="outline"
              >
                <RefreshCcw className="h-4 w-4 mr-1" />
                {t('e2eeRecovery.restore')}
              </Button>
            </div>
          </div>
          <div className="flex flex-col gap-2 rounded-lg border p-4">
            <div className="flex items-center gap-2 text-sm font-medium">
              <QrCode className="h-4 w-4" /> {t('e2eeRecovery.qrSectionTitle')}
            </div>
            <p className="text-sm text-muted-foreground">{t('e2eeRecovery.qrSectionBody')}</p>
            <div>
              <Button onClick={() => setQrOpen(true)} variant="default">
                {t('e2eeRecovery.openQrPairing')}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
      <Dialog
        open={mode !== null}
        onOpenChange={(open) => (!open ? closeDialog() : undefined)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {mode === 'create' ? t('e2eeRecovery.dialogCreateTitle') : t('e2eeRecovery.dialogRestoreTitle')}
            </DialogTitle>
            <DialogDescription>
              {mode === 'create'
                ? t('e2eeRecovery.dialogCreateHint', { min: E2EE_BACKUP_MIN_PASSWORD_LENGTH })
                : t('e2eeRecovery.dialogRestoreHint')}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1">
              <Label htmlFor="e2ee-recovery-password">{t('e2eeRecovery.passwordLabel')}</Label>
              <Input
                id="e2ee-recovery-password"
                type="password"
                autoFocus
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            {mode === 'create' && (
              <div className="space-y-1">
                <Label htmlFor="e2ee-recovery-confirm">{t('e2eeRecovery.confirmPasswordLabel')}</Label>
                <Input
                  id="e2ee-recovery-confirm"
                  type="password"
                  value={confirm}
                  onChange={(e) => setConfirm(e.target.value)}
                />
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={closeDialog} disabled={busy}>
              {t('e2eeRecovery.cancel')}
            </Button>
            <Button
              onClick={() => (mode === 'create' ? handleCreate() : handleRestore())}
              disabled={busy}
            >
              {busy
                ? t('e2eeRecovery.busy')
                : mode === 'create'
                  ? t('common.save')
                  : t('e2eeRecovery.restore')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      <E2eeQrPairingDialog open={qrOpen} onOpenChange={setQrOpen} />
    </>
  );
}
