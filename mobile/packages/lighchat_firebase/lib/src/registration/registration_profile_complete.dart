final _emailLike = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _usernameAllowed = RegExp(r'^[a-zA-Z0-9_]+$');

String _normalizedUsername(String raw) =>
    raw.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

bool isRegistrationProfileComplete({
  required String? name,
  required String? username,
  required String? phone,
  required String? email,
}) {
  final n = (name ?? '').trim();
  if (n.length < 2) return false;
  final u = _normalizedUsername(username ?? '');
  if (u.length < 3 || u.length > 30) return false;
  if (!_usernameAllowed.hasMatch(u)) return false;
  final e = (email ?? '').trim();
  if (e.isEmpty || !_emailLike.hasMatch(e)) return false;
  return true;
}
