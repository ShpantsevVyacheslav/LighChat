'use client';

import React, { useCallback, useMemo, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
import { useFirestore, useUser, useFirebaseApp } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { getFunctions, httpsCallable, type HttpsCallableResult } from 'firebase/functions';
import type { PlatformBillingConfig, PlatformSettingsDoc } from '@/lib/types';
import { DollarSign, Loader2, RefreshCw, Settings2 } from 'lucide-react';
import { logger } from '@/lib/logger';

/**
 * UI-таб «Затраты»: вызывает callable `fetchBillingSummary`, который
 * читает Cloud Billing Export → BigQuery. Включить экспорт и выдать SA
 * `roles/bigquery.dataViewer` нужно вручную в GCP Console (один раз на
 * billing account).
 *
 * Пока в `platformSettings/main.billing` не сохранён конфиг
 * (projectId/dataset/tableId), панель показывает форму настройки.
 */

const MAIN_DOC = 'main';

type PresetPeriod = 'last7d' | 'last30d' | 'mtd' | 'custom';

type CallableResponse =
  | {
      ok: true;
      items: Array<{ service: string; cost: number; currency: string }>;
      total: { cost: number; currency: string };
      periodFrom: string;
      periodTo: string;
      tableFullyQualified: string;
    }
  | { ok: false; error: string; details?: string };

function periodRange(p: PresetPeriod, customFrom: string, customTo: string): { from: string; to: string } | null {
  const now = new Date();
  const to = now.toISOString();
  if (p === 'last7d') {
    return { from: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString(), to };
  }
  if (p === 'last30d') {
    return { from: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString(), to };
  }
  if (p === 'mtd') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
    return { from: start, to };
  }
  // custom
  if (!customFrom || !customTo) return null;
  const fromMs = Date.parse(customFrom);
  const toMs = Date.parse(customTo);
  if (!Number.isFinite(fromMs) || !Number.isFinite(toMs) || fromMs >= toMs) return null;
  return { from: new Date(fromMs).toISOString(), to: new Date(toMs).toISOString() };
}

function formatCost(value: number, currency: string): string {
  try {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: currency || 'USD',
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    return `${value.toFixed(2)} ${currency}`;
  }
}

