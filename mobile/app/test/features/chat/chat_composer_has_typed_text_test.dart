import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/chat/data/composer_html_editing.dart';
import 'package:lighchat_mobile/features/chat/ui/message_html_text.dart';

/// Контракт-тесты для логики, по которой `ChatComposerState._hasTypedText`
/// решает показывать ли inline send/Aa-кнопку. Контроллер хранит сырой
/// HTML, поэтому пустая строка ≠ отсутствие текста (HTML-обёртки
/// `<p></p>` тоже считаются пустыми).
void main() {
  bool hasTypedText(String controllerText) {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      controllerText,
    );
    if (prepared.isEmpty) return false;
    return messageHtmlToPlainText(prepared).trim().isNotEmpty;
  }

  group('_hasTypedText (источник правды для inline Aa + send-button)', () {
    test('пустая строка → false', () {
      expect(hasTypedText(''), isFalse);
    });

    test('только пробелы → false', () {
      expect(hasTypedText('   \n\t  '), isFalse);
    });

    test('пустые HTML-обёртки → false', () {
      expect(hasTypedText('<p></p>'), isFalse);
      expect(hasTypedText('<p>   </p>'), isFalse);
    });

    test('обычный текст → true', () {
      expect(hasTypedText('hello'), isTrue);
    });

    test('текст в HTML-обёртке → true', () {
      expect(hasTypedText('<p>hello</p>'), isTrue);
    });

    test('форматированный текст в HTML → true', () {
      expect(hasTypedText('<p><strong>bold</strong></p>'), isTrue);
    });

    test('пробельный текст внутри HTML → false', () {
      expect(hasTypedText('<p>   </p>'), isFalse);
    });
  });
}
