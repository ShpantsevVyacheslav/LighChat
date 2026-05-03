import '../../../l10n/app_localizations.dart';

/// Localized relative string for lastSeen (replaces `last_seen_relative_ru.dart`).
String formatLastSeenStatus(DateTime lastSeen, AppLocalizations l10n, [DateTime? now]) {
  final n = now ?? DateTime.now();
  var diffMs = n.millisecondsSinceEpoch - lastSeen.millisecondsSinceEpoch;
  if (diffMs < 0) diffMs = 0;

  final sec = diffMs ~/ 1000;
  final min = diffMs ~/ 60000;

  final prefix = l10n.presence_last_seen_prefix;

  if (sec < 60) return '$prefix${l10n.presence_less_than_minute_ago}';
  if (min < 60) return '$prefix${l10n.presence_minutes_ago(min)}';

  final calDays = _differenceInCalendarDays(n, lastSeen);

  if (calDays == 0) {
    final hrs = (diffMs ~/ 3600000).clamp(1, 999999);
    return '$prefix${l10n.presence_hours_ago(hrs)}';
  }

  if (calDays == 1) return '$prefix${l10n.presence_yesterday}';

  if (calDays >= 2 && calDays <= 30) {
    return '$prefix${l10n.presence_days_ago(calDays)}';
  }

  final totalMonths = _differenceInMonths(n, lastSeen);

  if (totalMonths < 1) {
    return '$prefix${l10n.presence_days_ago(calDays)}';
  }

  if (totalMonths < 12) {
    return '$prefix${l10n.presence_months_ago(totalMonths)}';
  }

  final years = totalMonths ~/ 12;
  final monthsRem = totalMonths % 12;

  if (monthsRem == 0) {
    return '$prefix${l10n.presence_years_ago(years)}';
  }

  return '$prefix${l10n.presence_years_months_ago(years, monthsRem)}';
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
