/// Относительная строка «Был(а) …» для lastSeen (как на вебе).
String formatLastSeenStatusRu(DateTime lastSeen, [DateTime? now]) {
  final n = now ?? DateTime.now();
  var diffMs = n.millisecondsSinceEpoch - lastSeen.millisecondsSinceEpoch;
  if (diffMs < 0) diffMs = 0;

  final sec = diffMs ~/ 1000;
  final min = diffMs ~/ 60000;

  if (sec < 60) return '$_prefixменее минуты назад';
  if (min < 60) return '$_prefix${_ruMinutesPhrase(min)}';

  final calDays = _differenceInCalendarDays(n, lastSeen);

  if (calDays == 0) {
    final hrs = (diffMs ~/ 3600000).clamp(1, 999999);
    return '$_prefix${_ruHoursPhrase(hrs)}';
  }

  if (calDays == 1) return '$_prefixвчера';

  if (calDays >= 2 && calDays <= 30) {
    return '$_prefix${_ruDaysPhrase(calDays)}';
  }

  final totalMonths = _differenceInMonths(n, lastSeen);

  if (totalMonths < 1) {
    return '$_prefix${_ruDaysPhrase(calDays)}';
  }

  if (totalMonths < 12) {
    if (totalMonths == 1) return '${_prefix}1 месяц назад';
    return '$_prefix${_ruMonthsNominal(totalMonths)} назад';
  }

  final years = totalMonths ~/ 12;
  final monthsRem = totalMonths % 12;

  if (monthsRem == 0) {
    return '$_prefix${_ruYearsNominal(years)} назад';
  }

  return '$_prefix${_ruYearsNominal(years)} ${_ruMonthsNominal(monthsRem)} назад';
}

const _prefix = 'Был(а) ';

bool _isTeen(int n) {
  final m = n % 100;
  return m >= 11 && m <= 14;
}

int _differenceInCalendarDays(DateTime a, DateTime b) {
  final startA = DateTime(a.year, a.month, a.day);
  final startB = DateTime(b.year, b.month, b.day);
  return startA.difference(startB).inDays;
}

int _differenceInMonths(DateTime end, DateTime start) {
  var months = (end.year - start.year) * 12 + (end.month - start.month);
  if (end.day < start.day) months--;
  return months;
}

String _ruMinutesPhrase(int n) {
  if (n <= 0) return 'менее минуты назад';
  if (n == 1) return 'минуту назад';
  if (_isTeen(n)) return '$n минут назад';
  final t = n % 10;
  if (t == 1) return '$n минуту назад';
  if (t >= 2 && t <= 4) return '$n минуты назад';
  return '$n минут назад';
}

String _ruHoursPhrase(int n) {
  if (n <= 0) return 'менее часа назад';
  if (n == 1) return 'час назад';
  if (_isTeen(n)) return '$n часов назад';
  final t = n % 10;
  if (t == 1) return '$n час назад';
  if (t >= 2 && t <= 4) return '$n часа назад';
  return '$n часов назад';
}

String _ruDaysPhrase(int n) {
  if (_isTeen(n)) return '$n дней назад';
  final t = n % 10;
  if (t == 1) return '$n день назад';
  if (t >= 2 && t <= 4) return '$n дня назад';
  return '$n дней назад';
}

String _ruMonthsNominal(int n) {
  if (_isTeen(n)) return '$n месяцев';
  final t = n % 10;
  if (t == 1) return '$n месяц';
  if (t >= 2 && t <= 4) return '$n месяца';
  return '$n месяцев';
}

String _ruYearsNominal(int n) {
  if (_isTeen(n)) return '$n лет';
  final t = n % 10;
  if (t == 1) return '$n год';
  if (t >= 2 && t <= 4) return '$n года';
  return '$n лет';
}
