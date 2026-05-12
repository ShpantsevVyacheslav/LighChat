'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logger } from '@/lib/logger';

export type DailyStats = {
  date: string;
  activeUsers: number;
  newRegistrations: number;
  messagesSent: number;
  chatsCreated?: number;
  callsStarted?: number;
  meetingsHeld?: number;
  breakdownByPlatform?: Record<string, number>;
  breakdownByCountry?: { code: string; count: number }[];
  breakdownBySignupMethod?: Record<string, number>;
};

export type AnalyticsSummary = {
  totalUsers: number;
  onlineNow: number;
  activeToday: number;
  newToday: number;
  dailyStats: DailyStats[];
};

export async function fetchAnalyticsAction(input: {
  idToken: string;
  days?: number;
}): Promise<{ ok: true; data: AnalyticsSummary } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const days = input.days ?? 30;
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();

    const usersSnap = await adminDb.collection('users')
      .where('deletedAt', '==', null)
      .get();

    const totalUsers = usersSnap.size;
    let onlineNow = 0;
    let activeToday = 0;
    let newToday = 0;

    usersSnap.docs.forEach((doc) => {
      const data = doc.data();
      if (data.online === true) onlineNow++;
      if (data.lastSeen && data.lastSeen >= todayStart) activeToday++;
      if (data.createdAt && data.createdAt >= todayStart) newToday++;
    });

    const dailyStats: DailyStats[] = [];
    const statsSnap = await adminDb
      .collection('platformStats')
      .doc('daily')
      .collection('entries')
      .orderBy('date', 'desc')
      .limit(days)
      .get();

    statsSnap.docs.forEach((doc) => {
      dailyStats.push(doc.data() as DailyStats);
    });
    dailyStats.reverse();

    return {
      ok: true,
      data: { totalUsers, onlineNow, activeToday, newToday, dailyStats },
    };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchAnalyticsAction', e);
    return { ok: false, error: 'Ошибка загрузки аналитики' };
  }
}

export type AdminOverviewMetrics = {
  pendingReports: number;
  openTickets: number;
  blockedUsers: number;
};

export async function fetchAdminOverviewMetricsAction(input: {
  idToken: string;
}): Promise<{ ok: true; data: AdminOverviewMetrics } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    const [reportsSnap, ticketsInProgressSnap, ticketsOpenSnap, usersSnap] = await Promise.all([
      adminDb.collection('messageReports').where('status', '==', 'pending').count().get(),
      adminDb.collection('supportTickets').where('status', '==', 'in_progress').count().get(),
      adminDb.collection('supportTickets').where('status', '==', 'open').count().get(),
      adminDb.collection('users').where('accountBlock.active', '==', true).get(),
    ]);

    const nowMs = Date.now();
    let blockedUsers = 0;
    usersSnap.docs.forEach((doc) => {
      const data = doc.data() as { accountBlock?: { active?: boolean; until?: string | null } };
      const block = data.accountBlock;
      if (!block?.active) return;
      if (block.until == null) {
        blockedUsers++;
        return;
      }
      const untilMs = new Date(block.until).getTime();
      if (Number.isFinite(untilMs) && untilMs > nowMs) blockedUsers++;
    });

    return {
      ok: true,
      data: {
        pendingReports: reportsSnap.data().count,
        openTickets: ticketsOpenSnap.data().count + ticketsInProgressSnap.data().count,
        blockedUsers,
      },
    };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchAdminOverviewMetricsAction', e);
    return { ok: false, error: 'Ошибка загрузки метрик' };
  }
}

export type GeoBucket = { code: string; label: string; users: number };

export type AdminGeoMetrics = {
  totalKnown: number;
  unknown: number;
  topCountries: GeoBucket[];
  topCities: GeoBucket[];
  topCountryCode: string | null;
};

