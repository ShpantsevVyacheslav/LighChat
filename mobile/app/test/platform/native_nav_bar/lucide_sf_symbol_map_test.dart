import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/lucide_sf_symbol_map.dart';

/// Контракт перевода Lucide-имён иконок (которые пользователь выбирает в
/// настройках) в SF Symbol для native UITabBar / UINavigationBar на iOS.
/// Регрессия от 2026-05-13: native tabs показывали захардкоженный набор
/// SF Symbol-ов и не учитывали пользовательский выбор.
void main() {
  group('lucideToSfSymbol', () {
    test('базовые иконки для нижней навигации замаплены (outline-style)', () {
      // Settings-picker рисует иконки в outline-стиле — SF Symbols в баре
      // должны визуально совпадать, поэтому без `.fill`.
      expect(lucideToSfSymbol('messages-square'),
          'bubble.left.and.bubble.right');
      expect(lucideToSfSymbol('contact'), 'person.crop.rectangle');
      expect(lucideToSfSymbol('phone-call'), 'phone');
      expect(lucideToSfSymbol('video'), 'video');
    });

    test('alias-формы', () {
      expect(lucideToSfSymbol('message-circle'), 'message');
      expect(lucideToSfSymbol('message-square'), 'bubble.left');
      expect(lucideToSfSymbol('users'), 'person.2');
      expect(lucideToSfSymbol('user'), 'person');
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
      expect(lucideToSfSymbol('bell'), 'bell');
      expect(lucideToSfSymbol('settings'), 'gearshape');
    });
  });

  group('lucideToSfSymbolFilled (selected state)', () {
    test('добавляет .fill к outline-SF Symbol', () {
      expect(lucideToSfSymbolFilled('messages-square'),
          'bubble.left.and.bubble.right.fill');
      expect(lucideToSfSymbolFilled('phone-call'), 'phone.fill');
      expect(lucideToSfSymbolFilled('video'), 'video.fill');
      expect(lucideToSfSymbolFilled('contact'),
          'person.crop.rectangle.fill');
    });

    test('SF Symbols без .fill варианта возвращают outline', () {
      expect(lucideToSfSymbolFilled('search'), 'magnifyingglass');
      expect(lucideToSfSymbolFilled('calendar'), 'calendar');
      expect(lucideToSfSymbolFilled('smartphone'), 'iphone');
    });
  });
}
