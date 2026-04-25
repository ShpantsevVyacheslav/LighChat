import 'username_candidate.dart';

final _emailLike = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isRegistrationProfileComplete({
  required String? name,
  required String? username,
  required String? phone,
  required String? email,
}) {
  final n = (name ?? '').trim();
  if (n.length < 2) return false;
  final u = normalizeUsernameCandidate(username ?? '');
  if (!isNormalizedUsernameTokenAllowed(u)) return false;
  final e = (email ?? '').trim();
  if (e.isEmpty || !_emailLike.hasMatch(e)) return false;
  return true;
}
