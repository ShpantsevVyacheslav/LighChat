import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/composer_html_editing.dart';

void main() {
  group('ComposerHtmlEditing.toggleInline', () {
    test('unwraps tag when full rendered segment is selected', () {
      const text = '<strong>abc</strong>';
      final next = ComposerHtmlEditing.toggleInline(
        text,
        const TextSelection(baseOffset: 0, extentOffset: text.length),
        '<strong>',
        '</strong>',
      );
      expect(next.text, 'abc');
    });

    test('unwraps tag even when selection includes surrounding spaces', () {
      const text = ' <strong>abc</strong> ';
      final next = ComposerHtmlEditing.toggleInline(
        text,
        const TextSelection(baseOffset: 0, extentOffset: text.length),
        '<strong>',
        '</strong>',
      );
      expect(next.text, ' abc ');
    });

    test('normalizes ranges that start inside tag chars', () {
      const text = '<em>ab</em>';
      final next = ComposerHtmlEditing.toggleInline(
        text,
        const TextSelection(baseOffset: 1, extentOffset: 6),
        '<strong>',
        '</strong>',
      );
      expect(next.text, '<em><strong>ab</strong></em>');
    });
  });

  group('ComposerHtmlEditing.applyLink', () {
    test('preserves nested formatting inside selected html fragment', () {
      const text = '<strong>abc</strong>';
      final next = ComposerHtmlEditing.applyLink(
        text,
        const TextSelection(baseOffset: 0, extentOffset: text.length),
        'https://example.com',
      );
      expect(
        next.text,
        '<strong><a href="https://example.com">abc</a></strong>',
      );
    });

    test('replaces existing anchor instead of nesting links', () {
      const text = '<a href="https://old">abc</a>';
      final next = ComposerHtmlEditing.applyLink(
        text,
        const TextSelection(baseOffset: 0, extentOffset: text.length),
        'https://new',
      );
      expect(next.text, '<a href="https://new">abc</a>');
    });

    test('normalizes start/end when selection touches hidden tag chars', () {
      const text = '<strong>abc</strong>';
      final next = ComposerHtmlEditing.applyLink(
        text,
        const TextSelection(baseOffset: 1, extentOffset: 19),
        'https://example.com',
      );
      expect(
        next.text,
        '<strong><a href="https://example.com">abc</a></strong>',
      );
    });
  });
}
