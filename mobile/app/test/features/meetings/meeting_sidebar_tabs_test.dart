import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_sidebar_tabs.dart';

/// Контракт раскладки вкладок шторки митинга.
void main() {
  group('MeetingSidebarTabsLayout.from', () {
    test('public meeting + regular member: 3 tabs, no requests', () {
      final l = MeetingSidebarTabsLayout.from(
        isPrivate: false,
        isHostOrAdmin: false,
      );
      expect(l.showRequests, isFalse);
      expect(l.totalCount, 3);
      expect(l.participantsIndex, 0);
      expect(l.requestsIndex, -1);
      expect(l.pollsIndex, 1);
      expect(l.chatIndex, 2);
    });

    test('public meeting + host/admin: still no requests tab', () {
      // Бизнес-правило: в публичной встрече заявок не бывает —
      // даже host не должен видеть пустую вкладку.
      final l = MeetingSidebarTabsLayout.from(
        isPrivate: false,
        isHostOrAdmin: true,
      );
      expect(l.showRequests, isFalse);
      expect(l.totalCount, 3);
      expect(l.requestsIndex, -1);
      expect(l.chatIndex, 2);
    });

    test('private meeting + regular member: requests hidden (no admin rights)',
        () {
      final l = MeetingSidebarTabsLayout.from(
        isPrivate: true,
        isHostOrAdmin: false,
      );
      expect(l.showRequests, isFalse);
      expect(l.totalCount, 3);
    });

    test('private meeting + host/admin: requests right after members', () {
      final l = MeetingSidebarTabsLayout.from(
        isPrivate: true,
        isHostOrAdmin: true,
      );
      expect(l.showRequests, isTrue);
      expect(l.totalCount, 4);
      expect(l.participantsIndex, 0);
      // Requests должен идти сразу после Members.
      expect(l.requestsIndex, 1);
      expect(l.pollsIndex, 2);
      expect(l.chatIndex, 3);
    });

    test('chat is always the last tab', () {
      for (final isPrivate in [true, false]) {
        for (final isHostOrAdmin in [true, false]) {
          final l = MeetingSidebarTabsLayout.from(
            isPrivate: isPrivate,
            isHostOrAdmin: isHostOrAdmin,
          );
          expect(l.chatIndex, l.totalCount - 1,
              reason:
                  'isPrivate=$isPrivate isHostOrAdmin=$isHostOrAdmin');
        }
      }
    });
  });
}
