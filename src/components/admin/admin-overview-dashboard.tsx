'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  Users, UserPlus, Wifi, BarChart3, Loader2, ShieldAlert, MessageSquareText, HardDrive,
  Globe2, Inbox, Ban, ChevronRight,
} from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import {
  fetchAnalyticsAction, fetchAdminOverviewMetricsAction, fetchAdminGeoMetricsAction,
  type AnalyticsSummary, type AdminOverviewMetrics, type AdminGeoMetrics,
} from '@/actions/analytics-actions';
import { StatCard } from '@/components/admin/admin-stat-widgets';
import { useI18n } from '@/hooks/use-i18n';

interface AdminOverviewDashboardProps {
  onNavigateTab: (tab: string) => void;
}

const quickLinks: { tab: string; icon: React.ElementType; labelKey: string }[] = [
  { tab: 'users', icon: Users, labelKey: 'adminPage.overview.linkUsers' },
  { tab: 'storage', icon: HardDrive, labelKey: 'adminPage.overview.linkStorage' },
  { tab: 'audit', icon: BarChart3, labelKey: 'adminPage.overview.linkAudit' },
  { tab: 'platform', icon: Globe2, labelKey: 'adminPage.overview.linkPlatform' },
];

function ActionItemCard({
  icon: Icon, label, count, tone, onClick,
}: {
  icon: React.ElementType; label: string; count: number;
  tone: 'red' | 'amber' | 'slate'; onClick: () => void;
}) {
  const toneClass =
    tone === 'red' ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    : tone === 'amber' ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    : 'bg-slate-100 text-slate-700 dark:bg-slate-800/50 dark:text-slate-300';
  const isAttention = count > 0;
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-2xl border p-4 text-left hover:bg-muted/40 transition-colors flex items-center justify-between gap-3 group"
    >
      <div className="flex items-center gap-3 min-w-0">
        <div className={`rounded-xl p-2.5 ${toneClass}`}>
          <Icon className="h-5 w-5" />
        </div>
        <div className="min-w-0">
          <p className="text-2xl font-bold leading-none">{count.toLocaleString()}</p>
          <p className="text-xs text-muted-foreground mt-1">{label}</p>
        </div>
      </div>
      <ChevronRight className={`h-4 w-4 shrink-0 transition-transform ${isAttention ? 'text-primary group-hover:translate-x-0.5' : 'text-muted-foreground/40'}`} />
    </button>
  );
}

function GeoBarRow({ label, value, max }: { label: string; value: number; max: number }) {
  const pct = Math.max((value / Math.max(max, 1)) * 100, 2);
  return (
    <div className="flex items-center gap-3 text-sm">
      <span className="w-32 truncate text-muted-foreground" title={label}>{label}</span>
      <div className="flex-1 h-2 bg-muted/60 rounded-full overflow-hidden">
        <div className="h-full bg-primary/60 rounded-full" style={{ width: `${pct}%` }} />
      </div>
      <span className="w-12 text-right tabular-nums font-medium">{value.toLocaleString()}</span>
    </div>
  );
}