const COUNTRY_LABELS: Record<string, string> = {
  RU: 'Россия', BY: 'Беларусь', KZ: 'Казахстан', UA: 'Украина', UZ: 'Узбекистан',
  KG: 'Кыргызстан', AM: 'Армения', AZ: 'Азербайджан', GE: 'Грузия', MD: 'Молдова',
  TJ: 'Таджикистан', TM: 'Туркменистан', US: 'США', DE: 'Германия', GB: 'Великобритания',
  FR: 'Франция', IT: 'Италия', ES: 'Испания', PL: 'Польша', TR: 'Турция',
  IL: 'Израиль', CN: 'Китай', IN: 'Индия', AE: 'ОАЭ', CA: 'Канада', NL: 'Нидерланды',
  CZ: 'Чехия', RS: 'Сербия', LV: 'Латвия', LT: 'Литва', EE: 'Эстония', FI: 'Финляндия',
};

export async function fetchAdminGeoMetricsAction(input: {
  idToken: string;
  topCountryCode?: string | null;
}): Promise<{ ok: true; data: AdminGeoMetrics } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    // SECURITY: read geo from the PRIVATE `users/{uid}/devices` collection,
    // not from the world-readable e2eeDevices. New writes go to `devices`
    // (see confirmQrLogin / updateDeviceLastLocation). To keep the dashboard
    // useful during the migration window, we also read e2eeDevices as a
    // fallback — but never trust public-side fields preferentially. Once the
    // backfill has run and existing e2eeDevices docs are scrubbed, the
    // fallback can be removed.
    const [privateSnap, legacySnap] = await Promise.all([
      adminDb.collectionGroup('devices').get(),
      adminDb.collectionGroup('e2eeDevices').get(),
    ]);

    const userCountry = new Map<string, string>();
    const userCity = new Map<string, string>();

    const ingest = (doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const data = doc.data() as { lastLoginCountry?: string; lastLoginCity?: string; lastLoginAt?: string };
      const userId = doc.ref.parent.parent?.id;
      if (!userId) return;
      const country = (data.lastLoginCountry || '').toUpperCase().trim();
      const city = (data.lastLoginCity || '').trim();
      if (country && !userCountry.has(userId)) userCountry.set(userId, country);
      if (city && !userCity.has(userId)) userCity.set(userId, `${city}|${country}`);
    };
    // Private collection wins (newer, authoritative); legacy fills the gaps.
    privateSnap.docs.forEach(ingest);
    legacySnap.docs.forEach(ingest);

    const countryCounts = new Map<string, number>();
    userCountry.forEach((c) => countryCounts.set(c, (countryCounts.get(c) ?? 0) + 1));

    const topCountries: GeoBucket[] = Array.from(countryCounts.entries())
      .map(([code, users]) => ({ code, label: COUNTRY_LABELS[code] ?? code, users }))
      .sort((a, b) => b.users - a.users)
      .slice(0, 10);

    const totalKnown = userCountry.size;
    const focusCountry = (input.topCountryCode || topCountries[0]?.code || '').toUpperCase();

    const cityCounts = new Map<string, number>();
    userCity.forEach((cityKey) => {
      const [city, country] = cityKey.split('|');
      if (focusCountry && country !== focusCountry) return;
      cityCounts.set(city, (cityCounts.get(city) ?? 0) + 1);
    });

    const topCities: GeoBucket[] = Array.from(cityCounts.entries())
      .map(([label, users]) => ({ code: label, label, users }))
      .sort((a, b) => b.users - a.users)
      .slice(0, 10);

    const usersTotal = await adminDb.collection('users').where('deletedAt', '==', null).count().get();

    return {
      ok: true,
      data: {
        totalKnown,
        unknown: Math.max(0, usersTotal.data().count - totalKnown),
        topCountries,
        topCities,
        topCountryCode: focusCountry || null,
      },
    };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchAdminGeoMetricsAction', e);
    return { ok: false, error: 'Ошибка загрузки геометрик' };
  }
}

export type EngagementMetrics = {
  totalMessages30d: number;
  totalChats30d: number;
  totalCalls30d: number;
  totalMeetings30d: number;
  avgMessagesPerActiveUser30d: number;
};

