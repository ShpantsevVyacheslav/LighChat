import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/lucide_sf_symbol_map.dart';

/// Контракт перевода Lucide-имён иконок (которые пользователь выбирает в
/// настройках) в SF Symbol для native UITabBar / UINavigationBar на iOS.
/// Регрессия от 2026-05-13: native tabs показывали захардкоженный набор
/// SF Symbol-ов и не учитывали пользовательский выбор.
void main() {
  group('lucideToSfSymbol', () {
    test('базовые иконки для нижней навигации замаплены', () {
      expect(lucideToSfSymbol('messages-square'),
          'bubble.left.and.bubble.right.fill');
      expect(lucideToSfSymbol('contact'), 'person.crop.rectangle.fill');
      expect(lucideToSfSymbol('phone-call'), 'phone.fill');
      expect(lucideToSfSymbol('video'), 'video.fill');
    });

    test('alias-формы', () {
      expect(lucideToSfSymbol('message-circle'), 'message.fill');
      expect(lucideToSfSymbol('message-square'), 'bubble.left.fill');
      expect(lucideToSfSymbol('users'), 'person.2.fill');
      expect(lucideToSfSymbol('user'), 'person.fill');
    });

    test('неизвестное имя → fallback', () {
      expect(lucideToSfSymbol('definitely-not-an-icon'), 'circle');
    });

    test('кастомный fallback применяется', () {
      expect(
        lucideToSfSymbol('not-real', fallback: 'questionmark'),
        'questionmark',
      );
    });

    test('actions-icons тоже доступны', () {
      expect(lucideToSfSymbol('search'), 'magnifyingglass');
      expect(lucideToSfSymbol('bell'), 'bell.fill');
      expect(lucideToSfSymbol('settings'), 'gearshape.fill');
    });
  });
}
