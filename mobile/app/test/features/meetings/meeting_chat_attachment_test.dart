import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_chat_attachment.dart';

void main() {
  group('MeetingChatAttachment.tryParse', () {
    test('minimal valid map', () {
      final a = MeetingChatAttachment.tryParse(<String, dynamic>{
        'url': 'https://example.com/x.png',
        'name': 'x.png',
        'type': 'image/png',
        'size': 100,
      })!;
      expect(a.url, 'https://example.com/x.png');
      expect(a.toFirestoreMap()['url'], 'https://example.com/x.png');
    });

    test('null on bad url or size', () {
      expect(
        MeetingChatAttachment.tryParse(<String, dynamic>{
          'url': '',
          'name': 'a',
          'type': 'image/png',
          'size': 1,
        }),
        isNull,
      );
      expect(
        MeetingChatAttachment.tryParse(<String, dynamic>{
          'url': 'https://a',
          'name': 'a',
          'type': 'image/png',
        }),
        isNull,
      );
    });
  });
}