export async function fetchEngagementMetricsAction(input: {
  idToken: string;
}): Promise<{ ok: true; data: EngagementMetrics } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const statsSnap = await adminDb
      .collection('platformStats')
      .doc('daily')
      .collection('entries')
      .orderBy('date', 'desc')
      .limit(30)
      .get();

    let totalMessages = 0;
    let totalChats = 0;
    let totalCalls = 0;
    let totalMeetings = 0;
    let totalActive = 0;

    statsSnap.docs.forEach((doc) => {
      const d = doc.data() as DailyStats;
      totalMessages += d.messagesSent ?? 0;
      totalChats += d.chatsCreated ?? 0;
      totalCalls += d.callsStarted ?? 0;
      totalMeetings += d.meetingsHeld ?? 0;
      totalActive += d.activeUsers ?? 0;
    });

    const avg = totalActive > 0 ? +(totalMessages / totalActive).toFixed(1) : 0;

    return {
      ok: true,
      data: {
        totalMessages30d: totalMessages,
        totalChats30d: totalChats,
        totalCalls30d: totalCalls,
        totalMeetings30d: totalMeetings,
        avgMessagesPerActiveUser30d: avg,
      },
    };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchEngagementMetricsAction', e);
    return { ok: false, error: 'Ошибка загрузки метрик engagement' };
  }
}

export type PlatformBreakdown = {
  platform: string;
  count: number;
};

export async function fetchPlatformBreakdownAction(input: {
  idToken: string;
  days?: number;
}): Promise<{ ok: true; data: PlatformBreakdown[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const days = input.days ?? 30;
    const statsSnap = await adminDb
      .collection('platformStats')
      .doc('daily')
      .collection('entries')
      .orderBy('date', 'desc')
      .limit(days)
      .get();

    const totals: Record<string, number> = {};
    statsSnap.docs.forEach((doc) => {
      const d = doc.data() as DailyStats;
      const b = d.breakdownByPlatform ?? {};
      for (const [k, v] of Object.entries(b)) {
        totals[k] = (totals[k] ?? 0) + (typeof v === 'number' ? v : 0);
      }
    });

    const data: PlatformBreakdown[] = Object.entries(totals)
      .map(([platform, count]) => ({ platform, count }))
      .sort((a, b) => b.count - a.count);

    return { ok: true, data };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchPlatformBreakdownAction', e);
    return { ok: false, error: 'Ошибка загрузки платформ' };
  }
}

export type SignupFunnel = {
  date: string;
  method: string;
  count: number;
};

export async function fetchSignupFunnelAction(input: {
  idToken: string;
  days?: number;
}): Promise<{ ok: true; data: SignupFunnel[] } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);
    const days = input.days ?? 30;
    const statsSnap = await adminDb
      .collection('platformStats')
      .doc('daily')
      .collection('entries')
      .orderBy('date', 'desc')
      .limit(days)
      .get();

    const out: SignupFunnel[] = [];
    statsSnap.docs.forEach((doc) => {
      const d = doc.data() as DailyStats;
      const breakdown = d.breakdownBySignupMethod ?? {};
      for (const [method, count] of Object.entries(breakdown)) {
        if (typeof count === 'number' && count > 0) {
          out.push({ date: d.date, method, count });
        }
      }
    });

    return { ok: true, data: out };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'fetchSignupFunnelAction', e);
    return { ok: false, error: 'Ошибка загрузки воронки регистраций' };
  }
}

export async function computeDailyStatsAction(input: {
  idToken: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    await assertAdminByIdToken(input.idToken);

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();

    const usersSnap = await adminDb.collection('users')
      .where('deletedAt', '==', null)
      .get();

    let activeUsers = 0;
    let newRegistrations = 0;

    usersSnap.docs.forEach((doc) => {
      const data = doc.data();
      if (data.lastSeen && data.lastSeen >= todayStart) activeUsers++;
      if (data.createdAt && data.createdAt >= todayStart) newRegistrations++;
    });

    const stats: DailyStats = {
      date: todayStr,
      activeUsers,
      newRegistrations,
      messagesSent: 0,
    };

    await adminDb
      .collection('platformStats')
      .doc('daily')
      .collection('entries')
      .doc(todayStr)
      .set(stats, { merge: true });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    logger.error('analytics', 'computeDailyStatsAction', e);
    return { ok: false, error: 'Ошибка вычисления статистики' };
  }
}
