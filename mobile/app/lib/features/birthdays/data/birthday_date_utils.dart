/// Парсит строковую дату ДР (`YYYY-MM-DD` или с timestamp) в `DateTime`.
/// Возвращает `null` если формат не распознан или год явно нерелевантен
/// (1900 как sentinel "год скрыт" — мы оставляем сам объект, но UI решает,
/// показывать ли возраст).
DateTime? parseDobString(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return DateTime.utc(parsed.year, parsed.month, parsed.day);
  // Fallback for `DD.MM.YYYY` (legacy clients).
  final m = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$').firstMatch(trimmed);
  if (m != null) {
    final d = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final y = int.tryParse(m.group(3)!);
    if (d != null && mo != null && y != null) {
      return DateTime.utc(y, mo, d);
    }
  }
  return null;
}

/// Возвращает `true` если день рождения [dob] совпадает с локальным
/// "сегодня". Особый случай — 29 февраля в невисокосный год: засчитываем
/// 28 февраля как ДР, чтобы плашка не пропадала на 3-4 года подряд.
bool isBirthdayToday(DateTime dob, DateTime now) {
  if (dob.month == now.month && dob.day == now.day) return true;
  final isLeapBirthday = dob.month == 2 && dob.day == 29;
  if (!isLeapBirthday) return false;
  final isLeapYearNow = (now.year % 4 == 0 && now.year % 100 != 0) ||
      (now.year % 400 == 0);
  if (isLeapYearNow) return false;
  return now.month == 2 && now.day == 28;
}

/// Считаем "возраст в этом году" по правилу `currentYear - birthYear`.
/// Возвращает `null` если год явно отсутствует (sentinel 1900 или меньше
/// 1900) — для отображения "День рождения сегодня" без числа лет.
int? ageInYear(DateTime dob, DateTime now) {
  if (dob.year < 1900) return null;
  return now.year - dob.year;
}

/// `YYYY-MM-DD` локальной даты (для сравнения "сегодня"). Не `toUtc()` —
/// плашка ДР живёт в часовом поясе пользователя.
String localYmd(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
