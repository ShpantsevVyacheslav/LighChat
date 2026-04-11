import 'package:lighchat_models/lighchat_models.dart';

/// Mirrors [src/lib/chat-pinned-messages.ts].
const int maxPinnedMessages = 20;

List<PinnedMessage> conversationPinnedList(Conversation c) {
  final arr = c.pinnedMessages;
  if (arr != null && arr.isNotEmpty) {
    return _dedupePinsPreserveOrder(arr);
  }
  final legacy = c.legacyPinnedMessage;
  if (legacy != null && legacy.messageId.isNotEmpty) {
    return [legacy];
  }
  return const <PinnedMessage>[];
}

List<PinnedMessage> _dedupePinsPreserveOrder(List<PinnedMessage> pins) {
  final seen = <String>{};
  final out = <PinnedMessage>[];
  for (final p in pins) {
    if (p.messageId.isEmpty || seen.contains(p.messageId)) continue;
    seen.add(p.messageId);
    out.add(p);
  }
  return out;
}

List<PinnedMessage> sortPinnedMessagesByTime(List<PinnedMessage> pins, Map<String, ChatMessage> messagesById) {
  String keyFor(PinnedMessage p) {
    final fromMsg = messagesById[p.messageId]?.createdAt.toUtc().toIso8601String();
    if (fromMsg != null && fromMsg.isNotEmpty) return fromMsg;
    return p.messageCreatedAt ?? '';
  }

  final copy = [...pins];
  copy.sort((a, b) => keyFor(a).compareTo(keyFor(b)));
  return copy;
}
