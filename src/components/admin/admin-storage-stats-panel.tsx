'use client';

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useToast } from '@/hooks/use-toast';
import { useAuth as useFirebaseAuth, useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { fetchChatStorageStatsAction } from '@/actions/storage-stats-actions';
import { listAdminConversationsAction } from '@/actions/admin-conversations-list-action';
import type { AdminChatStorageStatsResult, Conversation, PlatformSettingsDoc } from '@/lib/types';
import { formatStorageBytes, bytesToGiB } from '@/lib/format-storage';
import { BarChart3, Loader2, RefreshCw } from 'lucide-react';

const MAIN_DOC = 'main';

type PeriodPreset = 'all' | 'day' | 'week' | 'month' | 'year' | 'custom';

function rangeForPreset(preset: PeriodPreset): { from: string | null; to: string | null } {
  const now = new Date();
  const end = now.toISOString();
  if (preset === 'all') return { from: null, to: null };
  if (preset === 'day') {
    const d = new Date(now);
    d.setHours(0, 0, 0, 0);
    return { from: d.toISOString(), to: end };
  }
  if (preset === 'week') {
    const d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    return { from: d.toISOString(), to: end };
  }
  if (preset === 'month') {
    const d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    return { from: d.toISOString(), to: end };
  }
  if (preset === 'year') {
    const d = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
    return { from: d.toISOString(), to: end };
  }
  return { from: null, to: null };
}

export function AdminStorageStatsPanel() {
  const firestore = useFirestore();
  const firebaseAuth = useFirebaseAuth();
  const { user } = useAuth();
  const { toast } = useToast();

  const [conversations, setConversations] = useState<Pick<Conversation, 'id' | 'name' | 'isGroup'>[]>([]);
  const [convSearch, setConvSearch] = useState('');
  const [selectedConvIds, setSelectedConvIds] = useState<Set<string>>(() => new Set());
  const [preset, setPreset] = useState<PeriodPreset>('all');
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');
  const [priceUsd, setPriceUsd] = useState('');
  const [stats, setStats] = useState<AdminChatStorageStatsResult | null>(null);
  const [loadingConvos, setLoadingConvos] = useState(false);
  const [loadingStats, setLoadingStats] = useState(false);

  useEffect(() => {
    if (!firebaseAuth || user?.role !== 'admin') return;
    let cancelled = false;
    setLoadingConvos(true);
    (async () => {
      try {
        const token = await firebaseAuth.currentUser?.getIdToken();
        if (!token) {
          if (!cancelled) {
            toast({ variant: 'destructive', title: 'Нет сессии' });
          }
          return;
        }
        const res = await listAdminConversationsAction({ idToken: token });
        if (cancelled) return;
        if (!res.ok) {
          console.warn('[LighChat admin] listAdminConversationsAction:', res.error);
          toast({ variant: 'destructive', title: res.error });
          return;
        }
        setConversations(res.conversations);
      } catch (e) {
        console.error(e);
        toast({ variant: 'destructive', title: 'Не удалось загрузить список чатов' });
      } finally {
        if (!cancelled) setLoadingConvos(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firebaseAuth, user?.role, toast]);

  useEffect(() => {
    if (!firestore || user?.role !== 'admin') return;
    let cancelled = false;
    (async () => {
      try {
        const ref = doc(firestore, 'platformSettings', MAIN_DOC);
        const snap = await getDoc(ref);
        if (cancelled || !snap.exists()) return;
        const data = snap.data() as PlatformSettingsDoc;
        const p = data?.storage?.estimatedPricePerGbMonthUsd;
        if (p != null && Number.isFinite(p)) setPriceUsd(String(p));
      } catch {
        /* ignore */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firestore, user?.role]);

  const { fromIso, toIso } = useMemo(() => {
    if (preset === 'custom') {
      const fromMs = customFrom.trim() ? Date.parse(customFrom) : NaN;
      const toMs = customTo.trim() ? Date.parse(customTo) : NaN;
      return {
        fromIso: Number.isFinite(fromMs) ? new Date(fromMs).toISOString() : null,
        toIso: Number.isFinite(toMs) ? new Date(toMs).toISOString() : null,
      };
    }
    const r = rangeForPreset(preset);
    return { fromIso: r.from, toIso: r.to };
  }, [preset, customFrom, customTo]);

  const filteredConversations = useMemo(() => {
    const q = convSearch.trim().toLowerCase();
    if (!q) return conversations;
    return conversations.filter(
      (c) => c.id.toLowerCase().includes(q) || (c.name && c.name.toLowerCase().includes(q)),
    );
  }, [conversations, convSearch]);

  const toggleConv = useCallback((id: string, checked: boolean) => {
    setSelectedConvIds((prev) => {
      const next = new Set(prev);
      if (checked) next.add(id);
      else next.delete(id);
      return next;
    });
  }, []);

  const runStats = useCallback(async () => {
    const token = await firebaseAuth.currentUser?.getIdToken();
    if (!token) {
      toast({ variant: 'destructive', title: 'Нет сессии' });
      return;
    }
    setLoadingStats(true);
    try {
      const convIds = selectedConvIds.size > 0 ? Array.from(selectedConvIds) : null;
      const res = await fetchChatStorageStatsAction({
        idToken: token,
        conversationIds: convIds,
        createdAtFromIso: fromIso,
        createdAtToIso: toIso,
      });
      setStats(res);
      if (!res.ok) {
        console.warn('[LighChat admin] fetchChatStorageStatsAction:', res.error);
        toast({ variant: 'destructive', title: res.error });
      }
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Ошибка расчёта статистики' });
    } finally {
      setLoadingStats(false);
    }
  }, [firebaseAuth, toast, selectedConvIds, fromIso, toIso]);

  const savePrice = useCallback(async () => {
    if (!firestore || user?.role !== 'admin') return;
    const n = parseFloat(priceUsd.replace(',', '.'));
    if (!Number.isFinite(n) || n < 0) {
      toast({ variant: 'destructive', title: 'Укажите неотрицательное число' });
      return;
    }
    try {
      const ref = doc(firestore, 'platformSettings', MAIN_DOC);
      const snap = await getDoc(ref);
      const prev = snap.exists() ? (snap.data() as PlatformSettingsDoc) : { storage: {} };
      const base = prev.storage ?? { mediaRetentionDays: null, totalQuotaGb: null };
      const storage = {
        ...base,
        estimatedPricePerGbMonthUsd: n,
        updatedAt: new Date().toISOString(),
        updatedBy: user.id,
      };
      await setDoc(ref, { storage }, { merge: true });
      toast({ title: 'Ставка сохранена в platformSettings' });
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось сохранить ставку' });
    }
  }, [firestore, user, priceUsd, toast]);

  const priceNum = parseFloat(priceUsd.replace(',', '.'));
  const priceOk = Number.isFinite(priceNum) && priceNum >= 0;

  const grandBytes =
    stats && stats.ok ? stats.chatTotalBytes + stats.meetingsBytes : 0;
  const costEstimate =
    stats && stats.ok && priceOk ? bytesToGiB(grandBytes) * priceNum : null;

  const chatCost =
    stats && stats.ok && priceOk ? bytesToGiB(stats.chatTotalBytes) * priceNum : null;
  const meetingCost =
    stats && stats.ok && priceOk ? bytesToGiB(stats.meetingsBytes) * priceNum : null;

  if (user?.role !== 'admin') return null;

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <BarChart3 className="h-5 w-5 text-primary" />
          Статистика вложений (оценка по сообщениям)
        </CardTitle>
        <CardDescription>
          Суммируется поле <code className="text-xs">attachments[].size</code> в сообщениях чатов и тредов. Это
          приближение к объёму в Firebase Storage: без ключей в Storage API, старые вложения без{' '}
          <code className="text-xs">size</code> не попадают в сумму (счётчик «без размера»). Фильтр по чатам не
          действует на конференции. Расчёт денег — оценка по вашей ставке, не выгрузка из Google Cloud Billing.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="space-y-2">
            <Label>Период</Label>
            <Select value={preset} onValueChange={(v) => setPreset(v as PeriodPreset)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Всё время</SelectItem>
                <SelectItem value="day">Текущий день (с 00:00 локально)</SelectItem>
                <SelectItem value="week">Последние 7 дней</SelectItem>
                <SelectItem value="month">Последние 30 дней</SelectItem>
                <SelectItem value="year">Последние 365 дней</SelectItem>
                <SelectItem value="custom">Произвольный диапазон</SelectItem>
              </SelectContent>
            </Select>
            {preset === 'custom' && (
              <div className="grid gap-2 sm:grid-cols-2">
                <div>
                  <Label className="text-xs text-muted-foreground">С (локальное datetime)</Label>
                  <Input
                    type="datetime-local"
                    value={customFrom}
                    onChange={(e) => setCustomFrom(e.target.value)}
                    className="rounded-xl"
                  />
                </div>
                <div>
                  <Label className="text-xs text-muted-foreground">По</Label>
                  <Input
                    type="datetime-local"
                    value={customTo}
                    onChange={(e) => setCustomTo(e.target.value)}
                    className="rounded-xl"
                  />
                </div>
              </div>
            )}
          </div>

          <div className="space-y-2">
            <Label>Оценка стоимости (USD за 1 Гб·мес)</Label>
            <div className="flex flex-wrap gap-2">
              <Input
                type="number"
                min={0}
                step="0.001"
                placeholder="например 0.026"
                value={priceUsd}
                onChange={(e) => setPriceUsd(e.target.value)}
                className="max-w-[200px] rounded-xl"
              />
              <Button type="button" variant="secondary" className="rounded-full" onClick={() => void savePrice()}>
                Сохранить ставку
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              Умножается на объём в Гб по выбранным фильтрам. Хранится в{' '}
              <code className="text-xs">platformSettings/main.storage.estimatedPricePerGbMonthUsd</code>.
            </p>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <Label>Фильтр по чатам (пусто — все)</Label>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="rounded-full text-xs"
              onClick={() => setSelectedConvIds(new Set())}
              disabled={selectedConvIds.size === 0}
            >
              Сбросить выбор
            </Button>
          </div>
          <Input
            placeholder="Поиск по названию или ID…"
            value={convSearch}
            onChange={(e) => setConvSearch(e.target.value)}
            className="rounded-xl"
            disabled={loadingConvos}
          />
          <ScrollArea className="h-40 rounded-xl border border-border/60 bg-muted/10 p-2">
            {loadingConvos ? (
              <p className="text-sm text-muted-foreground p-2">Загрузка чатов…</p>
            ) : (
              <ul className="space-y-2 pr-3">
                {filteredConversations.map((c) => (
                  <li key={c.id} className="flex items-start gap-2 text-sm">
                    <Checkbox
                      id={`conv-${c.id}`}
                      checked={selectedConvIds.has(c.id)}
                      onCheckedChange={(v) => toggleConv(c.id, v === true)}
                    />
                    <label htmlFor={`conv-${c.id}`} className="cursor-pointer leading-tight">
                      <span className="font-medium">{c.name || 'Без названия'}</span>
                      <span className="ml-1 text-muted-foreground text-xs">
                        {c.isGroup ? '· группа' : '· личный'} · {c.id.slice(0, 12)}…
                      </span>
                    </label>
                  </li>
                ))}
              </ul>
            )}
          </ScrollArea>
        </div>

        <Button
          type="button"
          className="rounded-full"
          onClick={() => void runStats()}
          disabled={loadingStats}
        >
          {loadingStats ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          <span className="ml-2">Рассчитать</span>
        </Button>

        {stats && stats.ok && (
          <div className="space-y-4 border-t pt-4">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">Всего в чатах</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.chatTotalBytes)}</p>
                {chatCost != null && (
                  <p className="text-xs text-muted-foreground mt-1">≈ ${chatCost.toFixed(2)} / мес по ставке</p>
                )}
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">Личные чаты</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.directChatsBytes)}</p>
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">Групповые чаты</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.groupChatsBytes)}</p>
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">Конференции (meetings)</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.meetingsBytes)}</p>
                {meetingCost != null && (
                  <p className="text-xs text-muted-foreground mt-1">≈ ${meetingCost.toFixed(2)} / мес по ставке</p>
                )}
              </div>
              <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4 sm:col-span-2">
                <p className="text-xs text-muted-foreground">Итого (чаты + конференции)</p>
                <p className="text-2xl font-bold">{formatStorageBytes(grandBytes)}</p>
                {costEstimate != null && (
                  <p className="text-sm mt-1">Оценка: <strong>${costEstimate.toFixed(2)}</strong> USD/мес при указанной ставке</p>
                )}
              </div>
            </div>

            <p className="text-xs text-muted-foreground">
              Просканировано документов: основные сообщения {stats.scannedMainMessageDocs}, треды{' '}
              {stats.scannedThreadDocs}, конференции {stats.scannedMeetingMessageDocs}.
              {stats.skippedUndatedInRange > 0 && (
                <> Без даты в выбранном периоде пропущено: {stats.skippedUndatedInRange}.</>
              )}{' '}
              Вложений без поля size: {stats.attachmentsMissingSize}.
            </p>

            {stats.byConversation.length > 0 && (
              <div className="rounded-xl border border-border/60 overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Чат</TableHead>
                      <TableHead>Тип</TableHead>
                      <TableHead className="text-right">Объём</TableHead>
                      <TableHead className="text-right">Сообщений с вложениями</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {stats.byConversation.map((row) => (
                      <TableRow key={row.conversationId}>
                        <TableCell className="max-w-[220px]">
                          <div className="truncate font-medium" title={row.title}>
                            {row.title}
                          </div>
                          <div className="text-[10px] text-muted-foreground truncate" title={row.conversationId}>
                            {row.conversationId}
                          </div>
                        </TableCell>
                        <TableCell>{row.isGroup ? 'Группа' : 'Личный'}</TableCell>
                        <TableCell className="text-right font-mono text-sm">{formatStorageBytes(row.bytes)}</TableCell>
                        <TableCell className="text-right text-sm">{row.messageDocs}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
