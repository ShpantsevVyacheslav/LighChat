import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/message_attachments.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

void main() {
  testWidgets('MessageAttachments renders telegram-like pdf preview row', (
    tester,
  ) async {
    const attachment = ChatAttachment(
      url: 'https://example.com/docs/gift-certificate.pdf',
      name: 'Подарочный сертификат.pdf',
      type: 'application/pdf',
      size: 874800,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MessageAttachments(attachments: [attachment]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Подарочный сертификат.pdf'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('PDF'),
      ),
      findsWidgets,
    );
  });

  testWidgets('MessageAttachments renders document preview row for docx', (
    tester,
  ) async {
    const attachment = ChatAttachment(
      url: 'https://example.com/docs/contract.docx',
      name: 'contract.docx',
      type:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      size: 42100,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MessageAttachments(attachments: [attachment]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('contract.docx'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('DOCX'),
      ),
      findsWidgets,
    );
  });
}
