'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';

export type DailyStats = {
  date: string;
  activeUsers: number;
  newRegistrations: number;
  messagesSent: number;
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
    console.error('[fetchAnalyticsAction]', e);
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
    console.error('[fetchAdminOverviewMetricsAction]', e);
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

    const devicesSnap = await adminDb.collectionGroup('e2eeDevices').get();

    const userCountry = new Map<string, string>();
    const userCity = new Map<string, string>();

    devicesSnap.docs.forEach((doc) => {
      const data = doc.data() as { lastLoginCountry?: string; lastLoginCity?: string; lastLoginAt?: string };
      const userId = doc.ref.parent.parent?.id;
      if (!userId) return;
      const country = (data.lastLoginCountry || '').toUpperCase().trim();
      const city = (data.lastLoginCity || '').trim();
      if (country) {
        if (!userCountry.has(userId)) userCountry.set(userId, country);
      }
      if (city) {
        if (!userCity.has(userId)) userCity.set(userId, `${city}|${country}`);
      }
    });

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
    console.error('[fetchAdminGeoMetricsAction]', e);
    return { ok: false, error: 'Ошибка загрузки геометрик' };
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
    console.error('[computeDailyStatsAction]', e);
    return { ok: false, error: 'Ошибка вычисления статистики' };
  }
}
