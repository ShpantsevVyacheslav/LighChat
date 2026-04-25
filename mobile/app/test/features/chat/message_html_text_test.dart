import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/message_html_text.dart';

List<TextSpan> _collectTextSpans(List<InlineSpan> spans) {
  final out = <TextSpan>[];
  void walk(List<InlineSpan> nodes) {
    for (final n in nodes) {
      if (n is TextSpan) {
        out.add(n);
        final children = n.children;
        if (children != null && children.isNotEmpty) {
          walk(children);
        }
      }
    }
  }

  walk(spans);
  return out;
}

void main() {
  group('messageHtmlToPlainText', () {
    test('preserves consecutive spaces and decodes apostrophe entities', () {
      final plain = messageHtmlToPlainText('<p>A  B &#x27;C&#39;</p>');
      expect(plain, "A  B 'C'");
    });
  });

  group('messageHtmlToStyledSpans', () {
    test(
      'treats span with data-user-id as mention with tap recognizer',
      () async {
        String? tappedUserId;
        final spans = messageHtmlToStyledSpans(
          '<p>Hi <span data-user-id="u-1">@alice</span></p>',
          base: const TextStyle(fontSize: 14, color: Colors.white),
          onMentionTap: (userId) async {
            tappedUserId = userId;
          },
        );

        final textSpans = _collectTextSpans(spans);
        final mention = textSpans.firstWhere((s) => (s.text ?? '') == '@alice');
        expect(mention.style?.color, const Color(0xFF38BDF8));
        expect(mention.style?.fontWeight, FontWeight.w700);
        expect(mention.recognizer, isA<TapGestureRecognizer>());

        final recognizer = mention.recognizer! as TapGestureRecognizer;
        recognizer.onTap?.call();
        await Future<void>.delayed(Duration.zero);
        expect(tappedUserId, 'u-1');
      },
    );

    test('auto-linkify keeps trailing comma outside clickable URL', () {
      final spans = messageHtmlToStyledSpans(
        'См https://example.com, ок',
        base: const TextStyle(fontSize: 14, color: Colors.white),
      );

      final textSpans = _collectTextSpans(spans);
      final link = textSpans.firstWhere(
        (s) => (s.text ?? '') == 'https://example.com',
      );
      expect(link.recognizer, isA<TapGestureRecognizer>());

      final comma = textSpans.firstWhere((s) => (s.text ?? '') == ',');
      expect(comma.recognizer, isNull);
    });

    test('auto-linkify in html text nodes keeps trailing punctuation', () {
      final spans = messageHtmlToStyledSpans(
        '<p>Go https://example.com!</p>',
        base: const TextStyle(fontSize: 14, color: Colors.white),
      );

      final textSpans = _collectTextSpans(spans);
      final link = textSpans.firstWhere(
        (s) => (s.text ?? '') == 'https://example.com',
      );
      expect(link.recognizer, isA<TapGestureRecognizer>());

      final bang = textSpans.firstWhere((s) => (s.text ?? '') == '!');
      expect(bang.recognizer, isNull);
    });
  });
}
