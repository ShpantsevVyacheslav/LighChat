/// Паритет с `src/lib/username-candidate.ts` (web).
String usernameLocalPartFromMaybeEmail(String raw) {
  var s = raw.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
  final at = s.indexOf('@');
  if (at != -1) {
    s = s.substring(0, at).trim();
  }
  return s;
}

String normalizeUsernameCandidate(String raw) {
  var base = usernameLocalPartFromMaybeEmail(raw);
  base = base
      .replaceAll(RegExp(r'[^a-z0-9_.]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'\.{2,}'), '.')
      .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
  if (base.length > 30) {
    base = base.substring(0, 30);
  }
  return base;
}

bool isNormalizedUsernameTokenAllowed(String normalized) {
  final s = normalized.trim();
  if (s.length < 3 || s.length > 30) return false;
  if (!RegExp(r'^[a-z0-9][a-z0-9._]*[a-z0-9]$').hasMatch(s)) return false;
  if (s.contains('..')) return false;
  return true;
}
