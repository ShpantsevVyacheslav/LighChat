const String kLighchatWebHost = 'lighchat.online';
const String kLighchatWebHostWww = 'www.lighchat.online';

String buildProfileShareUrl(String userId) {
  final uid = userId.trim();
  if (uid.isEmpty) return 'https://$kLighchatWebHost/dashboard/contacts';
  return 'https://$kLighchatWebHost/dashboard/contacts/${Uri.encodeComponent(uid)}';
}

String buildProfileQrPayload({required String userId, String? username}) {
  final uid = userId.trim();
  if (uid.isEmpty) return '';
  final url = Uri.parse(buildProfileShareUrl(uid));
  final cleanUsername = (username ?? '').trim().replaceFirst(RegExp(r'^@'), '');
  if (cleanUsername.isEmpty) return url.toString();
  return url
      .replace(queryParameters: <String, String>{'u': cleanUsername})
      .toString();
}

String? extractProfileUserIdFromQrPayload(String payload) {
  final raw = payload.trim();
  if (raw.isEmpty) return null;

  final compact = raw.replaceAll(RegExp(r'\s+'), '');
  if (compact.startsWith('lighchat_profile:')) {
    final uid = compact.substring('lighchat_profile:'.length).trim();
    return uid.isEmpty ? null : uid;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final fromQuery = uri.queryParameters['uid'] ?? uri.queryParameters['userId'];
  if (fromQuery != null && fromQuery.trim().isNotEmpty) {
    return Uri.decodeComponent(fromQuery.trim());
  }

  if (uri.scheme.toLowerCase() == 'lighchat') {
    if (uri.host.toLowerCase() == 'profile') {
      if (uri.pathSegments.isNotEmpty) {
        final uid = uri.pathSegments.first.trim();
        if (uid.isNotEmpty) return Uri.decodeComponent(uid);
      }
    }
  }

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments;
  if ((host == kLighchatWebHost || host == kLighchatWebHostWww) &&
      segments.length >= 3 &&
      segments[0] == 'dashboard' &&
      segments[1] == 'contacts') {
    final uid = segments[2].trim();
    if (uid.isNotEmpty) return Uri.decodeComponent(uid);
  }

  if (segments.length >= 3 &&
      segments[0] == 'contacts' &&
      segments[1] == 'user') {
    final uid = segments[2].trim();
    if (uid.isNotEmpty) return Uri.decodeComponent(uid);
  }

  return null;
}
