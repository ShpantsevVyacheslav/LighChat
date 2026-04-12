import 'package:lighchat_models/lighchat_models.dart';

/// Mirrors [src/lib/chat-pinned-messages.ts].
const int maxPinnedMessages = 20;

/// Календарный ключ дня — как [ChatMessageList.dayKey] (должен совпадать с лентой).
String pinSyncDayKey(DateTime dt) {
  final d = dt.toLocal();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Плоские строки как на вебе [buildChatListRows] (date + message), без unread-separator в мобилке.
/// `null` = синтетическая строка «дата» перед первым сообщением дня.
List<String?> buildChatPinSyncFlatRows(List<ChatMessage> ascChronological) {
  final rows = <String?>[];
  var lastDay = '';
  for (final m in ascChronological) {
    final dk = pinSyncDayKey(m.createdAt);
    if (dk != lastDay) {
      rows.add(null);
      lastDay = dk;
    }
    rows.add(m.id);
  }
  return rows;
}

/// Паритет [pickPinnedBarIndexForViewport] из `src/lib/chat-pinned-messages.ts`.
int pickPinnedBarIndexForViewport(
  List<PinnedMessage> pinsSorted,
  List<String?> flatRows,
  int rangeStart,
  int rangeEnd,
) {
  if (pinsSorted.isEmpty) return 0;

  int indexInFlat(String msgId) {
    for (var i = 0; i < flatRows.length; i++) {
      if (flatRows[i] == msgId) return i;
    }
    return -1;
  }

  final withIdx = <({int i, int idx})>[];
  for (var pi = 0; pi < pinsSorted.length; pi++) {
    final idx = indexInFlat(pinsSorted[pi].messageId);
    if (idx != -1) withIdx.add((i: pi, idx: idx));
  }

  if (withIdx.isEmpty) return pinsSorted.length - 1;

  final strictlyOlder =
      withIdx.where((x) => x.idx < rangeStart).toList(growable: false);
  if (strictlyOlder.isNotEmpty) {
    return strictlyOlder.reduce((a, b) => a.idx > b.idx ? a : b).i;
  }

  final inView = withIdx
      .where((x) => x.idx >= rangeStart && x.idx <= rangeEnd)
      .toList(growable: false);
  if (inView.isNotEmpty) {
    return inView.reduce((a, b) => a.idx < b.idx ? a : b).i;
  }

  return withIdx.reduce((a, b) => a.idx < b.idx ? a : b).i;
}

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
