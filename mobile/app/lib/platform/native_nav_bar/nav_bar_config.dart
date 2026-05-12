import 'package:flutter/foundation.dart';

/// Identifies a native back-button / menu-button on the leading side of the bar.
enum NavBarLeadingType {
  none,
  back,
  close,
  menu,
}

/// SF Symbol name (iOS) / SF-mapped name (macOS).
///
/// We keep a fixed catalogue so the Dart side stays in sync with the native
/// SF-Symbol→UIImage lookup table. Adding a new icon means adding the SF Symbol
/// on both sides — Dart picks the string, native maps it.
class NavBarIcon {
  const NavBarIcon(this.symbol);

  /// Raw SF Symbol identifier, e.g. `phone.fill`, `magnifyingglass`.
  final String symbol;

  Map<String, Object?> toMap() => {'symbol': symbol};
}

@immutable
class NavBarAction {
  const NavBarAction({
    required this.id,
    required this.icon,
    this.title,
    this.badge,
    this.tintHex,
    this.enabled = true,
  });

  /// Stable identifier returned via `actionTap` event.
  final String id;
  final NavBarIcon icon;

  /// Optional plain title (used when icon-only is not desired).
  final String? title;

  /// Numeric badge string. Native side renders bubble over icon.
  final String? badge;

  /// `#RRGGBB` or `#AARRGGBB`. When `null` — native uses tintColor of the bar.
  final String? tintHex;

  final bool enabled;

  Map<String, Object?> toMap() => {
        'id': id,
        'icon': icon.toMap(),
        if (title != null) 'title': title,
        if (badge != null) 'badge': badge,
        if (tintHex != null) 'tintHex': tintHex,
        'enabled': enabled,
      };
}

@immutable
class NavBarLeading {
  const NavBarLeading.back({this.id = 'back'})
      : type = NavBarLeadingType.back,
        icon = null;
  const NavBarLeading.close({this.id = 'close'})
      : type = NavBarLeadingType.close,
        icon = null;
  const NavBarLeading.menu({this.id = 'menu', this.icon})
      : type = NavBarLeadingType.menu;
  const NavBarLeading.none()
      : type = NavBarLeadingType.none,
        id = '',
        icon = null;

  final NavBarLeadingType type;
  final String id;
  final NavBarIcon? icon;

  Map<String, Object?> toMap() => {
        'type': type.name,
        'id': id,
        if (icon != null) 'icon': icon!.toMap(),
      };
}

@immutable
class NavBarTitle {
  const NavBarTitle({
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.avatarFallbackInitial,
    this.statusDotColorHex,
  });

  final String title;
  final String? subtitle;

  /// Remote avatar URL. Native side caches & decodes. Pass `null` for plain
  /// text title.
  final String? avatarUrl;

  /// Single character used when avatar fails to load / URL is null.
  final String? avatarFallbackInitial;

  /// Small status dot color over the avatar (online/offline indicator).
  final String? statusDotColorHex;

  Map<String, Object?> toMap() => {
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (avatarFallbackInitial != null)
          'avatarFallbackInitial': avatarFallbackInitial,
        if (statusDotColorHex != null) 'statusDotColorHex': statusDotColorHex,
      };
}

enum NavBarTopStyle {
  /// Standard inline title. Liquid Glass when available.
  inline,

  /// Large title that collapses on scroll (iOS large-title style).
  largeTitle,

  /// Transparent — no background, used over hero images / video.
  transparent,
}

@immutable
class NavBarTopConfig {
  const NavBarTopConfig({
    required this.title,
    this.leading = const NavBarLeading.back(),
    this.trailing = const [],
    this.style = NavBarTopStyle.inline,
    this.visible = true,
  });

  /// Hidden bar — Flutter screen handles its own header.
  const NavBarTopConfig.hidden()
      : title = const NavBarTitle(title: ''),
        leading = const NavBarLeading.none(),
        trailing = const [],
        style = NavBarTopStyle.inline,
        visible = false;

