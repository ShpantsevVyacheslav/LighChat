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
import { Loader2, HardDrive } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { AdminStorageStatsPanel } from '@/components/admin/admin-storage-stats-panel';

const MAIN_DOC = 'main';

const defaultStorage = (): PlatformSettingsDoc['storage'] => ({
  mediaRetentionDays: null,
  totalQuotaGb: null,
});

export function AdminStorageSettingsPanel() {
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
      } catch (e: unknown) {
        console.error(e);
        const code = e && typeof e === 'object' && 'code' in e ? String((e as { code?: string }).code) : '';
        const isPermission = code === 'permission-denied';
        toast({
          variant: 'destructive',
          title: 'Не удалось загрузить настройки',
          description: isPermission
            ? 'Нет прав на чтение (нужна авторизация и актуальные правила). Выполните firebase deploy --only firestore:rules. Если сохранение настроек недоступно — в Firestore в users/{ваш UID} должно быть поле role со строкой admin.'
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
      toast({ title: 'Настройки сохранены' });
    } catch (e: unknown) {
      console.error(e);
      const code = e && typeof e === 'object' && 'code' in e ? String((e as { code?: string }).code) : '';
      toast({
        variant: 'destructive',
        title: 'Ошибка сохранения',
        description:
          code === 'permission-denied'
            ? 'Задеплойте правила Firestore (firebase deploy --only firestore:rules).'
            : undefined,
      });
    } finally {
      setSaving(false);
    }
  };

  const saveUserQuota = async () => {
    if (!firestore || !userQuotaUserId.trim()) {
      toast({ variant: 'destructive', title: 'Укажите ID пользователя' });
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
      toast({ title: gb != null ? 'Квота пользователя обновлена' : 'Квота пользователя сброшена' });
      setUserQuotaUserId('');
      setUserQuotaGb('');
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось записать квоту' });
    } finally {
      setSaving(false);
    }
  };

  const saveConvQuota = async () => {
    if (!firestore || !convQuotaId.trim()) {
      toast({ variant: 'destructive', title: 'Укажите ID чата' });
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
      toast({ title: gb != null ? 'Квота чата обновлена' : 'Квота чата сброшена' });
      setConvQuotaId('');
      setConvQuotaGb('');
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось записать квоту чата' });
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
          Хранилище (Storage)
        </CardTitle>
        <CardDescription>
          Параметры ниже сохраняются в Firestore (<code className="text-xs">platformSettings/main</code> и поля
          документов). Фактическое удаление файлов по сроку и FIFO при переполнении общей квоты нужно реализовать в{' '}
          <strong>Cloud Functions</strong> (обход Storage, подсчёт размера, связь с датами сообщений).
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-8">
        {loading ? (
          <div className="flex items-center gap-2 text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin" />
            Загрузка…
          </div>
        ) : (
          <>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="retention">Автоудаление медиа (дней после отправки)</Label>
                <Input
                  id="retention"
                  type="number"
                  min={1}
                  placeholder="Пусто — не задано"
                  value={retentionDays}
                  onChange={(e) => setRetentionDays(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">Изображения и видео в Storage старше N дней от метки в сообщении.</p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="totalgb">Общий лимит хранилища (Гб)</Label>
                <Input
                  id="totalgb"
                  type="number"
                  min={1}
                  step="0.1"
                  placeholder="Пусто — без лимита"
                  value={totalGb}
                  onChange={(e) => setTotalGb(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">При достижении — удалять самые старые объекты (FIFO).</p>
              </div>
            </div>
            <Button type="button" onClick={() => void saveGlobal()} disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Сохранить глобальные настройки
            </Button>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">Квота для конкретного пользователя</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <Input
                  placeholder="User ID (uid)"
                  value={userQuotaUserId}
                  onChange={(e) => setUserQuotaUserId(e.target.value)}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder="Гб (пусто — сброс)"
                  value={userQuotaGb}
                  onChange={(e) => setUserQuotaGb(e.target.value)}
                />
                <Button type="button" variant="secondary" onClick={() => void saveUserQuota()} disabled={saving}>
                  Применить
                </Button>
              </div>
            </div>

            <div className="border-t pt-6 space-y-4">
              <h3 className="text-sm font-semibold">Квота для группового чата</h3>
              <div className="grid gap-3 sm:grid-cols-3">
                <Input
                  placeholder="Conversation ID"
                  value={convQuotaId}
                  onChange={(e) => setConvQuotaId(e.target.value)}
                />
                <Input
                  type="number"
                  min={0.001}
                  step="0.1"
                  placeholder="Гб (пусто — сброс)"
                  value={convQuotaGb}
                  onChange={(e) => setConvQuotaGb(e.target.value)}
                />
                <Button type="button" variant="secondary" onClick={() => void saveConvQuota()} disabled={saving}>
                  Применить
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
