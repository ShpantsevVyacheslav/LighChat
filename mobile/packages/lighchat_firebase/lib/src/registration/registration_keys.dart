import 'dart:convert';

String _normalizePhoneDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

String _utf8ToBase64Url(String s) {
  final bytes = utf8.encode(s);
  final b64 = base64.encode(bytes);
  return b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll(RegExp(r'=+$'), '');
}

/// Guest placeholder email does not participate in `registrationIndex`.
bool isAnonymousPlaceholderEmail(String email) {
  final e = email.trim().toLowerCase();
  return e.endsWith('@anonymous.com') && e.startsWith('guest_');
}

String? registrationPhoneKey(String phone) {
  final d = _normalizePhoneDigits(phone);
  if (d.length < 10) return null;
  return 'p_$d';
}

String? registrationEmailKey(String email) {
  final n = email.trim().toLowerCase();
  if (n.isEmpty || isAnonymousPlaceholderEmail(n)) return null;
  return 'e_${_utf8ToBase64Url(n)}';
}

String? registrationUsernameKey(String username) {
  final n = username.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
  if (n.isEmpty) return null;
  return 'u_$n';
}