  final NavBarTitle title;
  final NavBarLeading leading;
  final List<NavBarAction> trailing;
  final NavBarTopStyle style;
  final bool visible;

  Map<String, Object?> toMap() => {
        'visible': visible,
        'title': title.toMap(),
        'leading': leading.toMap(),
        'trailing': trailing.map((a) => a.toMap()).toList(),
        'style': style.name,
      };
}

@immutable
class NavBarTab {
  const NavBarTab({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  final String id;
  final String label;
  final NavBarIcon icon;
  final NavBarIcon? selectedIcon;
  final String? badge;

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'icon': icon.toMap(),
        if (selectedIcon != null) 'selectedIcon': selectedIcon!.toMap(),
        if (badge != null) 'badge': badge,
      };
}

@immutable
class NavBarBottomConfig {
  const NavBarBottomConfig({
    required this.items,
    required this.selectedId,
    this.visible = true,
  });

  const NavBarBottomConfig.hidden()
      : items = const [],
        selectedId = '',
        visible = false;

  final List<NavBarTab> items;
  final String selectedId;
  final bool visible;

  Map<String, Object?> toMap() => {
        'visible': visible,
        'items': items.map((t) => t.toMap()).toList(),
        'selectedId': selectedId,
      };
}

@immutable
class NavBarSearchConfig {
  const NavBarSearchConfig({
    required this.active,
    this.placeholder = '',
    this.value = '',
  });

  const NavBarSearchConfig.inactive()
      : active = false,
        placeholder = '',
        value = '';

  final bool active;
  final String placeholder;
  final String value;

  Map<String, Object?> toMap() => {
        'active': active,
        'placeholder': placeholder,
        'value': value,
      };
}

@immutable
class NavBarSelectionConfig {
  const NavBarSelectionConfig({
    required this.active,
    this.count = 0,
    this.actions = const [],
  });

  const NavBarSelectionConfig.inactive()
      : active = false,
        count = 0,
        actions = const [];

  final bool active;
  final int count;
  final List<NavBarAction> actions;

  Map<String, Object?> toMap() => {
        'active': active,
        'count': count,
        'actions': actions.map((a) => a.toMap()).toList(),
      };
}

/// Event payloads coming from native bar back to Flutter.
sealed class NavBarEvent {
  const NavBarEvent();

  static NavBarEvent? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    final payload = raw['payload'];
    final pmap = payload is Map ? Map<String, Object?>.from(payload) : const {};
    switch (type) {
      case 'actionTap':
        final id = pmap['id'];
        if (id is String) return NavBarActionTap(id);
        return null;
      case 'leadingTap':
        final id = pmap['id'];
        if (id is String) return NavBarLeadingTap(id);
        return null;
      case 'tabChange':
        final id = pmap['id'];
        if (id is String) return NavBarTabChange(id);
        return null;
      case 'searchChange':
        final value = pmap['value'];
        if (value is String) return NavBarSearchChange(value);
        return null;
      case 'searchSubmit':
        final value = pmap['value'];
        if (value is String) return NavBarSearchSubmit(value);
        return null;
      case 'searchCancel':
        return const NavBarSearchCancel();
    }
    return null;
  }
}

class NavBarActionTap extends NavBarEvent {
  const NavBarActionTap(this.id);
  final String id;
}

class NavBarLeadingTap extends NavBarEvent {
  const NavBarLeadingTap(this.id);
  final String id;
}

class NavBarTabChange extends NavBarEvent {
  const NavBarTabChange(this.id);
  final String id;
}

class NavBarSearchChange extends NavBarEvent {
  const NavBarSearchChange(this.value);
  final String value;
}

class NavBarSearchSubmit extends NavBarEvent {
  const NavBarSearchSubmit(this.value);
  final String value;
}

class NavBarSearchCancel extends NavBarEvent {
  const NavBarSearchCancel();
}
