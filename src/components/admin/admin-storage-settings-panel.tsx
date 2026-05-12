'use client';

import React, { useEffect, useMemo, useState } from 'react';
import {
  collection,
  deleteField,
  doc,
  getDoc,
  onSnapshot,
  query,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useFirestore, useMemoFirebase, useUser } from '@/firebase';
import type { PlatformSettingsDoc, User } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { Loader2, HardDrive, Shield } from 'lucide-react';
import { Switch } from '@/components/ui/switch';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useAuth } from '@/hooks/use-auth';
import { useI18n } from '@/hooks/use-i18n';
import { AdminStorageStatsPanel } from '@/components/admin/admin-storage-stats-panel';
import {
  AdminQuotaTargetPicker,
  type AdminQuotaTargetOption,
} from '@/components/admin/admin-quota-target-picker';
import {
  listAdminConversationsAction,
  type AdminConversationListItem,
} from '@/actions/admin-conversations-list-action';
import { useAuth as useFirebaseAuth } from '@/firebase';
import { logger } from '@/lib/logger';

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
  const [enforcementMode, setEnforcementMode] = useState<'off' | 'dry_run' | 'enforce'>('off');
  const [userQuotaUserId, setUserQuotaUserId] = useState('');
  const [userQuotaGb, setUserQuotaGb] = useState('');
  const [convQuotaId, setConvQuotaId] = useState('');
  const [convQuotaGb, setConvQuotaGb] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [e2eeDefaultForNewDirectChats, setE2eeDefaultForNewDirectChats] = useState(false);

  // Источники для пикеров «по имени/логину».
  const firebaseAuthClient = useFirebaseAuth();
  type AdminQuotaUser = Pick<User, 'id' | 'name'> & {
    username?: string;
    email?: string;
  };
  const [users, setUsers] = useState<AdminQuotaUser[]>([]);
  const [usersLoading, setUsersLoading] = useState(false);
  const [conversations, setConversations] = useState<AdminConversationListItem[]>([]);
  const [convosLoading, setConvosLoading] = useState(false);

  useEffect(() => {
    if (!firestore || user?.role !== 'admin') return;
    setUsersLoading(true);
    const q = query(collection(firestore, 'users'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        setUsers(
          snap.docs.map((d) => {
            const data = d.data() as Partial<User>;
            return {
              id: d.id,
              name: typeof data.name === 'string' ? data.name : '',
              username: typeof data.username === 'string' ? data.username : undefined,
              email: typeof data.email === 'string' ? data.email : undefined,
            };
          }),
        );
        setUsersLoading(false);
      },
      (err) => {
        logger.error('admin-storage-settings', 'users onSnapshot', err);
        setUsersLoading(false);
      },
    );
    return () => unsub();
  }, [firestore, user?.role]);

  useEffect(() => {
    if (user?.role !== 'admin') return;
    let cancelled = false;
    setConvosLoading(true);
    (async () => {
      try {
        const token = await firebaseAuthClient?.currentUser?.getIdToken();
        if (!token) return;
        const res = await listAdminConversationsAction({ idToken: token });
        if (cancelled) return;
        if (res.ok) setConversations(res.conversations);
      } catch (e) {
        logger.error('admin-storage-settings', 'listAdminConversations', e);
      } finally {
        if (!cancelled) setConvosLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firebaseAuthClient, user?.role]);

  const userOptions: AdminQuotaTargetOption[] = useMemo(
    () =>
      users.map((u) => ({
        id: u.id,
        primary: u.name || u.username || u.email || u.id,
        secondary: [u.username && `@${u.username}`, u.email, u.id]
          .filter(Boolean)
          .join(' · '),
        haystack: [u.name, u.username, u.email].filter((x): x is string => !!x),
      })),
    [users],
  );

  const conversationOptions: AdminQuotaTargetOption[] = useMemo(
    () =>
      conversations.map((c) => {
        const primary = c.isGroup
          ? c.name || `Группа · ${c.id.slice(0, 8)}…`
          : (() => {
              const uniq = new Set(c.participants.map((p) => p.id));
              if (uniq.size === 1 && c.participants[0]) {
                return `Избранное · ${c.participants[0].name}`;
              }
              const names = c.participants.map((p) => p.name).slice(0, 2);
              return names.length === 2 ? `${names[0]} ↔ ${names[1]}` : c.id;
            })();
        const tag = c.isGroup ? `группа · ${c.participantCount}` : 'личный';
        return {
          id: c.id,
          primary,
          secondary: `${tag} · ${c.id}`,
          haystack: [
            c.name,
            ...c.participants.flatMap((p) => [p.name, p.id]),
          ].filter((x): x is string => !!x),
        };
      }),
    [conversations],
  );

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
        setEnforcementMode(
          s.enforcementMode === 'enforce' || s.enforcementMode === 'dry_run' ? s.enforcementMode : 'off',
        );
        setE2eeDefaultForNewDirectChats(data?.e2eeDefaultForNewDirectChats === true);
      } catch (e: unknown) {
        logger.error('admin-storage-settings', 'load platformSettings failed', e);
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
        enforcementMode,
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
      logger.error('admin-storage-settings', 'save platformSettings failed', e);
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
      logger.error('admin-storage-settings', 'user quota write failed', e);
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
      logger.error('admin-storage-settings', 'e2ee default save failed', e);
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
      logger.error('admin-storage-settings', 'chat quota write failed', e);
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

            <div className="space-y-2">
              <Label htmlFor="enforcement-mode">Режим применения квот</Label>
              <Select
                value={enforcementMode}
                onValueChange={(v) => setEnforcementMode(v as 'off' | 'dry_run' | 'enforce')}
              >
                <SelectTrigger id="enforcement-mode" className="rounded-xl max-w-sm">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="off">Выкл. — крон-функции ничего не удаляют</SelectItem>
                  <SelectItem value="dry_run">Dry-run — пишут в логи, что бы удалили</SelectItem>
                  <SelectItem value="enforce">Enforce — реальное удаление</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                Кроны запускаются ночью (Europe/Moscow): mediaRetentionCleanupDaily в 04:00, enforceStorageQuotasDaily в 04:30.
                После выселения у сообщения остаётся метка <code className="font-mono">mediaEvictedAt</code>, текст не удаляется.
              </p>
            </div>

            <Button type="button" onClick={() => void saveGlobal()} disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              {t('adminPage.storageSettings.saveGlobal')}
            </Button>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">{t('adminPage.storageSettings.userQuotaTitle')}</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <AdminQuotaTargetPicker
                  value={userQuotaUserId}
                  onChange={setUserQuotaUserId}
                  options={userOptions}
                  placeholder={t('adminPage.storageSettings.userIdPlaceholder')}
                  searchPlaceholder="Имя, логин или email…"
                  emptyMessage="Пользователи не найдены"
                  loading={usersLoading}
                  disabled={saving}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder={t('adminPage.storageSettings.userQuotaGbPlaceholder')}
                  value={userQuotaGb}
                  onChange={(e) => setUserQuotaGb(e.target.value)}
                />
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => void saveUserQuota()}
                  disabled={saving || !userQuotaUserId.trim()}
                >
                  {t('adminPage.storageSettings.apply')}
                </Button>
              </div>
            </div>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">{t('adminPage.storageSettings.chatQuotaTitle')}</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <AdminQuotaTargetPicker
                  value={convQuotaId}
                  onChange={setConvQuotaId}
                  options={conversationOptions}
                  placeholder={t('adminPage.storageSettings.chatIdPlaceholder')}
                  searchPlaceholder="Название, участник или ID…"
                  emptyMessage="Чаты не найдены"
                  loading={convosLoading}
                  disabled={saving}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder={t('adminPage.storageSettings.convQuotaGbPlaceholder')}
                  value={convQuotaGb}
                  onChange={(e) => setConvQuotaGb(e.target.value)}
                />
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => void saveConvQuota()}
                  disabled={saving || !convQuotaId.trim()}
                >
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
