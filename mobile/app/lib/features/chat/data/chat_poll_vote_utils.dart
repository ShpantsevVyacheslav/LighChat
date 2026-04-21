/// Паритет `src/lib/chat-poll-votes.ts`.
int countVotesForOption(Map<String, List<int>> votes, int optionIdx) {
  var n = 0;
  for (final sel in votes.values) {
    if (sel.contains(optionIdx)) n++;
  }
  return n;
}

bool userHasVoted(Map<String, List<int>> votes, String userId) {
  if (userId.isEmpty) return false;
  return (votes[userId] ?? const <int>[]).isNotEmpty;
}

bool userSelectedOption(Map<String, List<int>> votes, String userId, int idx) {
  return votes[userId]?.contains(idx) ?? false;
}

/// Детерминированный порядок строк для shuffle.
List<int> chatPollDisplayIndices({
  required String pollId,
  required String userId,
  required int optionCount,
  required bool shuffle,
}) {
  if (!shuffle || optionCount <= 1 || userId.isEmpty) {
    return List<int>.generate(optionCount, (i) => i);
  }
  final base = List<int>.generate(optionCount, (i) => i);
  var s = _hashString('$pollId:$userId');
  for (var i = optionCount - 1; i > 0; i--) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    final j = s % (i + 1);
    final t = base[i];
    base[i] = base[j];
    base[j] = t;
  }
  return base;
}

int _hashString(String str) {
  var h = 0;
  for (var i = 0; i < str.length; i++) {
    h = (31 * h + str.codeUnitAt(i)) & 0x7fffffff;
  }
  return h.abs();
}
