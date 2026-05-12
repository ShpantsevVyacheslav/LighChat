'use client';

import React, { useCallback, useEffect, useState } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Activity,
  Globe2,
  Loader2,
  MessagesSquare,
  PhoneCall,
  Users2,
  Video,
} from 'lucide-react';

import { useAuth as useFirebaseAuth } from '@/firebase';
import {
  fetchEngagementMetricsAction,
  fetchPlatformBreakdownAction,
  fetchSignupFunnelAction,
  fetchAdminGeoMetricsAction,
  type EngagementMetrics,
  type PlatformBreakdown,
  type SignupFunnel,
  type AdminGeoMetrics,
} from '@/actions/analytics-actions';

/**
 * Расширенная панель продуктовой аналитики. Источник — `platformStats/daily/entries`,
 * который наполняется ежесуточным rollup'ом из `analyticsEvents`.
 *
 * Разделы:
 *   - Engagement (за 30 дней): сообщения, чаты, звонки, встречи + avg
 *   - Источники регистраций: разбивка по signup_method
 *   - Платформы: web/pwa/ios/android/macos/windows/linux
 *   - География: top-стран
 */
export function AdminProductAnalyticsPanel() {
  const firebaseAuth = useFirebaseAuth();
  const [loading, setLoading] = useState(true);
  const [eng, setEng] = useState<EngagementMetrics | null>(null);
  const [platforms, setPlatforms] = useState<PlatformBreakdown[]>([]);
  const [funnel, setFunnel] = useState<SignupFunnel[]>([]);
  const [geo, setGeo] = useState<AdminGeoMetrics | null>(null);

  const load = useCallback(async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    const [e, p, f, g] = await Promise.all([
      fetchEngagementMetricsAction({ idToken: token }),
      fetchPlatformBreakdownAction({ idToken: token, days: 30 }),
      fetchSignupFunnelAction({ idToken: token, days: 30 }),
      fetchAdminGeoMetricsAction({ idToken: token }),
    ]);
    if (e.ok) setEng(e.data);
    if (p.ok) setPlatforms(p.data);
    if (f.ok) setFunnel(f.data);
    if (g.ok) setGeo(g.data);
    setLoading(false);
  }, [firebaseAuth]);

  useEffect(() => {
    void load();
  }, [load]);

  const funnelTotals = aggregateBy(funnel, (x) => x.method, (x) => x.count);
  const totalPlatform = platforms.reduce((sum, p) => sum + p.count, 0);

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Activity className="h-5 w-5 text-primary" />
          Продуктовая аналитика
        </CardTitle>
        <CardDescription>
          Метрики из ежесуточного rollup&apos;а событий (последние 30 дней). Источники —
          серверные триггеры и клиентский SDK.
        </CardDescription>
      </CardHeader>

      <CardContent className="space-y-6">
        {loading && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" /> Загрузка...
          </div>
        )}

        {/* Engagement */}
        <section>
          <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Engagement за 30 дней
          </h3>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <MiniStat icon={<MessagesSquare className="h-4 w-4" />} label="Сообщений" value={eng?.totalMessages30d ?? 0} />
            <MiniStat icon={<Users2 className="h-4 w-4" />} label="Чатов" value={eng?.totalChats30d ?? 0} />
            <MiniStat icon={<PhoneCall className="h-4 w-4" />} label="Звонков" value={eng?.totalCalls30d ?? 0} />
            <MiniStat icon={<Video className="h-4 w-4" />} label="Встреч" value={eng?.totalMeetings30d ?? 0} />
          </div>
          {eng && (
            <p className="mt-2 text-xs text-muted-foreground">
              Среднее: {eng.avgMessagesPerActiveUser30d} сообщений на активного пользователя.
            </p>
          )}
        </section>

        {/* Signup methods */}
        <section>
          <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Источники регистраций
          </h3>
          {funnelTotals.length === 0 ? (
            <EmptyHint />
          ) : (
            <ul className="space-y-2 text-sm">
              {funnelTotals.map(({ key, value }) => (
                <BarRow key={key} label={methodLabel(key)} value={value} total={funnelTotals.reduce((s, x) => s + x.value, 0)} />
              ))}
            </ul>
          )}
        </section>

        {/* Platforms */}
        <section>
          <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Активность по платформам
          </h3>
          {platforms.length === 0 ? (
            <EmptyHint />
          ) : (
            <ul className="space-y-2 text-sm">
              {platforms.map((p) => (
                <BarRow key={p.platform} label={platformLabel(p.platform)} value={p.count} total={totalPlatform} />
              ))}
            </ul>
          )}
        </section>

        {/* Geography */}
        <section>
          <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            <Globe2 className="h-4 w-4" /> Топ-стран
          </h3>
          {!geo || geo.topCountries.length === 0 ? (
            <EmptyHint />
          ) : (
            <ul className="space-y-2 text-sm">
              {geo.topCountries.slice(0, 10).map((c) => (
                <BarRow
                  key={c.code}
                  label={`${c.label} (${c.code})`}
                  value={c.users}
                  total={geo.totalKnown}
                />
              ))}
            </ul>
          )}
        </section>
      </CardContent>
    </Card>
  );
}

function MiniStat({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-muted/30 p-3">
      <div className="mb-1 flex items-center gap-1.5 text-xs text-muted-foreground">
        {icon}
        {label}
      </div>
      <div className="text-xl font-semibold tabular-nums">{value.toLocaleString('ru')}</div>
    </div>
  );
}

function BarRow({ label, value, total }: { label: string; value: number; total: number }) {
  const pct = total > 0 ? Math.round((value / total) * 100) : 0;
  return (
    <li>
      <div className="flex items-center justify-between gap-3">
        <span className="text-foreground/90">{label}</span>
        <span className="tabular-nums text-muted-foreground">
          {value.toLocaleString('ru')} · {pct}%
        </span>
      </div>
      <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-muted">
        <div className="h-full rounded-full bg-primary" style={{ width: `${pct}%` }} />
      </div>
    </li>
  );
}

function EmptyHint() {
  return (
    <p className="text-xs text-muted-foreground">
      Пока нет данных. После первого срабатывания scheduler&apos;а
      <code className="mx-1 rounded bg-muted px-1.5 py-0.5">rollupDailyAnalytics</code>
      раздел заполнится автоматически.
    </p>
  );
}

function aggregateBy<T>(
  items: T[],
  keyFn: (x: T) => string,
  valueFn: (x: T) => number,
): { key: string; value: number }[] {
  const map = new Map<string, number>();
  for (const it of items) {
    const k = keyFn(it);
    map.set(k, (map.get(k) ?? 0) + valueFn(it));
  }
  return Array.from(map.entries())
    .map(([key, value]) => ({ key, value }))
    .sort((a, b) => b.value - a.value);
}

function methodLabel(m: string): string {
  switch (m) {
    case 'email':
      return 'Email';
    case 'google':
      return 'Google';
    case 'apple':
      return 'Apple';
    case 'telegram':
      return 'Telegram';
    case 'yandex':
      return 'Яндекс';
    case 'phone_otp':
      return 'Телефон (OTP)';
    case 'qr':
      return 'QR-код';
    case 'guest':
      return 'Гость';
    default:
      return m;
  }
}

function platformLabel(p: string): string {
  switch (p) {
    case 'web':
      return 'Web';
    case 'pwa':
      return 'PWA';
    case 'ios':
      return 'iOS';
    case 'android':
      return 'Android';
    case 'macos':
      return 'macOS';
    case 'windows':
      return 'Windows';
    case 'linux':
      return 'Linux';
    case 'server':
      return 'Сервер';
    default:
      return p;
  }
}
