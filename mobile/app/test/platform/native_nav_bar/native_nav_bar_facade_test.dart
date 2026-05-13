import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/nav_bar_config.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_bar_facade.dart';

/// Контракт `NativeNavBarFacade` ↔ MethodChannel `lighchat/native_nav`.
///
/// Эти тесты проверяют, что фасад на iOS/macOS отправляет в native ровно
/// те методы и аргументы, которые описаны в `docs/arcitecture/native-nav-bar.md`.
/// На Android/Windows/Linux/Web фасад должен быть полным no-op.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lighchat/native_nav');

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    NativeNavBarFacade.instance.resetDedupeCacheForTests();
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

  bool supportedHost() => Platform.isIOS || Platform.isMacOS;

  group('NativeNavBarFacade.isSupported', () {
    test('детерминированно сооответствует platform check', () {
      expect(NativeNavBarFacade.instance.isSupported, supportedHost());
    });
  });

  group('setTopBar', () {
    test('отправляет метод setTopBar с сериализованным config', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setTopBar(
        const NavBarTopConfig(
          title: NavBarTitle(title: 'Hello'),
          trailing: [
            NavBarAction(id: 'search', icon: NavBarIcon('magnifyingglass')),
          ],
        ),
      );
      expect(calls, hasLength(1));
      final c = calls.single;
      expect(c.method, 'setTopBar');
      final args = (c.arguments as Map).cast<String, Object?>();
      expect(args['visible'], true);
      expect((args['title'] as Map)['title'], 'Hello');
      final trailing = args['trailing'] as List;
      expect(trailing, hasLength(1));
      expect((trailing[0] as Map)['id'], 'search');
    });

    test('hidden конфиг шлёт visible: false', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setTopBar(
        const NavBarTopConfig.hidden(),
      );
      expect(calls, hasLength(1));
      expect((calls.single.arguments as Map)['visible'], false);
    });
  });

  group('setBottomBar', () {
    test('сериализует items в порядке и проставляет selectedId', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setBottomBar(
        const NavBarBottomConfig(
          items: [
            NavBarTab(
              id: 'chats',
              label: 'Chats',
              icon: NavBarIcon('bubble.left'),
            ),
            NavBarTab(
              id: 'calls',
              label: 'Calls',
              icon: NavBarIcon('phone.fill'),
            ),
          ],
          selectedId: 'calls',
        ),
      );
      expect(calls.single.method, 'setBottomBar');
      final args = (calls.single.arguments as Map).cast<String, Object?>();
      expect(args['selectedId'], 'calls');
      final items = args['items'] as List;
      expect(items.map((i) => (i as Map)['id']), ['chats', 'calls']);
    });
  });

  group('setSearchMode', () {
    test('передаёт active=true с placeholder/value', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setSearchMode(
        const NavBarSearchConfig(
          active: true,
          placeholder: 'Find...',
          value: 'foo',
        ),
      );
      expect(calls.single.method, 'setSearchMode');
      final args = (calls.single.arguments as Map).cast<String, Object?>();
      expect(args['active'], true);
      expect(args['placeholder'], 'Find...');
      expect(args['value'], 'foo');
    });
  });

  group('setSelectionMode', () {
    test('передаёт count и actions', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setSelectionMode(
        const NavBarSelectionConfig(
          active: true,
          count: 2,
          actions: [
            NavBarAction(id: 'forward', icon: NavBarIcon('arrowshape.turn.up.right')),
          ],
        ),
      );
      expect(calls.single.method, 'setSelectionMode');
      final args = (calls.single.arguments as Map).cast<String, Object?>();
      expect(args['count'], 2);
      expect((args['actions'] as List), hasLength(1));
    });
  });

  group('setScrollOffset', () {
    test('передаёт contentOffset как double', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.setScrollOffset(42.5);
      expect(calls.single.method, 'setScrollOffset');
      expect(
        (calls.single.arguments as Map)['contentOffset'],
        42.5,
      );
    });
  });

  group('hideAll', () {
    test('отправляет setTopBar(hidden) + setBottomBar(hidden)', () async {
      if (!supportedHost()) return;
      await NativeNavBarFacade.instance.hideAll();
      expect(calls.map((c) => c.method), ['setTopBar', 'setBottomBar']);
      expect((calls[0].arguments as Map)['visible'], false);
      expect((calls[1].arguments as Map)['visible'], false);
    });

    test(
      'race regression: между двумя hideAll() не может протиснуться '
      'setBottomBar(visible) — все hide-вызовы должны быть собраны ДО',
      () async {
        if (!supportedHost()) return;
        // Симулируем последовательность context.go:
        // observer.didPop → hideAll
        // observer.didPush → hideAll
        // chat_contacts.initState postFrame → setBottomBar(visible)
        final hide1 = NativeNavBarFacade.instance.hideAll();
        final hide2 = NativeNavBarFacade.instance.hideAll();
        // Эмулируем postFrame push, который запускается в ту же
        // event-loop-итерацию (как только Flutter заканчивает обновлять
        // дерево). Без fix'а — push успевал просочиться между continuation'ами
        // hideAll'ов.
        unawaited(NativeNavBarFacade.instance.setBottomBar(
          const NavBarBottomConfig(
            items: [
              NavBarTab(
                id: 'contacts',
                label: 'Contacts',
                icon: NavBarIcon('person.crop.rectangle'),
              ),
            ],
            selectedId: 'contacts',
          ),
        ));
        await Future.wait([hide1, hide2]);
        // Ждём один полный цикл, чтобы postFrame push гарантированно
        // дошёл до канала.
        await Future<void>.delayed(Duration.zero);

        // Все вызовы setBottomBar в порядке отправки. ПОСЛЕДНИЙ должен быть
        // visible=true — иначе bar исчезнет на новом экране. С учётом dedupe
        // повторный hide не отправляется второй раз: ожидаем hide_bot
        // (1 раз) + visible_bot — итого минимум 2 вызова.
        final bottomCalls = calls.where((c) => c.method == 'setBottomBar').toList();
        expect(bottomCalls.length, greaterThanOrEqualTo(2));
        final lastVisible = (bottomCalls.last.arguments as Map)['visible'];
        expect(
          lastVisible,
          true,
          reason:
              'Последний setBottomBar должен быть visible=true (фикс race); '
              'все вызовы: ${bottomCalls.map((c) => (c.arguments as Map)['visible']).toList()}',
        );
      },
    );
  });

  group('no-op when native unsupported', () {
    test(
      'на Android/Windows/Linux setTopBar не делает MethodCall',
      () async {
        if (supportedHost()) return;
        await NativeNavBarFacade.instance.setTopBar(
          const NavBarTopConfig(title: NavBarTitle(title: 'x')),
        );
        expect(calls, isEmpty);
      },
      // Запускается только на не-iOS/macOS hosts; иначе test self-skips.
    );
  });

  group('dedupe', () {
    test(
      'идентичный setSearchMode подряд не шлётся повторно',
      () async {
        if (!supportedHost()) return;
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(
            active: true,
            placeholder: 'Search',
            value: '',
          ),
        );
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(
            active: true,
            placeholder: 'Search',
            value: '',
          ),
        );
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(
            active: true,
            placeholder: 'Search',
            value: '',
          ),
        );
        final searchCalls =
            calls.where((c) => c.method == 'setSearchMode').toList();
        expect(searchCalls.length, 1,
            reason:
                'Должен пройти ровно 1 setSearchMode (остальные 2 — дубли)');
      },
    );

    test(
      'отличающийся config проходит сквозь дедуп',
      () async {
        if (!supportedHost()) return;
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(active: true, value: 'a'),
        );
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(active: true, value: 'b'),
        );
        await NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig(active: true, value: 'c'),
        );
        final searchCalls =
            calls.where((c) => c.method == 'setSearchMode').toList();
        expect(searchCalls.length, 3,
            reason:
                'Разные value → каждый push должен дойти до native');
      },
    );
  });

  group('error swallowing', () {
    test('native ошибка не пробрасывается в Dart', () async {
      if (!supportedHost()) return;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'native error');
      });
      // Не должно бросать.
      await NativeNavBarFacade.instance.setTopBar(
        const NavBarTopConfig(title: NavBarTitle(title: 'x')),
      );
    });
  });
}
