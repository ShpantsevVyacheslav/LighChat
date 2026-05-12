/// Раскладка вкладок шторки митинга. Чисто-логическая структура, вынесена
/// из UI, чтобы быть unit-тестируемой.
///
/// Правила:
///   - `Members` есть всегда (индекс 0).
///   - `Requests` показывается **только** в приватных встречах
///     (`isPrivate == true`) для host/admin; идёт сразу после `Members`.
///   - `Polls` и `Chat` идут далее в стабильном порядке.
class MeetingSidebarTabsLayout {
  const MeetingSidebarTabsLayout({
    required this.showRequests,
    required this.participantsIndex,
    required this.requestsIndex,
    required this.pollsIndex,
    required this.chatIndex,
  });

  final bool showRequests;
  final int participantsIndex;

  /// `-1` если вкладки `Requests` нет.
  final int requestsIndex;
  final int pollsIndex;
  final int chatIndex;

  int get totalCount => showRequests ? 4 : 3;

  factory MeetingSidebarTabsLayout.from({
    required bool isPrivate,
    required bool isHostOrAdmin,
  }) {
    final showRequests = isPrivate && isHostOrAdmin;
    if (showRequests) {
      return const MeetingSidebarTabsLayout(
        showRequests: true,
        participantsIndex: 0,
        requestsIndex: 1,
        pollsIndex: 2,
        chatIndex: 3,
      );
    }
    return const MeetingSidebarTabsLayout(
      showRequests: false,
      participantsIndex: 0,
      requestsIndex: -1,
      pollsIndex: 1,
      chatIndex: 2,
    );
  }
}
