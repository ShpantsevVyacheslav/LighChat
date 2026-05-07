import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_message_list.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

void main() {
  testWidgets('ChatMessageList forwards file-tap callback with message', (
    tester,
  ) async {
    final attachment = ChatAttachment(
      url: 'https://example.com/docs/spec.pdf',
      name: 'spec.pdf',
      type: 'application/pdf',
      size: 4096,
    );
    final message = ChatMessage(
      id: 'm1',
      senderId: 'u1',
      attachments: [attachment],
      createdAt: DateTime(2026, 5, 7, 12, 0),
      deliveryStatus: 'sent',
    );

    ChatAttachment? tappedAttachment;
    ChatMessage? tappedMessage;
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatMessageList(
              messagesDesc: [message],
              currentUserId: 'u2',
              conversationId: 'c1',
              scrollController: controller,
              onOpenFileAttachment: (a, m) {
                tappedAttachment = a;
                tappedMessage = m;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('spec.pdf'));
    await tester.pump();

    expect(tappedAttachment, isNotNull);
    expect(tappedAttachment!.url, attachment.url);
    expect(tappedMessage, isNotNull);
    expect(tappedMessage!.id, message.id);
  });
}
