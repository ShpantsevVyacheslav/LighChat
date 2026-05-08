'use client';

import React, { useEffect, useState } from 'react';
import { deleteField, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useFirestore, useMemoFirebase, useUser } from '@/firebase';
import type { PlatformSettingsDoc } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { Loader2, HardDrive, Shield } from 'lucide-react';
import { Switch } from '@/components/ui/switch';
import { useAuth } from '@/hooks/use-auth';
import { useI18n } from '@/hooks/use-i18n';
import { AdminStorageStatsPanel } from '@/components/admin/admin-storage-stats-panel';

const MAIN_DOC = 'main';

const defaultStorage = (): PlatformSettingsDoc['storage'] => ({
  mediaRetentionDays: null,
  totalQuotaGb: null,
});

export function AdminStorageSettingsPanel() {
  const { t } = useI18n();
  const firestore = useFirestore();
  const { user: firebaseAuthUser, isUserLoading: isFirebaseAuthLoading } = useUser();
  const { user } = useAuth();
  const { toast } = useToast();
  const ref = useMemoFirebase(
    () => (firestore ? doc(firestore, 'platformSettings', MAIN_DOC) : null),
    [firestore]
  );

  const [retentionDays, setRetentionDays] = useState('');
  const [totalGb, setTotalGb] = useState('');
  const [userQuotaUserId, setUserQuotaUserId] = useState('');
  const [userQuotaGb, setUserQuotaGb] = useState('');
  const [convQuotaId, setConvQuotaId] = useState('');
  const [convQuotaGb, setConvQuotaGb] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [e2eeDefaultForNewDirectChats, setE2eeDefaultForNewDirectChats] = useState(false);

  useEffect(() => {
    if (!ref) return;
    if (isFirebaseAuthLoading) return;
    if (!firebaseAuthUser) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const snap = await getDoc(ref);
        if (cancelled) return;
        const data = snap.data() as PlatformSettingsDoc | undefined;
        const s = data?.storage ?? defaultStorage();
        setRetentionDays(s.mediaRetentionDays != null ? String(s.mediaRetentionDays) : '');
        setTotalGb(s.totalQuotaGb != null ? String(s.totalQuotaGb) : '');
        setE2eeDefaultForNewDirectChats(data?.e2eeDefaultForNewDirectChats === true);
      } catch (e: unknown) {
        console.error(e);
        const code = e && typeof e === 'object' && 'code' in e ? String((e as { code?: string }).code) : '';
        const isPermission = code === 'permission-denied';
        toast({
          variant: 'destructive',
          title: t('adminPage.storageSettings.loadError'),
          description: isPermission
            ? t('adminPage.storageSettings.permissionHint')
            : undefined,
        });
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [ref, toast, firebaseAuthUser, isFirebaseAuthLoading]);

  const saveGlobal = async () => {
    if (!firestore || !ref || !user) return;
    const rd = retentionDays.trim() === '' ? null : Math.max(1, parseInt(retentionDays, 10) || 0);
    const tg = totalGb.trim() === '' ? null : Math.max(1, parseFloat(totalGb.replace(',', '.')) || 0);
    setSaving(true);
    try {
      const snap = await getDoc(ref);
      const prevStorage =
        snap.exists() ? ((snap.data() as PlatformSettingsDoc).storage ?? {}) : {};
      const storage = {
        ...prevStorage,
        mediaRetentionDays: rd,
        totalQuotaGb: tg,
        updatedAt: new Date().toISOString(),
        updatedBy: user.id,
      };
      if (snap.exists()) {
        await updateDoc(ref, { storage });
      } else {
        await setDoc(ref, { storage } satisfies Partial<PlatformSettingsDoc>);
      }
      toast({ title: t('adminPage.storageSettings.saved') });
    } catch (e: unknown) {
      console.error(e);
      const code = e && typeof e === 'object' && 'code' in e ? String((e as { code?: string }).code) : '';
      toast({
        variant: 'destructive',
        title: t('adminPage.storageSettings.saveError'),
        description:
          code === 'permission-denied'
            ? t('adminPage.storageSettings.deployHint')
            : undefined,
      });
    } finally {
      setSaving(false);
    }
  };

  const saveUserQuota = async () => {
    if (!firestore || !userQuotaUserId.trim()) {
      toast({ variant: 'destructive', title: t('adminPage.storageSettings.enterUserId') });
      return;
    }
    const gb = userQuotaGb.trim() === '' ? null : Math.max(0.001, parseFloat(userQuotaGb.replace(',', '.')) || 0);
    setSaving(true);
    try {
      if (gb == null) {
        await updateDoc(doc(firestore, 'users', userQuotaUserId.trim()), {
          storageQuotaBytes: deleteField(),
        });
      } else {
        const bytes = Math.round(gb * 1024 ** 3);
        await updateDoc(doc(firestore, 'users', userQuotaUserId.trim()), {
          storageQuotaBytes: bytes,
        });
      }
      toast({ title: gb != null ? t('adminPage.storageSettings.userQuotaUpdated') : t('adminPage.storageSettings.userQuotaReset') });
      setUserQuotaUserId('');
      setUserQuotaGb('');
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: t('adminPage.storageSettings.quotaWriteError') });
    } finally {
      setSaving(false);
    }
  };

  const saveE2eePlatformDefault = async (checked: boolean) => {
    if (!firestore || !ref || !user) return;
    setSaving(true);
    try {
      const snap = await getDoc(ref);
      if (snap.exists()) {
        await updateDoc(ref, { e2eeDefaultForNewDirectChats: checked });
      } else {
        await setDoc(ref, {
          storage: defaultStorage(),
          e2eeDefaultForNewDirectChats: checked,
        } satisfies Partial<PlatformSettingsDoc>);
      }
      setE2eeDefaultForNewDirectChats(checked);
      toast({ title: t('adminPage.storageSettings.e2eSaved'), description: t('adminPage.storageSettings.e2eDescription') });
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: t('adminPage.storageSettings.e2eSaveError') });
    } finally {
      setSaving(false);
    }
  };

  const saveConvQuota = async () => {
    if (!firestore || !convQuotaId.trim()) {
      toast({ variant: 'destructive', title: t('adminPage.storageSettings.enterChatId') });
      return;
    }
    const gb = convQuotaGb.trim() === '' ? null : Math.max(0.001, parseFloat(convQuotaGb.replace(',', '.')) || 0);
    setSaving(true);
    try {
      if (gb == null) {
        await updateDoc(doc(firestore, 'conversations', convQuotaId.trim()), {
          storageQuotaBytes: deleteField(),
        });
      } else {
        const bytes = Math.round(gb * 1024 ** 3);
        await updateDoc(doc(firestore, 'conversations', convQuotaId.trim()), {
          storageQuotaBytes: bytes,
        });
      }
      toast({ title: gb != null ? t('adminPage.storageSettings.chatQuotaUpdated') : t('adminPage.storageSettings.chatQuotaReset') });
      setConvQuotaId('');
      setConvQuotaGb('');
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: t('adminPage.storageSettings.chatQuotaWriteError') });
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
    <AdminStorageStatsPanel />
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <HardDrive className="h-5 w-5 text-primary" />
          {t('adminPage.storageSettings.title')}
        </CardTitle>
        <CardDescription>
          {t('adminPage.storageSettings.storageDescription')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-8">
        {loading ? (
          <div className="flex items-center gap-2 text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin" />
            {t('adminPage.storageSettings.loading')}
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between gap-4 rounded-xl border border-border/60 bg-muted/15 p-4">
              <div className="flex items-start gap-3 min-w-0">
                <Shield className="h-5 w-5 text-muted-foreground shrink-0 mt-0.5" />
                <div>
                  <Label htmlFor="admin-e2ee-default" className="text-sm font-medium">
                    {t('adminPage.storageSettings.e2eLabel')}
                  </Label>
                  <p className="text-xs text-muted-foreground mt-1">
                    {t('adminPage.storageSettings.e2eeHint')}
                  </p>
                </div>
              </div>
              <Switch
                id="admin-e2ee-default"
                checked={e2eeDefaultForNewDirectChats}
                disabled={saving}
                onCheckedChange={(v) => void saveE2eePlatformDefault(v)}
              />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="retention">{t('adminPage.storageSettings.retentionLabel')}</Label>
                <Input
                  id="retention"
                  type="number"
                  min={1}
                  placeholder={t('adminPage.storageSettings.retentionPlaceholder')}
                  value={retentionDays}
                  onChange={(e) => setRetentionDays(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">{t('adminPage.storageSettings.retentionDescription')}</p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="totalgb">{t('adminPage.storageSettings.totalGbLabel')}</Label>
                <Input
                  id="totalgb"
                  type="number"
                  min={1}
                  step="0.1"
                  placeholder={t('adminPage.storageSettings.totalGbPlaceholder')}
                  value={totalGb}
                  onChange={(e) => setTotalGb(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">{t('adminPage.storageSettings.totalGbHint')}</p>
              </div>
            </div>
            <Button type="button" onClick={() => void saveGlobal()} disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              {t('adminPage.storageSettings.saveGlobal')}
            </Button>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">{t('adminPage.storageSettings.userQuotaTitle')}</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <Input
                  placeholder={t('adminPage.storageSettings.userIdPlaceholder')}
                  value={userQuotaUserId}
                  onChange={(e) => setUserQuotaUserId(e.target.value)}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder={t('adminPage.storageSettings.userQuotaGbPlaceholder')}
                  value={userQuotaGb}
                  onChange={(e) => setUserQuotaGb(e.target.value)}
                />
                <Button type="button" variant="secondary" onClick={() => void saveUserQuota()} disabled={saving}>
                  {t('adminPage.storageSettings.apply')}
                </Button>
              </div>
            </div>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">{t('adminPage.storageSettings.chatQuotaTitle')}</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <Input
                  placeholder={t('adminPage.storageSettings.chatIdPlaceholder')}
                  value={convQuotaId}
                  onChange={(e) => setConvQuotaId(e.target.value)}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder={t('adminPage.storageSettings.convQuotaGbPlaceholder')}
                  value={convQuotaGb}
                  onChange={(e) => setConvQuotaGb(e.target.value)}
                />
                <Button type="button" variant="secondary" onClick={() => void saveConvQuota()} disabled={saving}>
                  {t('adminPage.storageSettings.apply')}
                </Button>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
    </>
  );
}
