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

// Lucide-иконки в settings-picker'е отрисованы в outline-стиле. Чтобы
// native UITabBar визуально совпадал с выбором, используем outline-вариант
// SF Symbol (без `.fill`) везде, где возможно.
const Map<String, String> _lucideToSf = {
  // Сообщения / чаты
  'message-circle': 'message',
  'message-square': 'bubble.left',
  'messages-square': 'bubble.left.and.bubble.right',
  'mail': 'envelope',
  'inbox': 'tray',

  // Телефония / звонки
  'phone': 'phone',
  'phone-call': 'phone',
  'smartphone': 'iphone',

  // Люди / контакты
  'contact': 'person.crop.rectangle',
  'user': 'person',
  'users': 'person.2',
  'user-plus': 'person.badge.plus',
  'user-circle': 'person.crop.circle',

  // Видео / медиа
  'video': 'video',
  'camera': 'camera',
  'mic': 'mic',
  'film': 'film',

  // Календарь / время
  'calendar': 'calendar',
  'clock': 'clock',
  'alarm-clock': 'alarm',

  // Уведомления
  'bell': 'bell',
  'bell-off': 'bell.slash',

  // Навигация / общее
  'home': 'house',
  'settings': 'gearshape',
  'shield': 'shield',
  'shield-check': 'checkmark.shield',
  'lock': 'lock',
  'unlock': 'lock.open',
  'key': 'key',

  // Действия / контент
  'star': 'star',
  'heart': 'heart',
  'bookmark': 'bookmark',
  'folder': 'folder',
  'image': 'photo',
  'images': 'photo.stack',
  'music': 'music.note',
  'play': 'play',
  'pause': 'pause',

  // Места / гео
  'map-pin': 'mappin.circle',
  'map': 'map',
  'globe': 'globe',
  'compass': 'safari',

  // Сетка / layout
  'layout-grid': 'square.grid.2x2',
  'grid': 'square.grid.3x3',
  'list': 'list.bullet',

  // Бизнес / работа
  'briefcase': 'briefcase',
  'building': 'building.2',
  'graduation-cap': 'graduationcap',
  'school': 'graduationcap',

  // Текст / поиск
  'search': 'magnifyingglass',
  'hash': 'number',
  'at-sign': 'at',
  'paperclip': 'paperclip',
  'send': 'paperplane',
  'smile': 'face.smiling',
  'emoji': 'face.smiling',

  // Тех / разное
  'wifi': 'wifi',
  'coffee': 'cup.and.saucer',
  'gift': 'gift',
  'trophy': 'trophy',
  'flag': 'flag',
  'rocket': 'paperplane',
  'link': 'link',
  'sparkles': 'sparkles',
  'zap': 'bolt',
  'crown': 'crown',

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
