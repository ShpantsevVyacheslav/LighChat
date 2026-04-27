'use client';

/**
 * Панель "Мои устройства" (E2EE v2).
 *
 * Что показывает:
 *  - Список активных и revoked устройств из `users/{uid}/e2eeDevices`.
 *  - Badge "Это устройство" для текущего deviceId.
 *  - Короткий fingerprint (SHA-256 от publicKeySpki, первые 24 hex) — это то,
 *    что пользователь может зачитать собеседнику для safety numbers.
 *  - Кнопка Rename (inline) и Revoke (с подтверждением + прогресс-баром по чатам).
 *
 * Загрузка: одним запросом читаем все устройства (listAllE2eeDevicesV2), этот
 * список обычно маленький (≤ 10), пагинация не нужна.
 *
 * Revoke запускает клиентскую ротацию эпох во всех E2EE-чатах пользователя.
 * Процесс может длиться минуты; UI блокируется модальным прогрессом, абортится
 * по Cancel. Ошибки по отдельным чатам не ломают общий процесс.
 */

import * as React from 'react';
import { Fingerprint, Loader2, Pencil, ShieldOff, Trash2 } from 'lucide-react';
import { useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import {
  getOrCreateDeviceIdentityV2,
  listAllE2eeDevicesV2,
  publishE2eeDeviceV2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import { renameE2eeDeviceV2, revokeDeviceAndRekeyV2, type RevokeProgress } from '@/lib/e2ee/v2/revoke-device';
import type { E2eeDeviceDocV2 } from '@/lib/types';
import { fromBase64 } from '@/lib/e2ee/b64';

type DeviceRow = E2eeDeviceDocV2 & { fingerprintShort: string | null };

async function shortFingerprint(publicKeySpkiB64: string): Promise<string | null> {
  try {
    const bytes = fromBase64(publicKeySpkiB64);
    const copy = new Uint8Array(bytes.length);
    copy.set(bytes);
    const hash = await crypto.subtle.digest('SHA-256', copy.buffer as ArrayBuffer);
    const hex = Array.from(new Uint8Array(hash), (b) => b.toString(16).padStart(2, '0')).join('');
    return hex.slice(0, 24).toUpperCase().match(/.{1,4}/g)?.join(' ') ?? null;
  } catch {
    return null;
  }
}

export function DevicesPanel() {
  const firestore = useFirestore();
  const { user, isLoading } = useAuth();
  const { toast } = useToast();
  const { t, locale } = useI18n();

  const formatDate = React.useCallback(
    (iso?: string) => {
      if (!iso) return '—';
      const d = new Date(iso);
      if (Number.isNaN(d.getTime())) return '—';
      return d.toLocaleString(locale === 'en' ? 'en-US' : 'ru-RU');
    },
    [locale]
  );

  const [identity, setIdentity] = React.useState<DeviceIdentityV2 | null>(null);
  const [devices, setDevices] = React.useState<DeviceRow[] | null>(null);
  const [loadError, setLoadError] = React.useState<string | null>(null);
  const [renameTarget, setRenameTarget] = React.useState<string | null>(null);
  const [renameDraft, setRenameDraft] = React.useState('');
  const [revokeTarget, setRevokeTarget] = React.useState<E2eeDeviceDocV2 | null>(null);
  const [revokeProgress, setRevokeProgress] = React.useState<{
    done: number;
    total: number;
    last?: RevokeProgress;
  } | null>(null);
  const [revoking, setRevoking] = React.useState(false);

  const loadDevices = React.useCallback(async () => {
    if (!firestore || !user?.id) return;
    try {
      const list = await listAllE2eeDevicesV2(firestore, user.id);
      const enriched = await Promise.all(
        list.map(async (d) => ({
          ...d,
          fingerprintShort: await shortFingerprint(d.publicKeySpki),
        }))
      );
      enriched.sort((a, b) => {
        // активные сверху, потом по lastSeenAt убыв.
        const ar = a.revoked === true ? 1 : 0;
        const br = b.revoked === true ? 1 : 0;
        if (ar !== br) return ar - br;
        return (b.lastSeenAt ?? '').localeCompare(a.lastSeenAt ?? '');
      });
      setDevices(enriched);
      setLoadError(null);
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : String(e));
    }
  }, [firestore, user?.id]);

  React.useEffect(() => {
    let cancelled = false;
    async function bootstrap() {
      if (!firestore || !user?.id) return;
      try {
        const id = await getOrCreateDeviceIdentityV2();
        if (cancelled) return;
        setIdentity(id);
        // ensure publish — иначе текущее устройство отсутствует в списке.
        await publishE2eeDeviceV2(firestore, user.id, id);
      } catch (e) {
        if (!cancelled) setLoadError(e instanceof Error ? e.message : String(e));
      }
      if (!cancelled) await loadDevices();
    }
    void bootstrap();
    return () => {
      cancelled = true;
    };
  }, [firestore, user?.id, loadDevices]);

  async function handleRenameConfirm() {
    if (!firestore || !user?.id || !renameTarget) return;
    const trimmed = renameDraft.trim();
    try {
      await renameE2eeDeviceV2(firestore, user.id, renameTarget, trimmed);
      toast({ title: 'Переименовано' });
      setRenameTarget(null);
      setRenameDraft('');
      await loadDevices();
    } catch (e) {
      toast({
        variant: 'destructive',
        title: t('devices.toastRenameError'),
        description: e instanceof Error ? e.message : String(e),
      });
    }
  }

  async function handleRevokeConfirm() {
    if (!firestore || !user?.id || !identity || !revokeTarget) return;
    setRevoking(true);
    setRevokeProgress({ done: 0, total: 0 });
    try {
      const result = await revokeDeviceAndRekeyV2({
        firestore,
        userId: user.id,
        revokerIdentity: identity,
        deviceIdToRevoke: revokeTarget.deviceId,
        options: {
          onProgress: (p, done, total) => setRevokeProgress({ done, total, last: p }),
        },
      });
      toast({
        title: t('devices.toastRevokedTitle'),
        description: t('devices.toastRevokedDesc', {
          rekeyed: String(result.rekeyed),
          failedSuffix: result.failed
            ? t('devices.toastRevokedFailedSuffix', { failed: String(result.failed) })
            : '',
        }),
      });
      setRevokeTarget(null);
      setRevokeProgress(null);
      await loadDevices();
    } catch (e) {
      toast({
        variant: 'destructive',
        title: t('devices.toastRevokeError'),
        description: e instanceof Error ? e.message : String(e),
      });
    } finally {
      setRevoking(false);
    }
  }

  if (isLoading || !user) {
    return <Skeleton className="h-40 w-full" />;
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Fingerprint className="h-4 w-4 text-muted-foreground" />
          {t('devices.panelTitle')}
        </CardTitle>
        <CardDescription>{t('devices.panelDescription')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {loadError && (
          <div className="text-sm text-destructive">{loadError}</div>
        )}
        {devices === null && !loadError && <Skeleton className="h-20 w-full" />}
        {devices && devices.length === 0 && (
          <div className="text-sm text-muted-foreground">{t('devices.empty')}</div>
        )}
        {devices?.map((d) => {
          const isCurrent = identity?.deviceId === d.deviceId;
          const isRevoked = d.revoked === true;
          return (
            <div
              key={d.deviceId}
              className="border rounded-md p-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
            >
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <div className="font-medium text-sm truncate">{d.label || d.deviceId}</div>
                  <Badge variant="outline" className="text-[10px] uppercase">
                    {d.platform}
                  </Badge>
                  {isCurrent && !isRevoked && (
                    <Badge className="text-[10px]" variant="default">
                      {t('devices.badgeCurrent')}
                    </Badge>
                  )}
                  {isRevoked && (
                    <Badge variant="destructive" className="text-[10px]">
                      {t('devices.badgeRevoked')}
                    </Badge>
                  )}
                </div>
                <div className="text-xs text-muted-foreground mt-1">
                  {t('devices.createdActivity', {
                    created: formatDate(d.createdAt),
                    activity: formatDate(d.lastSeenAt),
                  })}
                </div>
                {d.fingerprintShort && (
                  <div className="text-[11px] font-mono text-muted-foreground mt-1 break-all">
                    {d.fingerprintShort}
                  </div>
                )}
                {isRevoked && d.revokedAt && (
                  <div className="text-xs text-destructive mt-1">
                    {t('devices.revokedAt', { date: formatDate(d.revokedAt) })}
                  </div>
                )}
              </div>
              <div className="flex gap-2 shrink-0">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setRenameTarget(d.deviceId);
                    setRenameDraft(d.label ?? '');
                  }}
                  disabled={isRevoked}
                >
                  <Pencil className="h-3.5 w-3.5 mr-1" /> {t('devices.rename')}
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => setRevokeTarget(d)}
                  disabled={isRevoked}
                >
                  {isCurrent ? (
                    <ShieldOff className="h-3.5 w-3.5 mr-1" />
                  ) : (
                    <Trash2 className="h-3.5 w-3.5 mr-1" />
                  )}
                  {t('devices.revoke')}
                </Button>
              </div>
            </div>
          );
        })}
      </CardContent>

      {/* Rename dialog */}
      <AlertDialog
        open={renameTarget !== null}
        onOpenChange={(o) => {
          if (!o) {
            setRenameTarget(null);
            setRenameDraft('');
          }
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('devices.renameDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription>{t('devices.renameDialogDescription')}</AlertDialogDescription>
          </AlertDialogHeader>
          <Input
            value={renameDraft}
            onChange={(e) => setRenameDraft(e.target.value)}
            placeholder={t('devices.renamePlaceholder')}
            maxLength={120}
          />
          <AlertDialogFooter>
            <AlertDialogCancel>{t('common.cancel')}</AlertDialogCancel>
            <AlertDialogAction onClick={handleRenameConfirm} disabled={!renameDraft.trim()}>
              {t('common.save')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Revoke dialog */}
      <AlertDialog
        open={revokeTarget !== null}
        onOpenChange={(o) => {
          if (!o && !revoking) {
            setRevokeTarget(null);
            setRevokeProgress(null);
          }
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('devices.revokeDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {identity?.deviceId === revokeTarget?.deviceId
                ? t('devices.revokeDialogBodyCurrent')
                : t('devices.revokeDialogBodyOther')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          {revokeProgress && (
            <div className="text-xs text-muted-foreground space-y-1">
              {revoking && (
                <div className="flex items-center gap-2">
                  <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  {t('devices.revokeProgress')}
                </div>
              )}
              <div>
                {t('devices.revokeProcessed', {
                  done: String(revokeProgress.done),
                  ofTotal:
                    revokeProgress.total > 0
                      ? t('devices.revokeOfTotal', { total: String(revokeProgress.total) })
                      : '',
                })}
              </div>
            </div>
          )}
          <AlertDialogFooter>
            <AlertDialogCancel disabled={revoking}>{t('common.cancel')}</AlertDialogCancel>
            <AlertDialogAction onClick={handleRevokeConfirm} disabled={revoking}>
              {revoking ? t('devices.revoking') : t('devices.revokeAction')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Card>
  );
}
