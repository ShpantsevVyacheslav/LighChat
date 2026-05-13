/// Lucide → SF Symbol mapping for the native UITabBar overlay on iOS / macOS.
///
/// Пользовательские настройки нижней навигации в LighChat хранят имена
/// иконок в стиле Lucide (см. `bottom_nav_icon_settings.dart`). Native UIKit
/// рисует только SF Symbols. Этот файл маппит выбор пользователя в
/// ближайший по смыслу SF Symbol — если соответствие не найдено, возвращаем
/// `fallback` (по умолчанию символ-кружок).
///
/// Источник Lucide-имен: `mobile/app/lib/features/chat/data/bottom_nav_icon_settings.dart`.
String lucideToSfSymbol(String lucideName, {String fallback = 'circle'}) {
  return _lucideToSf[lucideName] ?? fallback;
}

const Map<String, String> _lucideToSf = {
  // Сообщения / чаты
  'message-circle': 'message.fill',
  'message-square': 'bubble.left.fill',
  'messages-square': 'bubble.left.and.bubble.right.fill',
  'mail': 'envelope.fill',
  'inbox': 'tray.fill',

  // Телефония / звонки
  'phone': 'phone.fill',
  'phone-call': 'phone.fill',
  'smartphone': 'iphone',

  // Люди / контакты
  'contact': 'person.crop.rectangle.fill',
  'user': 'person.fill',
  'users': 'person.2.fill',
  'user-plus': 'person.fill.badge.plus',
  'user-circle': 'person.crop.circle.fill',

  // Видео / медиа
  'video': 'video.fill',
  'camera': 'camera.fill',
  'mic': 'mic.fill',
  'film': 'film.fill',

  // Календарь / время
  'calendar': 'calendar',
  'clock': 'clock.fill',
  'alarm-clock': 'alarm.fill',

  // Уведомления
  'bell': 'bell.fill',
  'bell-off': 'bell.slash.fill',

  // Навигация / общее
  'home': 'house.fill',
  'settings': 'gearshape.fill',
  'shield': 'shield.fill',
  'shield-check': 'checkmark.shield.fill',
  'lock': 'lock.fill',
  'unlock': 'lock.open.fill',
  'key': 'key.fill',

  // Действия / контент
  'star': 'star.fill',
  'heart': 'heart.fill',
  'bookmark': 'bookmark.fill',
  'folder': 'folder.fill',
  'image': 'photo.fill',
  'images': 'photo.stack.fill',
  'music': 'music.note',
  'play': 'play.fill',
  'pause': 'pause.fill',

  // Места / гео
  'map-pin': 'mappin.circle.fill',
  'map': 'map.fill',
  'globe': 'globe',
  'compass': 'safari.fill',

  // Сетка / layout
  'layout-grid': 'square.grid.2x2.fill',
  'grid': 'square.grid.3x3.fill',
  'list': 'list.bullet',

  // Бизнес / работа
  'briefcase': 'briefcase.fill',
  'building': 'building.2.fill',
  'graduation-cap': 'graduationcap.fill',
  'school': 'graduationcap.fill',

  // Текст / поиск
  'search': 'magnifyingglass',
  'hash': 'number',
  'at-sign': 'at',
  'paperclip': 'paperclip',
  'send': 'paperplane.fill',
  'smile': 'face.smiling.fill',
  'emoji': 'face.smiling.fill',

  // Тех / разное
  'wifi': 'wifi',
  'coffee': 'cup.and.saucer.fill',
  'gift': 'gift.fill',
  'trophy': 'trophy.fill',
  'flag': 'flag.fill',
  'rocket': 'paperplane.fill',
  'link': 'link',
  'sparkles': 'sparkles',
  'zap': 'bolt.fill',
  'crown': 'crown.fill',

  // Часто встречающиеся defaults
  'plus': 'plus',
  'check': 'checkmark',
  'x': 'xmark',
  'close': 'xmark',
  'arrow-left': 'chevron.backward',
  'arrow-right': 'chevron.forward',
  'menu': 'line.3.horizontal',
  'more': 'ellipsis',
  'dots-horizontal': 'ellipsis',
  'dots-vertical': 'ellipsis',
};
