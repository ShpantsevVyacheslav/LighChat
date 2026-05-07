const String kLighchatWebHost = 'lighchat.online';
const String kLighchatWebHostWww = 'www.lighchat.online';

String _normalizeUsernameToken(String? raw) {
  return (raw ?? '').trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
}

bool _looksLikeUserIdToken(String token) {
  final v = token.trim();
  if (v.isEmpty) return false;
  if (v.startsWith('tg_') || v.startsWith('ya_')) return true;
  return RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(v);
}

String buildProfileShareUrl(String userId, {String? username}) {
  final uid = userId.trim();
  if (uid.isEmpty) return 'https://$kLighchatWebHost/dashboard/contacts';
  final normalizedUsername = _normalizeUsernameToken(username);
  if (normalizedUsername.isEmpty) {
    return 'https://$kLighchatWebHost/dashboard/contacts/${Uri.encodeComponent(uid)}';
  }
  return 'https://$kLighchatWebHost/dashboard/contacts/${Uri.encodeComponent(normalizedUsername)}';
}

String buildProfileQrPayload({required String userId, String? username}) {
  final uid = userId.trim();
  if (uid.isEmpty) return '';
  final cleanUsername = _normalizeUsernameToken(username);
  final url = Uri.parse(buildProfileShareUrl(uid, username: cleanUsername));
  if (cleanUsername.isEmpty) return url.toString();
  return url
      .replace(queryParameters: <String, String>{'u': cleanUsername})
      .toString();
}

class ProfileQrTarget {
  const ProfileQrTarget({this.userId, this.username});

  final String? userId;
  final String? username;
}

ProfileQrTarget extractProfileTargetFromQrPayload(String payload) {
  final raw = payload.trim();
  if (raw.isEmpty) return const ProfileQrTarget();

  final compact = raw.replaceAll(RegExp(r'\s+'), '');
  if (compact.startsWith('lighchat_profile:')) {
    final uid = compact.substring('lighchat_profile:'.length).trim();
    return ProfileQrTarget(userId: uid.isEmpty ? null : uid);
  }

  final uri = Uri.tryParse(raw);
  if (uri == null) return const ProfileQrTarget();

  final fromQuery = uri.queryParameters['uid'] ?? uri.queryParameters['userId'];
  final usernameQuery = _normalizeUsernameToken(
    uri.queryParameters['u'] ?? uri.queryParameters['username'],
  );
  if (fromQuery != null && fromQuery.trim().isNotEmpty) {
    return ProfileQrTarget(
      userId: Uri.decodeComponent(fromQuery.trim()),
      username: usernameQuery.isEmpty ? null : usernameQuery,
    );
  }

  if (uri.scheme.toLowerCase() == 'lighchat') {
    if (uri.host.toLowerCase() == 'profile') {
      if (uri.pathSegments.isNotEmpty) {
        final uid = uri.pathSegments.first.trim();
        if (uid.isNotEmpty) {
          return ProfileQrTarget(userId: Uri.decodeComponent(uid));
        }
      }
    }
  }

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments;
  if ((host == kLighchatWebHost || host == kLighchatWebHostWww) &&
      segments.length >= 3 &&
      segments[0] == 'dashboard' &&
      segments[1] == 'contacts') {
    final token = Uri.decodeComponent(segments[2]).trim();
    if (token.isEmpty) return const ProfileQrTarget();
    if (_looksLikeUserIdToken(token)) {
      return ProfileQrTarget(
        userId: token,
        username: usernameQuery.isEmpty ? null : usernameQuery,
      );
    }
    final fromPath = _normalizeUsernameToken(token);
    return ProfileQrTarget(
      username: fromPath.isEmpty
          ? (usernameQuery.isEmpty ? null : usernameQuery)
          : fromPath,
    );
  }

  if (segments.length >= 3 &&
      segments[0] == 'contacts' &&
      segments[1] == 'user') {
    final uid = segments[2].trim();
    if (uid.isNotEmpty) {
      return ProfileQrTarget(userId: Uri.decodeComponent(uid));
    }
  }

  return const ProfileQrTarget();
}

String? extractProfileUserIdFromQrPayload(String payload) {
  return extractProfileTargetFromQrPayload(payload).userId;
}
