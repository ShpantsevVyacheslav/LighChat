String? resolveMentionQueryFromAfterAt(
  String textAfterAt,
  List<String> participantNamesSortedLongestFirst,
) {
  final afterAt = textAfterAt;
  if (participantNamesSortedLongestFirst.isEmpty) {
    return afterAt;
  }
  for (final raw in participantNamesSortedLongestFirst) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    if (afterAt.startsWith('$name ')) {
      return null;
    }
    if (afterAt == name) {
      return null;
    }
  }
  return afterAt;
}

List<String> buildMentionBoundaryNameList(List<String> namesAndUsernames) {
  final uniq = <String>{};
  for (final s in namesAndUsernames) {
    final t = s.trim();
    if (t.isEmpty) continue;
    uniq.add(t);
  }
  final out = uniq.toList();
  out.sort((a, b) => b.length.compareTo(a.length));
  return out;
}

