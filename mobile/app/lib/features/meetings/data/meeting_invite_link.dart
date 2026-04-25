/// Публичный URL веб-клиента для входа в ту же комнату, что и в приложении.
/// Путь совпадает с Next.js (`/meetings/[meetingId]`) и с web `MeetingRoom` copy-link.
const String kMeetingWebAppOrigin = 'https://lighchat.online';

/// Хосты, по которым включены Universal Links / App Links (должны совпадать с AASA / assetlinks на сервере).
const Set<String> kMeetingWebLinkHosts = {
  'lighchat.online',
  'www.lighchat.online',
};

String meetingWebJoinLink(String meetingId) {
  final id = meetingId.trim();
  if (id.isEmpty) return kMeetingWebAppOrigin;
  return '$kMeetingWebAppOrigin/meetings/$id';
}

/// Разбирает `https://lighchat.online/meetings/{id}` → `/meetings/{id}` для [GoRouter].
/// Возвращает `null`, если URI не относится к комнате на нашем веб-домене.
String? goRouterPathFromMeetingWebUri(Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!kMeetingWebLinkHosts.contains(uri.host.toLowerCase())) return null;
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.length < 2 || segs[0] != 'meetings') return null;
  final id = segs[1].trim();
  if (id.isEmpty) return null;
  return '/meetings/$id';
}
