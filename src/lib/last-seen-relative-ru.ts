import { differenceInCalendarDays, differenceInMonths, startOfDay } from 'date-fns';

const PREFIX = 'Был(а) ';

/** 11–14 → родительный множественный (минут, часов, …). */
function isTeen(n: number): boolean {
  const m = n % 100;
  return m >= 11 && m <= 14;
}

function ruMinutesPhrase(n: number): string {
  if (n <= 0) return 'менее минуты назад';
  if (n === 1) return 'минуту назад';
  if (isTeen(n)) return `${n} минут назад`;
  const t = n % 10;
  if (t === 1) return `${n} минуту назад`;
  if (t >= 2 && t <= 4) return `${n} минуты назад`;
  return `${n} минут назад`;
}

function ruHoursPhrase(n: number): string {
  if (n <= 0) return 'менее часа назад';
  if (n === 1) return 'час назад';
  if (isTeen(n)) return `${n} часов назад`;
  const t = n % 10;
  if (t === 1) return `${n} час назад`;
  if (t >= 2 && t <= 4) return `${n} часа назад`;
  return `${n} часов назад`;
}

function ruDaysPhrase(n: number): string {
  if (isTeen(n)) return `${n} дней назад`;
  const t = n % 10;
  if (t === 1) return `${n} день назад`;
  if (t >= 2 && t <= 4) return `${n} дня назад`;
  return `${n} дней назад`;
}

/** Именительный для состава «X лет Y месяцев». */
function ruMonthsNominal(n: number): string {
  if (isTeen(n)) return `${n} месяцев`;
  const t = n % 10;
  if (t === 1) return `${n} месяц`;
  if (t >= 2 && t <= 4) return `${n} месяца`;
  return `${n} месяцев`;
}

function ruYearsNominal(n: number): string {
  if (isTeen(n)) return `${n} лет`;
  const t = n % 10;
  if (t === 1) return `${n} год`;
  if (t >= 2 && t <= 4) return `${n} года`;
  return `${n} лет`;
}

/**
 * Строка статуса «последняя активность» для профиля (относительное время по-русски).
 * Примеры: «Был(а) менее минуты назад», «Был(а) минуту назад», «Был(а) вчера», «Был(а) 1 год 7 месяцев назад».
 */
export function formatLastSeenStatusRu(lastSeen: Date, now: Date = new Date()): string {
  let diffMs = now.getTime() - lastSeen.getTime();
  if (diffMs < 0) diffMs = 0;

  const sec = Math.floor(diffMs / 1000);
  const min = Math.floor(diffMs / 60000);

  if (sec < 60) {
    return PREFIX + 'менее минуты назад';
  }
  if (min < 60) {
    return PREFIX + ruMinutesPhrase(min);
  }

  const calDays = differenceInCalendarDays(startOfDay(now), startOfDay(lastSeen));

  if (calDays === 0) {
    const hrs = Math.max(1, Math.floor(diffMs / 3600000));
    return PREFIX + ruHoursPhrase(hrs);
  }

  if (calDays === 1) {
    return PREFIX + 'вчера';
  }

  if (calDays >= 2 && calDays <= 30) {
    return PREFIX + ruDaysPhrase(calDays);
  }

  const totalMonths = differenceInMonths(now, lastSeen);

  if (totalMonths < 1) {
    return PREFIX + ruDaysPhrase(calDays);
  }

  if (totalMonths < 12) {
    if (totalMonths === 1) return PREFIX + '1 месяц назад';
    return PREFIX + `${ruMonthsNominal(totalMonths)} назад`;
  }

  const years = Math.floor(totalMonths / 12);
  const monthsRem = totalMonths % 12;

  if (monthsRem === 0) {
    return PREFIX + `${ruYearsNominal(years)} назад`;
  }

  return PREFIX + `${ruYearsNominal(years)} ${ruMonthsNominal(monthsRem)} назад`;
}
