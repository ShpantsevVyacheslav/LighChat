import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/nav_bar_config.dart';

/// Контракт сериализации моделей NavBar*.
///
/// Эти тесты фиксируют формат wire-данных, отправляемых в native через
/// MethodChannel `lighchat/native_nav`. Любое изменение ключей или формы
/// должно сопровождаться синхронной правкой Swift-стороны
/// (`NavBarOverlayHost.applyTopBar(_:)` и `applyBottomBar(_:)`).
void main() {
  group('NavBarIcon.toMap', () {
    test('пишет ровно один ключ symbol', () {
      const icon = NavBarIcon('phone.fill');
      expect(icon.toMap(), {'symbol': 'phone.fill'});
    });
  });

  group('NavBarAction.toMap', () {
    test('минимальный action: id + icon + enabled', () {
      const action = NavBarAction(
        id: 'search',
        icon: NavBarIcon('magnifyingglass'),
      );
      expect(action.toMap(), {
        'id': 'search',
        'icon': {'symbol': 'magnifyingglass'},
        'enabled': true,
      });
    });

    test('опциональные поля пропадают, если null', () {
      const action = NavBarAction(
        id: 'x',
        icon: NavBarIcon('xmark'),
      );
      final map = action.toMap();
      expect(map.containsKey('title'), false);
      expect(map.containsKey('badge'), false);
      expect(map.containsKey('tintHex'), false);
    });

    test('полный action содержит все поля', () {
      const action = NavBarAction(
        id: 'threads',
        icon: NavBarIcon('bubble.left'),
        title: 'Threads',
        badge: '3',
        tintHex: '#FFAA00',
        enabled: false,
      );
      expect(action.toMap(), {
        'id': 'threads',
        'icon': {'symbol': 'bubble.left'},
        'title': 'Threads',
        'badge': '3',
        'tintHex': '#FFAA00',
        'enabled': false,
      });
    });
  });

  group('NavBarLeading.toMap', () {
    test('back — стандартный тип', () {
      const leading = NavBarLeading.back();
      expect(leading.toMap(), {'type': 'back', 'id': 'back'});
    });

    test('close с кастомным id', () {
      const leading = NavBarLeading.close(id: 'cancel');
      expect(leading.toMap(), {'type': 'close', 'id': 'cancel'});
    });

    test('menu с custom icon', () {
      const leading = NavBarLeading.menu(icon: NavBarIcon('line.3.horizontal'));
      expect(leading.toMap(), {
        'type': 'menu',
        'id': 'menu',
        'icon': {'symbol': 'line.3.horizontal'},
      });
    });

    test('none — пустой id, без icon', () {
      const leading = NavBarLeading.none();
      expect(leading.toMap(), {'type': 'none', 'id': ''});
    });
  });

  group('NavBarTitle.toMap', () {
    test('только title', () {
      const title = NavBarTitle(title: 'Settings');
      expect(title.toMap(), {'title': 'Settings'});
    });

    test('avatar + subtitle + status', () {
      const title = NavBarTitle(
        title: 'Alice',
        subtitle: 'online',
        avatarUrl: 'https://x/avatar.jpg',
        avatarFallbackInitial: 'A',
        statusDotColorHex: '#00FF00',
      );
      expect(title.toMap(), {
        'title': 'Alice',
        'subtitle': 'online',
        'avatarUrl': 'https://x/avatar.jpg',
        'avatarFallbackInitial': 'A',
        'statusDotColorHex': '#00FF00',
      });
    });
  });

  group('NavBarTopConfig.toMap', () {
    test('hidden — visible: false, пустые поля', () {
      const config = NavBarTopConfig.hidden();
      final map = config.toMap();
      expect(map['visible'], false);
      expect((map['title'] as Map)['title'], '');
      expect((map['leading'] as Map)['type'], 'none');
      expect(map['trailing'], isEmpty);
    });

    test('visible с trailing actions сохраняет порядок', () {
      const config = NavBarTopConfig(
        title: NavBarTitle(title: 'Chat'),
        trailing: [
          NavBarAction(id: 'a', icon: NavBarIcon('phone.fill')),
          NavBarAction(id: 'b', icon: NavBarIcon('video.fill')),
        ],
      );
      final trailing = config.toMap()['trailing'] as List;
      expect(trailing, hasLength(2));
      expect((trailing[0] as Map)['id'], 'a');
      expect((trailing[1] as Map)['id'], 'b');
    });

    test('style.largeTitle сериализуется как строка имени', () {
      const config = NavBarTopConfig(
        title: NavBarTitle(title: 'X'),
        style: NavBarTopStyle.largeTitle,
      );
      expect(config.toMap()['style'], 'largeTitle');
    });
  });

  group('NavBarBottomConfig.toMap', () {
    test('hidden — visible: false, пустые items', () {
      const config = NavBarBottomConfig.hidden();
      final map = config.toMap();
      expect(map['visible'], false);
      expect(map['items'], isEmpty);
      expect(map['selectedId'], '');
    });

    test('items сериализуются в порядке передачи', () {
      const config = NavBarBottomConfig(
        items: [
          NavBarTab(id: 'chats', label: 'Chats', icon: NavBarIcon('bubble.left')),
          NavBarTab(id: 'calls', label: 'Calls', icon: NavBarIcon('phone.fill')),
        ],
        selectedId: 'calls',
      );
      final items = config.toMap()['items'] as List;
      expect(items, hasLength(2));
      expect((items[0] as Map)['id'], 'chats');
      expect((items[1] as Map)['id'], 'calls');
      expect(config.toMap()['selectedId'], 'calls');
    });

    test('badge на табе попадает в wire', () {
      const config = NavBarBottomConfig(
        items: [
          NavBarTab(
            id: 'chats',
            label: 'Chats',
            icon: NavBarIcon('bubble.left'),
            badge: '12',
          ),
        ],
        selectedId: 'chats',
      );
      final items = config.toMap()['items'] as List;
      expect((items[0] as Map)['badge'], '12');
    });

    test('tintHex на табе попадает в wire', () {
      const config = NavBarBottomConfig(
        items: [
          NavBarTab(
            id: 'chats',
            label: 'Chats',
            icon: NavBarIcon('bubble.left'),
            tintHex: '#FF8800',
          ),
        ],
        selectedId: 'chats',
      );
      final items = config.toMap()['items'] as List;
      expect((items[0] as Map)['tintHex'], '#FF8800');
    });

    test('tintHex отсутствует когда null', () {
      const config = NavBarBottomConfig(
        items: [
          NavBarTab(
            id: 'chats',
            label: 'Chats',
            icon: NavBarIcon('bubble.left'),
          ),
        ],
        selectedId: 'chats',
      );
      final item = (config.toMap()['items'] as List).first as Map;
      expect(item.containsKey('tintHex'), false);
    });
  });

  group('NavBarSearchConfig.toMap', () {
    test('inactive — все три поля сериализованы', () {
      const config = NavBarSearchConfig.inactive();
      expect(config.toMap(), {
        'active': false,
        'placeholder': '',
        'value': '',
      });
    });

    test('active с value/placeholder', () {
      const config = NavBarSearchConfig(
        active: true,
        placeholder: 'Search messages',
        value: 'hello',
      );
      expect(config.toMap(), {
        'active': true,
        'placeholder': 'Search messages',
        'value': 'hello',
      });
    });
  });

  group('NavBarSelectionConfig.toMap', () {
    test('inactive — count 0, пустые actions', () {
      const config = NavBarSelectionConfig.inactive();
      expect(config.toMap(), {
        'active': false,
        'count': 0,
        'actions': isEmpty,
      });
    });

    test('active с count и actions', () {
      const config = NavBarSelectionConfig(
        active: true,
        count: 3,
        actions: [
          NavBarAction(id: 'forward', icon: NavBarIcon('arrowshape.turn.up.right')),
          NavBarAction(id: 'delete', icon: NavBarIcon('trash')),
        ],
      );
      final map = config.toMap();
      expect(map['active'], true);
      expect(map['count'], 3);
      expect(map['actions'], hasLength(2));
    });
  });

  group('NavBarEvent.fromMap', () {
    test('actionTap c id', () {
      final event = NavBarEvent.fromMap({
        'type': 'actionTap',
        'payload': {'id': 'search'},
      });
      expect(event, isA<NavBarActionTap>());
      expect((event! as NavBarActionTap).id, 'search');
    });

    test('leadingTap c id', () {
      final event = NavBarEvent.fromMap({
        'type': 'leadingTap',
        'payload': {'id': 'back'},
      });
      expect(event, isA<NavBarLeadingTap>());
      expect((event! as NavBarLeadingTap).id, 'back');
    });

    test('tabChange c id', () {
      final event = NavBarEvent.fromMap({
        'type': 'tabChange',
        'payload': {'id': 'meetings'},
      });
      expect(event, isA<NavBarTabChange>());
      expect((event! as NavBarTabChange).id, 'meetings');
    });

    test('searchChange c value', () {
      final event = NavBarEvent.fromMap({
        'type': 'searchChange',
        'payload': {'value': 'hi'},
      });
      expect(event, isA<NavBarSearchChange>());
      expect((event! as NavBarSearchChange).value, 'hi');
    });

    test('searchSubmit c value', () {
      final event = NavBarEvent.fromMap({
        'type': 'searchSubmit',
        'payload': {'value': 'done'},
      });
      expect(event, isA<NavBarSearchSubmit>());
      expect((event! as NavBarSearchSubmit).value, 'done');
    });

    test('searchCancel — пустой payload', () {
      final event = NavBarEvent.fromMap({
        'type': 'searchCancel',
        'payload': const <String, Object?>{},
      });
      expect(event, isA<NavBarSearchCancel>());
    });

    test('неизвестный type → null', () {
      final event = NavBarEvent.fromMap({
        'type': 'unknown',
        'payload': const <String, Object?>{},
      });
      expect(event, isNull);
    });

    test('id не строка → null (защита от мусора)', () {
      final event = NavBarEvent.fromMap({
        'type': 'actionTap',
        'payload': {'id': 42},
      });
      expect(event, isNull);
    });

    test('null / не-map вход → null', () {
      expect(NavBarEvent.fromMap(null), isNull);
      expect(NavBarEvent.fromMap('string'), isNull);
      expect(NavBarEvent.fromMap(42), isNull);
    });
  });
}
