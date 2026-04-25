import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/mention_token_codec.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_html_composer_controller.dart';

void main() {
  group('ChatHtmlComposerController mentions', () {
    test(
      'selection-only tap inside mention keeps token and snaps caret out',
      () {
        final token = MentionTokenCodec.buildToken(
          userId: 'u1',
          label: 'alice',
        );
        final initial = '$token ';
        final controller = ChatHtmlComposerController(text: initial);

        final insideOffset = (token.length ~/ 2).clamp(1, token.length - 1);
        controller.value = TextEditingValue(
          text: initial,
          selection: TextSelection.collapsed(offset: insideOffset),
        );

        expect(controller.text, initial);
        expect(controller.text.contains(MentionTokenCodec.tokenStart), isTrue);
        expect(controller.text.contains(MentionTokenCodec.tokenEnd), isTrue);
        expect(controller.selection.baseOffset, token.length);
        expect(controller.selection.extentOffset, token.length);
      },
    );

    test(
      'editing damaged mention token degrades to plain @label without markers',
      () {
        final token = MentionTokenCodec.buildToken(
          userId: 'u1',
          label: 'alice',
        );
        final controller = ChatHtmlComposerController(text: '$token ');

        final damaged = '${token.substring(0, token.length - 1)} ';
        controller.value = TextEditingValue(
          text: damaged,
          selection: TextSelection.collapsed(offset: damaged.length),
        );

        expect(controller.text.contains(MentionTokenCodec.tokenStart), isFalse);
        expect(controller.text.contains(MentionTokenCodec.tokenEnd), isFalse);
        expect(controller.text.startsWith('@'), isTrue);
      },
    );

    testWidgets(
      'buildTextSpan keeps plain-text length aligned with raw offsets',
      (tester) async {
        final token = MentionTokenCodec.buildToken(
          userId: 'u1',
          label: 'alice',
        );
        final raw = '$token and text';
        final controller = ChatHtmlComposerController(text: raw);

        late TextSpan span;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 14),
                  withComposing: false,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(span.toPlainText().length, raw.length);
      },
    );
  });
}
