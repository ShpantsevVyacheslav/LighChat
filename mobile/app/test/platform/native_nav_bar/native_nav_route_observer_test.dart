import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/nav_bar_config.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_bar_facade.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_route_observer.dart';

/// Регрессия для багов из reports от 2026-05-12:
///   * Bottom bar (UITabBar) не скрывался при заходе в чат.
///   * Top bar (UINavigationBar) с avatar/title прилипал при возврате к
///     списку чатов.
///
/// Контракт: виджет-владелец native-overlay'я подписан как [RouteAware]
/// на [nativeNavRouteObserver] и:
///   * при `didPushNext` (новый экран сверху) — пушит hidden конфиг,
///   * при `didPopNext` (вернулись на этот экран) — пушит свой конфиг,
///   * при `dispose` — пушит hidden конфиг.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool supportedHost() => Platform.isIOS || Platform.isMacOS;

  test('nativeNavRouteObserver — RouteObserver<ModalRoute<Object?>>', () {
    expect(nativeNavRouteObserver, isA<RouteObserver<ModalRoute<Object?>>>());
  });

  group('RouteAware-проброс в native_nav через подписчика', () {
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

    testWidgets(
      'didPushNext шлёт setBottomBar(visible:false); didPopNext снова '
      'пушит видимый бар',
      (tester) async {
        if (!supportedHost()) return;

        final subscriber = _FakeRouteAwareOwner();
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [nativeNavRouteObserver],
            home: _OwnerScreen(subscriber: subscriber),
          ),
        );
        await tester.pumpAndSettle();

        // initial subscribe + initial push from owner widget
        expect(
          calls.where((c) => c.method == 'setBottomBar').isNotEmpty,
          true,
          reason: 'owner widget пушит свой config в initState',
        );
        calls.clear();

        // Push новый экран поверх owner'а.
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          ),
        );
        await tester.pumpAndSettle();

        final hideCall = calls.firstWhere(
          (c) =>
              c.method == 'setBottomBar' &&
              (c.arguments as Map)['visible'] == false,
          orElse: () => const MethodCall(''),
        );
        expect(
          hideCall.method,
          'setBottomBar',
          reason: 'didPushNext должен попросить native скрыть bottom bar',
        );

        calls.clear();

        // Pop обратно.
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        final showCall = calls.firstWhere(
          (c) =>
              c.method == 'setBottomBar' &&
              (c.arguments as Map)['visible'] == true,
          orElse: () => const MethodCall(''),
        );
        expect(
          showCall.method,
          'setBottomBar',
          reason:
              'didPopNext должен заново поднять bottom bar с visible:true',
        );
      },
    );

    testWidgets(
      'dispose шлёт hidden конфиг, чтобы overlay не «прилип»',
      (tester) async {
        if (!supportedHost()) return;

        final subscriber = _FakeRouteAwareOwner();

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [nativeNavRouteObserver],
            home: _OwnerScreen(subscriber: subscriber),
          ),
        );
        await tester.pumpAndSettle();
        calls.clear();

        // Размонтируем (новое дерево без owner).
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pumpAndSettle();

        final hide = calls.firstWhere(
          (c) =>
              c.method == 'setBottomBar' &&
              (c.arguments as Map)['visible'] == false,
          orElse: () => const MethodCall(''),
        );
        expect(
          hide.method,
          'setBottomBar',
          reason: 'dispose должен скрыть bottom bar',
        );
      },
    );
  });
}

/// Минимальный owner-виджет, повторяющий лайфсайкл-контракт `ChatBottomNav`
/// (initState → push, didPushNext → hide, didPopNext → push, dispose → hide).
class _FakeRouteAwareOwner {}

class _OwnerScreen extends StatefulWidget {
  const _OwnerScreen({required this.subscriber});
  final _FakeRouteAwareOwner subscriber;

  @override
  State<_OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<_OwnerScreen> with RouteAware {
  bool get _native => NativeNavBarFacade.instance.isSupported;

  @override
  void initState() {
    super.initState();
    if (_native) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _push();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_native) {
      final route = ModalRoute.of(context);
      if (route is ModalRoute<Object?>) {
        nativeNavRouteObserver.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    if (_native) {
      nativeNavRouteObserver.unsubscribe(this);
      NativeNavBarFacade.instance.hideAll();
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_native) _push();
  }

  @override
  void didPushNext() {
    if (_native) NativeNavBarFacade.instance.hideAll();
  }

  void _push() {
    NativeNavBarFacade.instance.setBottomBar(
      const NavBarBottomConfig(
        items: [
          NavBarTab(
            id: 'chats',
            label: 'Chats',
            icon: NavBarIcon('bubble.left'),
          ),
        ],
        selectedId: 'chats',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox());
  }
}

