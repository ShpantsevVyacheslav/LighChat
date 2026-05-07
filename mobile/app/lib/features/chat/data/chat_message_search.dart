import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../ui/message_html_text.dart';
import 'new_chat_user_search.dart';

/// Паритет `ChatSearchOverlay`: только неудалённые, подстрока по plain-тексту, ru↔lat.
///
/// `decryptedTextByMessageId` — мап `messageId → plaintext` для E2EE-сообщений
/// (поступает из `E2eeMessagesResolver._decrypted`). У зашифрованных сообщений
/// `m.text` пустой — поле под ciphertext'ом, и без этой мапы фильтр всегда
/// возвращал бы 0 результатов. Если null — ведём себя как раньше (не-E2EE
/// чат / decrypt ещё не прошёл).
List<ChatMessage> filterMessagesForInChatSearch(
  List<ChatMessage> messages,
  String query, {
  Map<String, String>? decryptedTextByMessageId,
}) {
  final q = query.trim();
  if (q.length < 2) return const [];

  final out = <ChatMessage>[];
  for (final m in messages) {
    if (m.isDeleted) continue;
    final source = _resolveSearchableText(m, decryptedTextByMessageId);
    if (source.isEmpty) continue;
    final plain = source.contains('<') ? messageHtmlToPlainText(source) : source;
    if (!ruEnSubstringMatch(plain, q)) continue;
    out.add(m);
  }
  // Новые сверху (как web `.reverse()` после filter).
  return out.reversed.toList(growable: false);
}

/// Строка для строки результата (паритет подписи под превью).
String chatSearchResultSnippet(
  ChatMessage m,
  AppLocalizations l10n, {
  Map<String, String>? decryptedTextByMessageId,
}) {
  final raw = _resolveSearchableText(m, decryptedTextByMessageId);
  if (raw.isEmpty) {
    if (m.attachments.isNotEmpty) return l10n.chat_search_snippet_attachment;
    if (m.locationShare != null) return l10n.chat_search_snippet_location;
    return l10n.chat_search_snippet_message;
  }
  if (raw.contains('<')) {
    final p = messageHtmlToPlainText(raw).trim();
    return p.isEmpty ? l10n.chat_search_snippet_message : p;
  }
  return raw;
}

/// Возвращает HTML/plaintext для поиска: для E2EE-сообщений берём из мапы
/// расшифрованных значений (если она передана), иначе fallback на `m.text`.
String _resolveSearchableText(
  ChatMessage m,
  Map<String, String>? decryptedTextByMessageId,
) {
  final raw = (m.text ?? '').trim();
  if (raw.isNotEmpty) return raw;
  final decrypted = decryptedTextByMessageId?[m.id];
  if (decrypted == null) return '';
  return decrypted.trim();
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
