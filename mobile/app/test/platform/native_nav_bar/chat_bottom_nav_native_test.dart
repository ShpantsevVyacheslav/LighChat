import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_bottom_nav.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_route_observer.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

/// Регрессия от 2026-05-13: native UITabBar не появлялся на /contacts,
/// /calls, /meetings — только на /chats. Контракт:
///
/// 1) Первый mount ChatBottomNav на любом таб-экране → setBottomBar шлётся
///    (force-push из initState).
/// 2) При навигации (Navigator.push) RouteObserver вызывает hideAll
///    → setTopBar/setBottomBar с `visible: false`.
/// 3) При возврате (Navigator.pop) bar снова появляется (didPopNext →
///    force-push).
/// 4) На iOS/macOS ChatBottomNav.build() возвращает SizedBox.shrink() —
///    Material-pill bar НЕ рисуется в дереве (визуально отсутствует).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lighchat/native_nav');
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  bool nativeSupported() => Platform.isIOS || Platform.isMacOS;

  Widget appWithHome(Widget home) {
    return MaterialApp(
      navigatorObservers: [nativeNavRouteObserver],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  testWidgets(
    'native path: build() возвращает SizedBox.shrink, push улетает в native',
    (tester) async {
      if (!nativeSupported()) return;

      await tester.pumpWidget(
        appWithHome(
          Scaffold(
            body: ChatBottomNav(
              activeTab: ChatBottomNavTab.chats,
              onChatsTap: () {},
              onContactsTap: () {},
              onProfileTap: () {},
              onCallsTap: () {},
              onMeetingsTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Material pill bar в дерево не попадает — высота 0.
      final renderObject =
          tester.renderObject<RenderBox>(find.byType(ChatBottomNav));
      expect(renderObject.size.height, 0,
          reason: 'ChatBottomNav.build() должен вернуть SizedBox.shrink на iOS/macOS');

      // setBottomBar(visible:true) пришёл в native.
      final visible = calls.where(
        (c) =>
            c.method == 'setBottomBar' &&
            (c.arguments as Map)['visible'] == true,
      );
      expect(
        visible.length,
        greaterThanOrEqualTo(1),
        reason:
            'initState должен force-pushнуть setBottomBar(visible:true)',
      );
      // Проверяем что selectedId совпадает с активным табом.
      expect(
        (visible.first.arguments as Map)['selectedId'],
        'chats',
      );
    },
  );

  testWidgets(
    'observer hideAll шлётся на каждом push/pop',
    (tester) async {
      if (!nativeSupported()) return;

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [nativeNavRouteObserver],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatBottomNav(
              activeTab: ChatBottomNavTab.chats,
              onChatsTap: () {},
              onContactsTap: () {},
              onProfileTap: () {},
              onCallsTap: () {},
              onMeetingsTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      calls.clear();

      // push нового экрана сверху.
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      // Observer.didPush должен вызвать hideAll (setTopBar+setBottomBar hidden).
      final hideCalls = calls.where(
        (c) =>
            (c.method == 'setTopBar' || c.method == 'setBottomBar') &&
            (c.arguments as Map)['visible'] == false,
      );
      expect(
        hideCalls.length,
        greaterThanOrEqualTo(2),
        reason: 'observer должен скрыть оба бара на push',
      );

      calls.clear();

      // pop назад.
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // Observer.didPop + didPopNext → hideAll затем push visible.
      final visibleAgain = calls.where(
        (c) =>
            c.method == 'setBottomBar' &&
            (c.arguments as Map)['visible'] == true,
      );
      expect(
        visibleAgain.length,
        greaterThanOrEqualTo(1),
        reason:
            'didPopNext должен force-pushнуть bottom bar с visible:true',
      );
    },
  );
}
