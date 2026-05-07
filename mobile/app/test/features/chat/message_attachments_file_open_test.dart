import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/message_attachments.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

void main() {
  testWidgets('MessageAttachments opens non-media file on tap', (tester) async {
    final attachment = ChatAttachment(
      url: 'https://example.com/docs/readme.txt',
      name: 'readme.txt',
      type: 'text/plain',
      size: 1280,
    );
    ChatAttachment? tapped;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MessageAttachments(
            attachments: [attachment],
            onOpenFileAttachment: (a) => tapped = a,
          ),
        ),
      ),
    );

    await tester.tap(find.text('readme.txt'));
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.url, attachment.url);
    expect(tapped!.name, attachment.name);
  });
}
