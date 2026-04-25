import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_invite_link.dart';

void main() {
  group('goRouterPathFromMeetingWebUri', () {
    test('parses meeting path on apex host', () {
      final u = Uri.parse('https://lighchat.online/meetings/abc123');
      expect(goRouterPathFromMeetingWebUri(u), '/meetings/abc123');
    });

    test('parses www host', () {
      final u = Uri.parse('https://www.lighchat.online/meetings/x-y_z');
      expect(goRouterPathFromMeetingWebUri(u), '/meetings/x-y_z');
    });

    test('rejects other hosts', () {
      expect(
        goRouterPathFromMeetingWebUri(Uri.parse('https://evil.example/meetings/abc')),
        isNull,
      );
    });

    test('rejects wrong path', () {
      expect(
        goRouterPathFromMeetingWebUri(Uri.parse('https://lighchat.online/dashboard')),
        isNull,
      );
    });
  });
}
