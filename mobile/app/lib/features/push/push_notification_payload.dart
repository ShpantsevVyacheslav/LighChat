/// Парсинг FCM `data` для deep link (паритет с web `parseConversationIdFromDashboardChatLink`).
String? conversationIdFromPushData(Map<String, dynamic> data) {
  final direct = data['conversationId'];
  if (direct != null) {
    final t = direct.toString().trim();
    if (t.isNotEmpty) return t;
  }
  final link = data['link'];
  if (link != null) {
    return parseConversationIdFromDashboardChatLink(link.toString());
  }
  return null;
}

String? parseConversationIdFromDashboardChatLink(String link) {
  if (link.isEmpty) return null;
  try {
    final uri = link.contains('://')
        ? Uri.parse(link)
        : Uri.parse('https://dummy.local${link.startsWith('/') ? '' : '/'}$link');
    final q = uri.queryParameters['conversationId'];
    if (q != null && q.trim().isNotEmpty) return q.trim();
  } catch (_) {}
  return null;
}
