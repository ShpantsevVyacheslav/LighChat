import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/features/chat/ui/message_location_request_bubble.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

ChatLocationRequest _req(String status) => ChatLocationRequest(
      requesterId: 'u1',
      status: status,
      requestedAt: '2026-05-16T10:00:00Z',
    );

Future<void> _pump(
  WidgetTester tester, {
  required ChatLocationRequest request,
  required bool isMine,
  VoidCallback? onRemove,
  VoidCallback? onAccept,
  VoidCallback? onDecline,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        child: MessageLocationRequestBubble(
          request: request,
          isMine: isMine,
          onAccept: onAccept ?? () {},
          onDecline: onDecline ?? () {},
          onRemove: onRemove,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'Bug #17: для своего pending request X-иконка отрисована (когда onRemove задан)',
      (tester) async {
    await _pump(
      tester,
      request: _req('pending'),
      isMine: true,
      onRemove: () {},
    );
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets(
      'Bug #17: для своего pending request без onRemove — X не рисуется',
      (tester) async {
    await _pump(tester, request: _req('pending'), isMine: true);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('Bug #17: для received-bubble (не isMine) X не показываем',
      (tester) async {
    await _pump(
      tester,
      request: _req('pending'),
      isMine: false,
      onRemove: () {},
    );
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('Bug #17: для accepted/declined X не показываем даже если isMine',
      (tester) async {
    for (final status in const ['accepted', 'declined']) {
      await _pump(
        tester,
        request: _req(status),
        isMine: true,
        onRemove: () {},
      );
      expect(
        find.byIcon(Icons.close_rounded),
        findsNothing,
        reason: 'status=$status',
      );
    }
  });

  testWidgets('Bug #17: тап X вызывает onRemove ровно один раз',
      (tester) async {
    var calls = 0;
    await _pump(
      tester,
      request: _req('pending'),
      isMine: true,
      onRemove: () => calls++,
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('isMine + pending показывает «Ожидаем локацию…»',
      (tester) async {
    await _pump(
      tester,
      request: _req('pending'),
      isMine: true,
      onRemove: () {},
    );
    expect(find.text('Ожидаем локацию…'), findsOneWidget);
  });

  testWidgets('!isMine + pending показывает Accept/Decline кнопки',
      (tester) async {
    await _pump(tester, request: _req('pending'), isMine: false);
    expect(find.text('Отклонить'), findsOneWidget);
    expect(find.text('Поделиться'), findsOneWidget);
  });
}
