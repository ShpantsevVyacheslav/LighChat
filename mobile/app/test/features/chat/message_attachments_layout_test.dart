import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/message_attachments.dart';
import 'package:lighchat_models/lighchat_models.dart';

void main() {
  group('computeMessageAttachmentsColumnWidth', () {
    test('returns 0 for empty attachments', () {
      final width = computeMessageAttachmentsColumnWidth(
        attachments: const <ChatAttachment>[],
        available: 320,
      );
      expect(width, 0);
    });

    test('expands single landscape image using horizontal scale', () {
      final width = computeMessageAttachmentsColumnWidth(
        attachments: const <ChatAttachment>[
          ChatAttachment(
            url: 'https://example.com/landscape.jpg',
            name: 'landscape.jpg',
            type: 'image/jpeg',
            width: 1920,
            height: 1080,
          ),
        ],
        available: 500,
      );
      expect(width, closeTo(270.4, 0.001));
    });
  });
}
