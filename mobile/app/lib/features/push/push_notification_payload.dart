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

String? callIdFromPushData(Map<String, dynamic> data) {
  final direct = data['callId'];
  if (direct != null) {
    final t = direct.toString().trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}

bool isCallPushData(Map<String, dynamic> data) {
  return callIdFromPushData(data) != null;
}

bool isVideoCallFromPushData(Map<String, dynamic> data) {
  final raw = data['isVideo']?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return false;
  return raw == '1' || raw == 'true' || raw == 'video';
}

String callerNameFromPushData(Map<String, dynamic> data) {
  final callerName = data['callerName']?.toString().trim();
  if (callerName != null && callerName.isNotEmpty) {
    return callerName;
  }
  final body = data['body']?.toString().trim();
  if (body != null && body.isNotEmpty) {
    return body
        .replaceFirst(RegExp(r'^\s*Вам звонит\s*', caseSensitive: false), '')
        .trim();
  }
  return 'Кто-то';
}

String? parseConversationIdFromDashboardChatLink(String link) {
  if (link.isEmpty) return null;
  try {
    final uri = link.contains('://')
        ? Uri.parse(link)
        : Uri.parse(
            'https://dummy.local${link.startsWith('/') ? '' : '/'}$link',
          );
    final q = uri.queryParameters['conversationId'];
    if (q != null && q.trim().isNotEmpty) return q.trim();
  } catch (_) {}
  return null;
}
