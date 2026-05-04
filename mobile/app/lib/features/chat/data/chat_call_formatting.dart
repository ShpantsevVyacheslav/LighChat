import '../../../l10n/app_localizations.dart';
// Форматирование дат/длительности для экрана «Звонки» (в духе веб CallsHistoryPage + макет списка).

List<String> _localizedMonths(AppLocalizations l10n) => [
  l10n.call_month_january, l10n.call_month_february, l10n.call_month_march,
  l10n.call_month_april, l10n.call_month_may, l10n.call_month_june,
  l10n.call_month_july, l10n.call_month_august, l10n.call_month_september,
  l10n.call_month_october, l10n.call_month_november, l10n.call_month_december,
];

String formatCallDetailDateRu(DateTime local, AppLocalizations l10n) {
  final months = _localizedMonths(l10n);
  final m = months[local.month - 1];
  return '${local.day} $m ${local.year}';
}

// Длительность как на вебе (formatDuration в src/lib/utils.ts).
String formatCallDurationSeconds(int seconds, AppLocalizations l10n) {
  if (seconds < 0) return '0${l10n.call_format_minute_short}';
  if (seconds < 60) return '$seconds ${l10n.call_format_second_short}';
  final days = seconds ~/ 86400;
  var rest = seconds % 86400;
  final hours = rest ~/ 3600;
  rest %= 3600;
  final minutes = rest ~/ 60;
  final parts = <String>[];
  if (days > 0) parts.add('$days${l10n.call_format_day_short}');
  if (hours > 0) parts.add('$hours${l10n.call_format_hour_short}');
  if (minutes > 0 || (days == 0 && hours == 0)) {
    parts.add('$minutes${l10n.call_format_minute_short}');
  }
  final s = parts.join(' ').trim();
  return s.isEmpty ? '0${l10n.call_format_minute_short}' : s;
}

String _hm(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// Подпись строки списка: «Сегодня, HH:mm • mm:ss» (длительность только если есть интервал).
String formatCallListSubtitle({
  required DateTime createdLocal,
  required AppLocalizations l10n,
  DateTime? startedAt,
  DateTime? endedAt,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(
    createdLocal.year,
    createdLocal.month,
    createdLocal.day,
  );
  final yesterday = today.subtract(const Duration(days: 1));

  String datePart;
  if (d == today) {
    datePart = '${l10n.call_format_today}, ${_hm(createdLocal)}';
  } else if (d == yesterday) {
    datePart = '${l10n.call_format_yesterday}, ${_hm(createdLocal)}';
  } else {
    datePart =
        '${createdLocal.day.toString().padLeft(2, '0')}.'
        '${createdLocal.month.toString().padLeft(2, '0')}.'
        '${createdLocal.year.toString().substring(2)} ${_hm(createdLocal)}';
  }

  if (startedAt != null && endedAt != null) {
    final sec = endedAt.difference(startedAt).inSeconds;
    if (sec > 0) {
      final mm = sec ~/ 60;
      final ss = sec % 60;
      final dur = '${mm.toString()}:${ss.toString().padLeft(2, '0')}';
      return '$datePart • $dur';
    }
  }
  return datePart;
}
