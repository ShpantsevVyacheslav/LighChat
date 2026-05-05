'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BarChart3, Loader2, Users, UserPlus, Wifi, RefreshCw } from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import { fetchAnalyticsAction, computeDailyStatsAction, type AnalyticsSummary } from '@/actions/analytics-actions';

function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType; label: string; value: number; color: string }) {
  return (
    <div className="rounded-2xl border p-4 flex items-center gap-3">
      <div className={`rounded-xl p-2.5 ${color}`}>
        <Icon className="h-5 w-5" />
      </div>
      <div>
        <p className="text-2xl font-bold">{value.toLocaleString('ru-RU')}</p>
        <p className="text-xs text-muted-foreground">{label}</p>
      </div>
    </div>
  );
}

function MiniBarChart({ data, label }: { data: { date: string; value: number }[]; label: string }) {
  if (data.length === 0) return null;
  const max = Math.max(...data.map((d) => d.value), 1);

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium">{label}</p>
      <div className="flex items-end gap-[2px] h-[80px]">
        {data.map((d) => (
          <div
            key={d.date}
            className="flex-1 bg-primary/20 hover:bg-primary/40 transition-colors rounded-t-sm relative group"
            style={{ height: `${Math.max((d.value / max) * 100, 4)}%` }}
          >
            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-popover text-popover-foreground text-[10px] px-1.5 py-0.5 rounded shadow whitespace-nowrap z-10">
              {d.date}: {d.value}
            </div>
          </div>
        ))}
      </div>
      {data.length > 0 && (
        <div className="flex justify-between text-[10px] text-muted-foreground">
          <span>{data[0].date.slice(5)}</span>
          <span>{data[data.length - 1].date.slice(5)}</span>
        </div>
      )}
    </div>
  );
}

export function AdminAnalyticsPanel() {
  const firebaseAuth = useFirebaseAuth();
  const [data, setData] = useState<AnalyticsSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [computing, setComputing] = useState(false);

  const load = useCallback(async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    const res = await fetchAnalyticsAction({ idToken: token, days: 30 });
    if (res.ok) setData(res.data);
    setLoading(false);
  }, [firebaseAuth]);

  useEffect(() => { load(); }, [load]);

  const runCompute = async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setComputing(true);
    await computeDailyStatsAction({ idToken: token });
    await load();
    setComputing(false);
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2 text-lg">
              <BarChart3 className="h-5 w-5 text-primary" />
              Аналитика платформы
            </CardTitle>
            <CardDescription>Обзор активности пользователей и состояния системы.</CardDescription>
          </div>
          <Button
            variant="outline"
            size="sm"
            className="rounded-xl"
            onClick={runCompute}
            disabled={computing}
          >
            {computing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            <span className="ml-1.5 hidden sm:inline">Обновить</span>
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {loading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : data ? (
          <>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <StatCard icon={Users} label="Всего пользователей" value={data.totalUsers} color="bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400" />
              <StatCard icon={Wifi} label="Онлайн сейчас" value={data.onlineNow} color="bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" />
              <StatCard icon={BarChart3} label="Активных сегодня" value={data.activeToday} color="bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400" />
              <StatCard icon={UserPlus} label="Новых сегодня" value={data.newToday} color="bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400" />
            </div>

            {data.dailyStats.length > 0 && (
              <div className="grid sm:grid-cols-2 gap-6">
                <MiniBarChart
                  label="Активные пользователи (DAU)"
                  data={data.dailyStats.map((s) => ({ date: s.date, value: s.activeUsers }))}
                />
                <MiniBarChart
                  label="Регистрации"
                  data={data.dailyStats.map((s) => ({ date: s.date, value: s.newRegistrations }))}
                />
              </div>
            )}

            {data.dailyStats.length === 0 && (
              <p className="text-sm text-muted-foreground text-center py-4">
                Исторических данных пока нет. Нажмите «Обновить» для сбора статистики за сегодня.
              </p>
            )}
          </>
        ) : (
          <p className="text-center text-sm text-muted-foreground py-8">Не удалось загрузить данные.</p>
        )}
      </CardContent>
    </Card>
  );
}
