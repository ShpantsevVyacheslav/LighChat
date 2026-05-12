import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_list_screen.dart';
import 'package:lighchat_mobile/features/chat/ui/workspace_shell_screen.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

const _l10nDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Контракт-тесты для Stage 2 рефакторинга:
///   - [ChatListPane] рендерится без Scaffold-обёртки.
///   - [WorkspaceShellScreen] выбирает one-pane vs two-pane по ширине окна.
///
/// Не проверяет live данные — Firebase не инициализирован, поэтому
/// `firebaseReadyProvider` overrid'ится в `false`, и Pane рендерит
/// fallback Text без Firestore-запросов.
void main() {
  testWidgets('ChatListPane строится без Scaffold-обёртки',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: _l10nDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: SizedBox(
              width: 360,
              height: 800,
              child: ChatListPane(),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ChatListPane), findsOneWidget);
  });

  testWidgets('WorkspaceShellScreen в узком окне без conversationId — '
      'master only, без divider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: _l10nDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkspaceShellScreen(),
        ),
      ),
    );

    expect(find.byType(WorkspaceShellScreen), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    expect(find.byType(ChatListPane), findsOneWidget);
  });

  testWidgets(
      'WorkspaceShellScreen в широком окне без conversationId — '
      'master + divider + empty placeholder', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: _l10nDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkspaceShellScreen(),
        ),
      ),
    );

    // 1280dp — show rail (≥1024dp) + master + detail (3-pane), без
    // folders rail (≥1200dp нужен — есть, но провайдер lazy loads).
    // Хотя бы один VerticalDivider должен присутствовать между панелями.
    expect(find.byType(VerticalDivider), findsWidgets);
    expect(find.byType(ChatListPane), findsOneWidget);
    // Empty placeholder содержит подпись «Выберите чат».
    expect(find.text('Выберите чат'), findsOneWidget);
  });
}
