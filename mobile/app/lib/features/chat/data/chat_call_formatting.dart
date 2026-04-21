// Форматирование дат/длительности для экрана «Звонки» (в духе веб CallsHistoryPage + макет списка).

const List<String> _ruMonthsGenitive = <String>[
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String formatCallDetailDateRu(DateTime local) {
  final m = _ruMonthsGenitive[local.month - 1];
  return '${local.day} $m ${local.year}';
}

// Длительность как на вебе (formatDuration в src/lib/utils.ts).
String formatCallDurationSeconds(int seconds) {
  if (seconds < 0) return '0м';
  if (seconds < 60) return '$seconds с';
  final days = seconds ~/ 86400;
  var rest = seconds % 86400;
  final hours = rest ~/ 3600;
  rest %= 3600;
  final minutes = rest ~/ 60;
  final parts = <String>[];
  if (days > 0) parts.add('$days' 'д');
  if (hours > 0) parts.add('$hours' 'ч');
  if (minutes > 0 || (days == 0 && hours == 0)) {
    parts.add('$minutesм');
  }
  final s = parts.join(' ').trim();
  return s.isEmpty ? '0м' : s;
}

String _hm(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// Подпись строки списка: «Сегодня, HH:mm • mm:ss» (длительность только если есть интервал).
String formatCallListSubtitle({
  required DateTime createdLocal,
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
    datePart = 'Сегодня, ${_hm(createdLocal)}';
  } else if (d == yesterday) {
    datePart = 'Вчера, ${_hm(createdLocal)}';
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
