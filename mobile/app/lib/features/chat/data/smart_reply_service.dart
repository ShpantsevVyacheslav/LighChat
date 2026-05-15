import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// On-device Smart Reply: 1–3 коротких варианта ответа на основе последних
/// сообщений диалога. Модель встроена в ML Kit SDK, ничего качать не нужно.
///
/// Качество: оптимизировано под английский. SDK сам решает «похож разговор
/// на английский» — если нет, вернёт `notSupportedLanguage`, мы покажем
/// пустой ряд (юзеру так и нужно).
///
/// E2EE-чаты: вызываем на расшифрованных `ChatMessage.text` локально,
/// на сервер plaintext не уходит.
class SmartReplyService {
  SmartReplyService._();
  static final SmartReplyService instance = SmartReplyService._();

  final SmartReply _engine = SmartReply();

  /// До 3 предложенных ответов на основе последних 10 сообщений диалога.
  /// `currentUserId` нужен чтобы SDK знал, какие сообщения «свои», а какие
  /// — от собеседника (Smart Reply работает только если последнее сообщение
  /// НЕ от текущего пользователя).
  Future<List<String>> suggest({
    required List<ChatMessage> messages,
    required String currentUserId,
  }) async {
    if (messages.isEmpty) return const [];
    final recent = messages
        .where((m) => !m.isDeleted && (m.text ?? '').trim().isNotEmpty)
        .toList();
    if (recent.isEmpty) return const [];
    final tail = recent.length <= 10
        ? recent
        : recent.sublist(recent.length - 10);

    if (tail.last.senderId == currentUserId) return const [];

    _engine.clearConversation();
    for (final m in tail) {
      final text = m.text!.trim();
      final ts = m.createdAt.millisecondsSinceEpoch;
      if (m.senderId == currentUserId) {
        _engine.addMessageToConversationFromLocalUser(text, ts);
      } else {
        _engine.addMessageToConversationFromRemoteUser(text, ts, m.senderId);
      }
    }

    try {
      final response = await _engine.suggestReplies();
      if (response.status != SmartReplySuggestionResultStatus.success) {
        return const [];
      }
      return response.suggestions
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Освобождаем native-ресурсы (вызывать при logout / app shutdown).
  Future<void> dispose() => _engine.close();
}
