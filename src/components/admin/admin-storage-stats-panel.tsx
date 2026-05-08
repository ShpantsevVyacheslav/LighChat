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
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';
import { BarChart3, Loader2, RefreshCw } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

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
  const { t } = useI18n();
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
            toast({ variant: 'destructive', title: t('adminPage.storageStats.noSession') });
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
        toast({ variant: 'destructive', title: t('adminPage.storageStats.chatListError') });
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
      (c) =>
        c.id.toLowerCase().includes(q) ||
        (c.name && ruEnSubstringMatch(c.name, q)),
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
      toast({ variant: 'destructive', title: t('adminPage.storageStats.noSession') });
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
      toast({ variant: 'destructive', title: t('adminPage.storageStats.statsError') });
    } finally {
      setLoadingStats(false);
    }
  }, [firebaseAuth, toast, selectedConvIds, fromIso, toIso]);

  const savePrice = useCallback(async () => {
    if (!firestore || user?.role !== 'admin') return;
    const n = parseFloat(priceUsd.replace(',', '.'));
    if (!Number.isFinite(n) || n < 0) {
      toast({ variant: 'destructive', title: t('adminPage.storageStats.nonNegativeNumber') });
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
      toast({ title: t('adminPage.storageStats.rateSaved') });
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: t('adminPage.storageStats.rateSaveError') });
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
          {t('adminPage.storageStats.title')}
        </CardTitle>
        <CardDescription>
          {t('adminPage.storageStats.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="space-y-2">
            <Label>{t('adminPage.storageStats.periodLabel')}</Label>
            <Select value={preset} onValueChange={(v) => setPreset(v as PeriodPreset)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">{t('adminPage.storageStats.periodAll')}</SelectItem>
                <SelectItem value="day">{t('adminPage.storageStats.periodDay')}</SelectItem>
                <SelectItem value="week">{t('adminPage.storageStats.periodWeek')}</SelectItem>
                <SelectItem value="month">{t('adminPage.storageStats.periodMonth')}</SelectItem>
                <SelectItem value="year">{t('adminPage.storageStats.periodYear')}</SelectItem>
                <SelectItem value="custom">{t('adminPage.storageStats.periodCustom')}</SelectItem>
              </SelectContent>
            </Select>
            {preset === 'custom' && (
              <div className="grid gap-2 sm:grid-cols-2">
                <div>
                  <Label className="text-xs text-muted-foreground">{t('adminPage.storageStats.customFrom')}</Label>
                  <Input
                    type="datetime-local"
                    value={customFrom}
                    onChange={(e) => setCustomFrom(e.target.value)}
                    className="rounded-xl"
                  />
                </div>
                <div>
                  <Label className="text-xs text-muted-foreground">{t('adminPage.storageStats.customTo')}</Label>
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
            <Label>{t('adminPage.storageStats.costLabel')}</Label>
            <div className="flex flex-wrap gap-2">
              <Input
                type="number"
                min={0}
                step="0.001"
                placeholder={t('adminPage.storageStats.costPlaceholder')}
                value={priceUsd}
                onChange={(e) => setPriceUsd(e.target.value)}
                className="max-w-[200px] rounded-xl"
              />
              <Button type="button" variant="secondary" className="rounded-full" onClick={() => void savePrice()}>
                {t('adminPage.storageStats.saveRate')}
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              {t('adminPage.storageStats.costHint')}
            </p>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <Label>{t('adminPage.storageStats.chatFilterLabel')}</Label>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="rounded-full text-xs"
              onClick={() => setSelectedConvIds(new Set())}
              disabled={selectedConvIds.size === 0}
            >
              {t('adminPage.storageStats.resetSelection')}
            </Button>
          </div>
          <Input
            placeholder={t('adminPage.storageStats.searchPlaceholder')}
            value={convSearch}
            onChange={(e) => setConvSearch(e.target.value)}
            className="rounded-xl"
            disabled={loadingConvos}
          />
          <ScrollArea className="h-40 rounded-xl border border-border/60 bg-muted/10 p-2">
            {loadingConvos ? (
              <p className="text-sm text-muted-foreground p-2">{t('adminPage.storageStats.loadingChats')}</p>
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
                      <span className="font-medium">{c.name || t('adminPage.storageStats.noTitle')}</span>
                      <span className="ml-1 text-muted-foreground text-xs">
                        {c.isGroup ? `· ${t('adminPage.storageStats.groupTag')}` : `· ${t('adminPage.storageStats.directTag')}`} · {c.id.slice(0, 12)}…
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
          <span className="ml-2">{t('adminPage.storageStats.calculate')}</span>
        </Button>

        {stats && stats.ok && (
          <div className="space-y-4 border-t pt-4">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">{t('adminPage.storageStats.totalChats')}</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.chatTotalBytes)}</p>
                {chatCost != null && (
                  <p className="text-xs text-muted-foreground mt-1">{t('adminPage.storageStats.perMonthRate').replace('${amount}', chatCost.toFixed(2))}</p>
                )}
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">{t('adminPage.storageStats.directChats')}</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.directChatsBytes)}</p>
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">{t('adminPage.storageStats.groupChats')}</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.groupChatsBytes)}</p>
              </div>
              <div className="rounded-2xl border border-border/60 bg-muted/10 p-4">
                <p className="text-xs text-muted-foreground">{t('adminPage.storageStats.meetings')}</p>
                <p className="text-xl font-semibold">{formatStorageBytes(stats.meetingsBytes)}</p>
                {meetingCost != null && (
                  <p className="text-xs text-muted-foreground mt-1">{t('adminPage.storageStats.perMonthRate').replace('${amount}', meetingCost.toFixed(2))}</p>
                )}
              </div>
              <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4 sm:col-span-2">
                <p className="text-xs text-muted-foreground">{t('adminPage.storageStats.grandTotal')}</p>
                <p className="text-2xl font-bold">{formatStorageBytes(grandBytes)}</p>
                {costEstimate != null && (
                  <p className="text-sm mt-1">{t('adminPage.storageStats.costEstimate').replace('${amount}', costEstimate.toFixed(2))}</p>
                )}
              </div>
            </div>

            <p className="text-xs text-muted-foreground">
              {t('adminPage.storageStats.scannedDocs').replace('{main}', String(stats.scannedMainMessageDocs)).replace('{threads}', String(stats.scannedThreadDocs)).replace('{meetings}', String(stats.scannedMeetingMessageDocs))}
              {stats.skippedUndatedInRange > 0 && (
                <>{t('adminPage.storageStats.skippedUndated').replace('{count}', String(stats.skippedUndatedInRange))}</>
              )}{' '}
              {t('adminPage.storageStats.missingSize').replace('{count}', String(stats.attachmentsMissingSize))}
            </p>

            {stats.byConversation.length > 0 && (
              <div className="rounded-xl border border-border/60 overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>{t('adminPage.storageStats.colChat')}</TableHead>
                      <TableHead>{t('adminPage.storageStats.colType')}</TableHead>
                      <TableHead className="text-right">{t('adminPage.storageStats.colVolume')}</TableHead>
                      <TableHead className="text-right">{t('adminPage.storageStats.colMessageDocs')}</TableHead>
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
                        <TableCell>{row.isGroup ? t('adminPage.storageStats.typeGroup') : t('adminPage.storageStats.typeDirect')}</TableCell>
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