export function AdminCostsPanel() {
  const { toast } = useToast();
  const firestore = useFirestore();
  const firebaseApp = useFirebaseApp();
  const { user: firebaseAuthUser } = useUser();
  const { user } = useAuth();

  const [config, setConfig] = useState<PlatformBillingConfig | null>(null);
  const [configLoaded, setConfigLoaded] = useState(false);
  const [editingConfig, setEditingConfig] = useState(false);
  const [configProjectId, setConfigProjectId] = useState('');
  const [configDataset, setConfigDataset] = useState('');
  const [configTableId, setConfigTableId] = useState('');
  const [savingConfig, setSavingConfig] = useState(false);

  const [preset, setPreset] = useState<PresetPeriod>('last30d');
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');
  const [data, setData] = useState<CallableResponse | null>(null);
  const [loading, setLoading] = useState(false);

  // Загрузка конфига
  React.useEffect(() => {
    if (!firestore || user?.role !== 'admin') return;
    let cancelled = false;
    (async () => {
      try {
        const snap = await getDoc(doc(firestore, 'platformSettings', MAIN_DOC));
        if (cancelled) return;
        const billing = (snap.data() as PlatformSettingsDoc | undefined)?.billing;
        if (billing) {
          setConfig(billing);
          setConfigProjectId(billing.projectId);
          setConfigDataset(billing.dataset);
          setConfigTableId(billing.tableId);
        }
      } catch (e) {
        logger.error('admin-costs', 'load config', e);
      } finally {
        if (!cancelled) setConfigLoaded(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firestore, user?.role]);

  const saveConfig = useCallback(async () => {
    if (!firestore || !user) return;
    const next: PlatformBillingConfig = {
      projectId: configProjectId.trim(),
      dataset: configDataset.trim(),
      tableId: configTableId.trim(),
      updatedAt: new Date().toISOString(),
      updatedBy: user.id,
    };
    if (!next.projectId || !next.dataset || !next.tableId) {
      toast({ variant: 'destructive', title: 'Заполните projectId, dataset и tableId' });
      return;
    }
    setSavingConfig(true);
    try {
      await setDoc(
        doc(firestore, 'platformSettings', MAIN_DOC),
        { billing: next },
        { merge: true },
      );
      setConfig(next);
      setEditingConfig(false);
      toast({ title: 'Конфигурация Billing Export сохранена' });
    } catch (e) {
      logger.error('admin-costs', 'saveConfig', e);
      toast({ variant: 'destructive', title: 'Не удалось сохранить конфигурацию' });
    } finally {
      setSavingConfig(false);
    }
  }, [firestore, user, configProjectId, configDataset, configTableId, toast]);

  const fetchData = useCallback(async () => {
    if (!firebaseApp || !firebaseAuthUser) return;
    const range = periodRange(preset, customFrom, customTo);
    if (!range) {
      toast({ variant: 'destructive', title: 'Укажите корректный диапазон дат' });
      return;
    }
    setLoading(true);
    setData(null);
    try {
      const functions = getFunctions(firebaseApp, 'us-central1');
      const fn = httpsCallable<{ from: string; to: string }, CallableResponse>(
        functions,
        'fetchBillingSummary',
      );
      const res: HttpsCallableResult<CallableResponse> = await fn({
        from: range.from,
        to: range.to,
      });
      setData(res.data);
      if (!res.data.ok) {
        if (res.data.error === 'not_configured') {
          toast({
            variant: 'destructive',
            title: 'Billing Export не настроен',
            description: 'Заполните projectId/dataset/tableId и сохраните.',
          });
          setEditingConfig(true);
        } else {
          toast({ variant: 'destructive', title: 'Ошибка запроса BigQuery', description: res.data.details });
        }
      }
    } catch (e) {
      logger.error('admin-costs', 'fetchBillingSummary', e);
      toast({ variant: 'destructive', title: 'Не удалось вызвать fetchBillingSummary' });
    } finally {
      setLoading(false);
    }
  }, [firebaseApp, firebaseAuthUser, preset, customFrom, customTo, toast]);

  const items = useMemo(() => (data && data.ok ? data.items : []), [data]);
  const totalCost = data && data.ok ? data.total : null;

  if (user?.role !== 'admin') return null;

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <DollarSign className="h-5 w-5 text-primary" /> Затраты GCP (Billing Export)
        </CardTitle>
        <CardDescription>
          Реальные суммы из Cloud Billing → BigQuery. Cron функции Storage/Firestore/FCM, App Hosting,
          Cloud Run — всё, что включено в биллинг-экспорт. Если данных нет — проверьте, что Billing
          Export включён в GCP Console и Service Account Cloud Functions имеет
          <code className="font-mono"> roles/bigquery.dataViewer</code> на dataset.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Конфиг */}
        {(editingConfig || (!config && configLoaded)) ? (
          <div className="space-y-3 rounded-2xl border border-border/60 bg-muted/15 p-4">
            <div className="flex items-center gap-2">
              <Settings2 className="h-4 w-4 text-muted-foreground" />
              <h3 className="text-sm font-semibold">Конфигурация Billing Export</h3>
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label className="text-xs">GCP projectId</Label>
                <Input
                  placeholder="project-72b24"
                  value={configProjectId}
                  onChange={(e) => setConfigProjectId(e.target.value)}
                  className="rounded-xl"
                />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Dataset</Label>
                <Input
                  placeholder="billing_export"
                  value={configDataset}
                  onChange={(e) => setConfigDataset(e.target.value)}
                  className="rounded-xl"
                />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Table ID</Label>
                <Input
                  placeholder="gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX"
                  value={configTableId}
                  onChange={(e) => setConfigTableId(e.target.value)}
                  className="rounded-xl"
                />
              </div>
            </div>
            <p className="text-xs text-muted-foreground">
              Имя таблицы Google генерирует автоматически при включении экспорта (Console →
              Billing → Billing export → Daily cost detail). Идентификаторы должны соответствовать
              <code className="font-mono"> [A-Za-z][A-Za-z0-9_-]*</code> — иначе CF отклоняет запрос
              (защита от SQL-инъекции в имени таблицы).
            </p>
            <div className="flex gap-2">
              <Button type="button" onClick={() => void saveConfig()} disabled={savingConfig}>
                {savingConfig ? <Loader2 className="h-4 w-4 animate-spin mr-1" /> : null}
                Сохранить
              </Button>
              {config && (
                <Button type="button" variant="ghost" onClick={() => setEditingConfig(false)} disabled={savingConfig}>
                  Отмена
                </Button>
              )}
            </div>
          </div>
        ) : (
          config && (
            <div className="flex items-center justify-between rounded-2xl border border-border/60 bg-muted/10 p-3">
              <div className="text-xs">
                <span className="text-muted-foreground">Источник: </span>
                <code className="font-mono">{config.projectId}.{config.dataset}.{config.tableId}</code>
              </div>
              <Button type="button" variant="ghost" size="sm" onClick={() => setEditingConfig(true)}>
                <Settings2 className="h-3.5 w-3.5 mr-1" /> Изменить
              </Button>
            </div>
          )
        )}

        {/* Период */}
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="space-y-2">
            <Label>Период</Label>
            <Select value={preset} onValueChange={(v) => setPreset(v as PresetPeriod)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="last7d">Последние 7 дней</SelectItem>
                <SelectItem value="last30d">Последние 30 дней</SelectItem>
                <SelectItem value="mtd">Месяц-to-date</SelectItem>
                <SelectItem value="custom">Произвольный диапазон</SelectItem>
              </SelectContent>
            </Select>
          </div>
          {preset === 'custom' && (
            <div className="grid gap-2 sm:grid-cols-2">
              <div className="space-y-1">
                <Label className="text-xs">С</Label>
                <Input
                  type="datetime-local"
                  value={customFrom}
                  onChange={(e) => setCustomFrom(e.target.value)}
                  className="rounded-xl"
                />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">По</Label>
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

        <Button type="button" onClick={() => void fetchData()} disabled={loading || !config}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin mr-1" /> : <RefreshCw className="h-4 w-4 mr-1" />}
          Получить отчёт
        </Button>

        {/* Результат */}
        {data && data.ok && (
          <div className="space-y-3 border-t pt-4">
            <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4">
              <p className="text-xs text-muted-foreground">Итого за период</p>
              <p className="text-2xl font-bold">
                {totalCost ? formatCost(totalCost.cost, totalCost.currency) : '—'}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                {new Date(data.periodFrom).toLocaleDateString('ru-RU')} —{' '}
                {new Date(data.periodTo).toLocaleDateString('ru-RU')}
              </p>
            </div>

            <div className="rounded-xl border border-border/60 overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Сервис</TableHead>
                    <TableHead className="text-right">Стоимость</TableHead>
                    <TableHead className="text-right w-20">%</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {items.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={3} className="text-center text-sm text-muted-foreground py-6">
                        Нет данных за выбранный период. Биллинг-экспорт пишется с задержкой до 24 часов.
                      </TableCell>
                    </TableRow>
                  ) : (
                    items.map((row) => {
                      const share = totalCost && totalCost.cost > 0 ? (row.cost / totalCost.cost) * 100 : 0;
                      return (
                        <TableRow key={row.service}>
                          <TableCell className="font-medium">{row.service}</TableCell>
                          <TableCell className="text-right font-mono text-sm">
                            {formatCost(row.cost, row.currency)}
                          </TableCell>
                          <TableCell className="text-right text-sm text-muted-foreground">
                            {share.toFixed(1)}%
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        )}

        {data && !data.ok && data.error === 'not_configured' && (
          <p className="text-xs text-muted-foreground border-t pt-4">
            После настройки Billing Export первая порция данных появляется в BigQuery
            обычно в течение 24 часов.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
