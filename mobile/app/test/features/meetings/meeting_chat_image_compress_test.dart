import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lighchat_mobile/features/meetings/data/meeting_chat_image_compress.dart';

void main() {
  group('prepareMeetingChatImageForUpload', () {
    test('downscales wide PNG and outputs JPEG', () {
      final wide = img.Image(width: 3000, height: 500);
      img.fill(wide, color: img.ColorRgb8(40, 120, 200));
      final png = Uint8List.fromList(img.encodePng(wide));

      final out = prepareMeetingChatImageForUpload(
        bytes: png,
        displayName: 'wide.png',
        mimeType: 'image/png',
      );

      expect(out.mimeType, 'image/jpeg');
      expect(out.displayName.toLowerCase().endsWith('.jpg'), isTrue);

      final decoded = img.decodeImage(out.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(kMeetingChatImageMaxSide));
      expect(decoded.height, lessThanOrEqualTo(kMeetingChatImageMaxSide));
    });

    test('keeps tiny PNG when JPEG would be larger', () {
      final im = img.Image(width: 64, height: 64);
      img.fill(im, color: img.ColorRgb8(10, 200, 30));
      final png = Uint8List.fromList(img.encodePng(im));

      final out = prepareMeetingChatImageForUpload(
        bytes: png,
        displayName: 'tiny.png',
        mimeType: 'image/png',
      );

      expect(out.bytes, png);
      expect(out.mimeType, 'image/png');
      expect(out.displayName, 'tiny.png');
    });

    test('leaves small JPEG unchanged', () {
      final im = img.Image(width: 400, height: 300);
      img.fill(im, color: img.ColorRgb8(200, 100, 50));
      final jpeg = Uint8List.fromList(img.encodeJpg(im, quality: 90));

      final out = prepareMeetingChatImageForUpload(
        bytes: jpeg,
        displayName: 'small.jpg',
        mimeType: 'image/jpeg',
      );

      expect(out.bytes, jpeg);
      expect(out.mimeType, 'image/jpeg');
      expect(out.displayName, 'small.jpg');
    });

    test('detects animated GIF and skips re-encode', () {
      // Minimal GIF header + NETSCAPE marker (not a valid full GIF, enough for heuristic).
      final fake = Uint8List.fromList(<int>[
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
        ...List<int>.filled(20, 0),
        0x4E,
        0x45,
        0x54,
        0x53,
        0x43,
        0x41,
        0x50,
        0x45,
        ...List<int>.filled(30, 0),
      ]);

      final out = prepareMeetingChatImageForUpload(
        bytes: fake,
        displayName: 'a.gif',
        mimeType: 'image/gif',
      );

      expect(out.bytes, fake);
      expect(out.mimeType, 'image/gif');
    });
  });
}
