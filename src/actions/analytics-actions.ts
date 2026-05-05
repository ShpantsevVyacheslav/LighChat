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
