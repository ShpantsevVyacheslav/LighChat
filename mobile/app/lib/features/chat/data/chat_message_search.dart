import 'package:lighchat_models/lighchat_models.dart';

import '../ui/message_html_text.dart';
import 'new_chat_user_search.dart';

/// Паритет `ChatSearchOverlay`: только неудалённые, подстрока по plain-тексту, ru↔lat.
List<ChatMessage> filterMessagesForInChatSearch(
  List<ChatMessage> messages,
  String query,
) {
  final q = query.trim();
  if (q.length < 2) return const [];

  final out = <ChatMessage>[];
  for (final m in messages) {
    if (m.isDeleted) continue;
    final raw = (m.text ?? '').trim();
    final plain = raw.contains('<') ? messageHtmlToPlainText(raw) : raw;
    if (!ruEnSubstringMatch(plain, q)) continue;
    out.add(m);
  }
  // Новые сверху (как web `.reverse()` после filter).
  return out.reversed.toList(growable: false);
}

/// Строка для строки результата (паритет подписи под превью).
String chatSearchResultSnippet(ChatMessage m) {
  final raw = (m.text ?? '').trim();
  if (raw.isEmpty) {
    if (m.attachments.isNotEmpty) return 'Вложение';
    if (m.locationShare != null) return 'Геолокация';
    return 'Сообщение';
  }
  if (raw.contains('<')) {
    final p = messageHtmlToPlainText(raw).trim();
    return p.isEmpty ? 'Сообщение' : p;
  }
  return raw;
}

/// `dd.MM.yy HH:mm` как на вебе (`ChatSearchOverlay` + date-fns ru).
String formatChatSearchResultTimestamp(DateTime dt) {
  final l = dt.toLocal();
  final dd = l.day.toString().padLeft(2, '0');
  final mm = l.month.toString().padLeft(2, '0');
  final yy = (l.year % 100).toString().padLeft(2, '0');
  final hh = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$dd.$mm.$yy $hh:$min';
}