export function AdminOverviewDashboard({ onNavigateTab }: AdminOverviewDashboardProps) {
  const { t } = useI18n();
  const firebaseAuth = useFirebaseAuth();
  const [snap, setSnap] = useState<AnalyticsSummary | null>(null);
  const [metrics, setMetrics] = useState<AdminOverviewMetrics | null>(null);
  const [geo, setGeo] = useState<AdminGeoMetrics | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    const [a, b, c] = await Promise.all([
      fetchAnalyticsAction({ idToken: token, days: 0 }),
      fetchAdminOverviewMetricsAction({ idToken: token }),
      fetchAdminGeoMetricsAction({ idToken: token }),
    ]);
    if (a.ok) setSnap(a.data);
    if (b.ok) setMetrics(b.data);
    if (c.ok) setGeo(c.data);
    setLoading(false);
  }, [firebaseAuth]);

  useEffect(() => { load(); }, [load]);

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  const maxCountry = geo?.topCountries[0]?.users ?? 1;
  const maxCity = geo?.topCities[0]?.users ?? 1;
  const focusLabel = geo?.topCountries.find((c) => c.code === geo?.topCountryCode)?.label ?? geo?.topCountryCode;

  return (
    <div className="space-y-6">
      {snap && (
        <section className="space-y-2">
          <h2 className="text-sm font-semibold text-muted-foreground px-1">{t('adminPage.overview.snapshot')}</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <StatCard icon={Users} label={t('adminPage.overview.totalUsers')} value={snap.totalUsers} color="bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400" />
            <StatCard icon={Wifi} label={t('adminPage.overview.onlineNow')} value={snap.onlineNow} color="bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" />
            <StatCard icon={BarChart3} label={t('adminPage.overview.activeToday')} value={snap.activeToday} color="bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400" />
            <StatCard icon={UserPlus} label={t('adminPage.overview.newToday')} value={snap.newToday} color="bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400" />
          </div>
        </section>
      )}

      {metrics && (
        <section className="space-y-2">
          <h2 className="text-sm font-semibold text-muted-foreground px-1">{t('adminPage.overview.needsAttention')}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <ActionItemCard
              icon={ShieldAlert}
              label={t('adminPage.overview.openReports')}
              count={metrics.pendingReports}
              tone={metrics.pendingReports > 0 ? 'red' : 'slate'}
              onClick={() => onNavigateTab('moderation')}
            />
            <ActionItemCard
              icon={Inbox}
              label={t('adminPage.overview.openTickets')}
              count={metrics.openTickets}
              tone={metrics.openTickets > 0 ? 'amber' : 'slate'}
              onClick={() => onNavigateTab('support')}
            />
            <ActionItemCard
              icon={Ban}
              label={t('adminPage.overview.blockedAccounts')}
              count={metrics.blockedUsers}
              tone="slate"
              onClick={() => onNavigateTab('users')}
            />
          </div>
        </section>
      )}

      {geo && (geo.topCountries.length > 0 || geo.topCities.length > 0) && (
        <section className="space-y-2">
          <div className="flex items-baseline justify-between px-1 gap-2">
            <h2 className="text-sm font-semibold text-muted-foreground flex items-center gap-1.5">
              <Globe2 className="h-3.5 w-3.5" /> {t('adminPage.overview.userGeo')}
            </h2>
            <span className="text-xs text-muted-foreground">
              {t('adminPage.overview.geoKnown', { known: geo.totalKnown.toLocaleString(), total: (geo.totalKnown + geo.unknown).toLocaleString() })}
            </span>
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
            <div className="rounded-3xl border p-5 space-y-2.5">
              <p className="text-sm font-medium mb-3">{t('adminPage.overview.topCountries')}</p>
              {geo.topCountries.length === 0 ? (
                <p className="text-xs text-muted-foreground">{t('adminPage.overview.noData')}</p>
              ) : (
                geo.topCountries.map((c) => (
                  <GeoBarRow key={c.code} label={`${c.label} (${c.code})`} value={c.users} max={maxCountry} />
                ))
              )}
            </div>
            <div className="rounded-3xl border p-5 space-y-2.5">
              <p className="text-sm font-medium mb-3">
                {t('adminPage.overview.topCities')}{focusLabel ? <span className="text-muted-foreground font-normal"> · {focusLabel}</span> : null}
              </p>
              {geo.topCities.length === 0 ? (
                <p className="text-xs text-muted-foreground">{t('adminPage.overview.noData')}</p>
              ) : (
                geo.topCities.map((c) => (
                  <GeoBarRow key={c.label} label={c.label} value={c.users} max={maxCity} />
                ))
              )}
            </div>
          </div>
          <p className="text-[11px] text-muted-foreground px-1">
            {t('adminPage.overview.geoSourceHint')}
          </p>
        </section>
      )}

      <section className="space-y-2">
        <h2 className="text-sm font-semibold text-muted-foreground px-1">{t('adminPage.overview.quickLinks')}</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {quickLinks.map(({ tab, icon: Icon, labelKey }) => (
            <button
              key={tab}
              type="button"
              onClick={() => onNavigateTab(tab)}
              className="rounded-2xl border p-3 text-left hover:bg-muted/40 transition-colors flex items-center gap-2.5 group"
            >
              <Icon className="h-4 w-4 text-primary group-hover:scale-110 transition-transform shrink-0" />
              <span className="text-sm font-medium truncate">{t(labelKey)}</span>
            </button>
          ))}
        </div>
        <p className="text-[11px] text-muted-foreground px-1">
          {t('adminPage.overview.analyticsLinkHint')}{' '}
          <button type="button" className="underline hover:text-foreground" onClick={() => onNavigateTab('analytics')}>
            {t('adminPage.overview.analyticsLinkText')}
          </button>{t('adminPage.overview.analyticsLinkSuffix')}
        </p>
      </section>
    </div>
  );
}
