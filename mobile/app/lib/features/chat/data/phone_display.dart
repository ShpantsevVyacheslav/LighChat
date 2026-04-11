/// Упрощённо как web `formatPhoneNumberForDisplay` / `applyPhoneMask` для RU.
String formatPhoneNumberForDisplay(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return '—';
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  var d = digits;
  if (d.startsWith('8') && d.length == 11) d = '7${d.substring(1)}';
  if (d.length == 10) d = '7$d';
  if (d.length < 11 || !d.startsWith('7')) return trimmed;

  final tail = d.substring(1);
  final a = tail.substring(0, 3);
  final b = tail.substring(3, 6);
  final c = tail.substring(6, 8);
  final e = tail.substring(8, 10);
  return '+7($a)$b-$c-$e';
}
