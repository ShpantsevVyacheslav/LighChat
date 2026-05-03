import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

const Map<String, String> defaultBottomNavIconNames = <String, String>{
  '/dashboard/chat': 'messages-square',
  '/dashboard/contacts': 'contact',
  '/dashboard/meetings': 'video',
  '/dashboard/calls': 'phone-call',
};

class BottomNavMenuItemDefinition {
  const BottomNavMenuItemDefinition({
    required this.href,
    required this.label,
    required this.defaultIconName,
    required this.fallbackIcon,
  });

  final String href;
  final String label;
  final String defaultIconName;
  final IconData fallbackIcon;
}

List<BottomNavMenuItemDefinition> get bottomNavMenuItems {
  final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
  return <BottomNavMenuItemDefinition>[
    BottomNavMenuItemDefinition(
      href: '/dashboard/chat',
      label: l10n.bottom_nav_label_chats,
      defaultIconName: 'messages-square',
      fallbackIcon: Icons.chat_bubble_outline_rounded,
    ),
    BottomNavMenuItemDefinition(
      href: '/dashboard/contacts',
      label: l10n.bottom_nav_label_contacts,
      defaultIconName: 'contact',
      fallbackIcon: Icons.group_outlined,
    ),
    BottomNavMenuItemDefinition(
      href: '/dashboard/meetings',
      label: l10n.bottom_nav_label_conferences,
      defaultIconName: 'video',
      fallbackIcon: Icons.videocam_outlined,
    ),
    BottomNavMenuItemDefinition(
      href: '/dashboard/calls',
      label: l10n.bottom_nav_label_calls,
      defaultIconName: 'phone-call',
      fallbackIcon: Icons.call_outlined,
    ),
  ];
}

String localizedBottomNavLabel(String href, AppLocalizations l10n) {
  switch (href) {
    case '/dashboard/chat':
      return l10n.bottom_nav_chats;
    case '/dashboard/contacts':
      return l10n.bottom_nav_contacts;
    case '/dashboard/meetings':
      return l10n.bottom_nav_meetings;
    case '/dashboard/calls':
      return l10n.bottom_nav_calls;
    default:
      return href;
  }
}

class BottomNavIconChoice {
  const BottomNavIconChoice({
    required this.name,
    required this.label,
    required this.icon,
    this.searchKeywords = const <String>[],
  });

  final String name;
  final String label;
  final IconData icon;
  final List<String> searchKeywords;
}

const List<BottomNavIconChoice> bottomNavIconLibrary = <BottomNavIconChoice>[
  BottomNavIconChoice(
    name: 'message-circle',
    label: 'Message Circle',
    icon: Icons.chat_outlined,
    searchKeywords: <String>['chat', 'message'],
  ),
  BottomNavIconChoice(
    name: 'message-square',
    label: 'Message Square',
    icon: Icons.chat_bubble_outline_rounded,
    searchKeywords: <String>['chat', 'message'],
  ),
  BottomNavIconChoice(
    name: 'messages-square',
    label: 'Messages Square',
    icon: Icons.forum_outlined,
    searchKeywords: <String>['chat', 'messages'],
  ),
  BottomNavIconChoice(
    name: 'mail',
    label: 'Mail',
    icon: Icons.mail_outline_rounded,
    searchKeywords: <String>['email', 'letter'],
  ),
  BottomNavIconChoice(
    name: 'inbox',
    label: 'Inbox',
    icon: Icons.inbox_outlined,
    searchKeywords: <String>['mail'],
  ),
  BottomNavIconChoice(
    name: 'phone',
    label: 'Phone',
    icon: Icons.phone_outlined,
    searchKeywords: <String>['call'],
  ),
  BottomNavIconChoice(
    name: 'phone-call',
    label: 'Phone Call',
    icon: Icons.call_outlined,
    searchKeywords: <String>['call'],
  ),
  BottomNavIconChoice(
    name: 'smartphone',
    label: 'Smartphone',
    icon: Icons.smartphone_rounded,
    searchKeywords: <String>['phone'],
  ),
  BottomNavIconChoice(
    name: 'contact',
    label: 'Contact',
    icon: Icons.person_outline_rounded,
    searchKeywords: <String>['user'],
  ),
  BottomNavIconChoice(
    name: 'user',
    label: 'User',
    icon: Icons.person_outline_rounded,
    searchKeywords: <String>['contact'],
  ),
  BottomNavIconChoice(
    name: 'users',
    label: 'Users',
    icon: Icons.group_outlined,
    searchKeywords: <String>['contacts', 'team'],
  ),
  BottomNavIconChoice(
    name: 'user-plus',
    label: 'User Plus',
    icon: Icons.person_add_alt_rounded,
    searchKeywords: <String>['add', 'contact'],
  ),
  BottomNavIconChoice(
    name: 'video',
    label: 'Video',
    icon: Icons.videocam_outlined,
    searchKeywords: <String>['meeting', 'call'],
  ),
  BottomNavIconChoice(
    name: 'camera',
    label: 'Camera',
    icon: Icons.photo_camera_outlined,
    searchKeywords: <String>['video', 'photo'],
  ),
  BottomNavIconChoice(
    name: 'mic',
    label: 'Mic',
    icon: Icons.mic_none_rounded,
    searchKeywords: <String>['audio', 'record'],
  ),
  BottomNavIconChoice(
    name: 'calendar',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    searchKeywords: <String>['date'],
  ),
  BottomNavIconChoice(
    name: 'bell',
    label: 'Bell',
    icon: Icons.notifications_none_rounded,
    searchKeywords: <String>['notification'],
  ),
  BottomNavIconChoice(
    name: 'home',
    label: 'Home',
    icon: Icons.home_outlined,
    searchKeywords: <String>['main'],
  ),
  BottomNavIconChoice(
    name: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    searchKeywords: <String>['gear'],
  ),
  BottomNavIconChoice(
    name: 'shield',
    label: 'Shield',
    icon: Icons.shield_outlined,
    searchKeywords: <String>['security'],
  ),
  BottomNavIconChoice(
    name: 'shield-check',
    label: 'Shield Check',
    icon: Icons.verified_user_outlined,
    searchKeywords: <String>['security', 'safe'],
  ),
  BottomNavIconChoice(
    name: 'star',
    label: 'Star',
    icon: Icons.star_border_rounded,
    searchKeywords: <String>['favorite'],
  ),
  BottomNavIconChoice(
    name: 'heart',
    label: 'Heart',
    icon: Icons.favorite_border_rounded,
    searchKeywords: <String>['like'],
  ),
  BottomNavIconChoice(
    name: 'bookmark',
    label: 'Bookmark',
    icon: Icons.bookmark_border_rounded,
    searchKeywords: <String>['save'],
  ),
  BottomNavIconChoice(
    name: 'folder',
    label: 'Folder',
    icon: Icons.folder_outlined,
    searchKeywords: <String>['files'],
  ),
  BottomNavIconChoice(
    name: 'image',
    label: 'Image',
    icon: Icons.image_outlined,
    searchKeywords: <String>['photo'],
  ),
  BottomNavIconChoice(
    name: 'music',
    label: 'Music',
    icon: Icons.music_note_outlined,
    searchKeywords: <String>['audio'],
  ),
  BottomNavIconChoice(
    name: 'map-pin',
    label: 'Map Pin',
    icon: Icons.location_on_outlined,
    searchKeywords: <String>['location', 'gps'],
  ),
  BottomNavIconChoice(
    name: 'layout-grid',
    label: 'Layout Grid',
    icon: Icons.grid_view_rounded,
    searchKeywords: <String>['apps'],
  ),
  BottomNavIconChoice(
    name: 'compass',
    label: 'Compass',
    icon: Icons.explore_outlined,
    searchKeywords: <String>['navigate'],
  ),
  BottomNavIconChoice(
    name: 'briefcase',
    label: 'Briefcase',
    icon: Icons.work_outline_rounded,
    searchKeywords: <String>['work'],
  ),
  BottomNavIconChoice(
    name: 'building',
    label: 'Building',
    icon: Icons.apartment_outlined,
    searchKeywords: <String>['office'],
  ),
  BottomNavIconChoice(
    name: 'graduation-cap',
    label: 'Graduation Cap',
    icon: Icons.school_outlined,
    searchKeywords: <String>['education'],
  ),
  BottomNavIconChoice(
    name: 'search',
    label: 'Search',
    icon: Icons.search_rounded,
    searchKeywords: <String>['find'],
  ),
  BottomNavIconChoice(
    name: 'hash',
    label: 'Hash',
    icon: Icons.tag_rounded,
    searchKeywords: <String>['tag'],
  ),
  BottomNavIconChoice(
    name: 'at-sign',
    label: 'At Sign',
    icon: Icons.alternate_email_rounded,
    searchKeywords: <String>['mention'],
  ),
  BottomNavIconChoice(
    name: 'paperclip',
    label: 'Paperclip',
    icon: Icons.attach_file_rounded,
    searchKeywords: <String>['attachment'],
  ),
  BottomNavIconChoice(
    name: 'send',
    label: 'Send',
    icon: Icons.send_outlined,
    searchKeywords: <String>['plane'],
  ),
  BottomNavIconChoice(
    name: 'smile',
    label: 'Smile',
    icon: Icons.emoji_emotions_outlined,
    searchKeywords: <String>['emoji'],
  ),
  BottomNavIconChoice(
    name: 'wifi',
    label: 'Wifi',
    icon: Icons.wifi_rounded,
    searchKeywords: <String>['network'],
  ),
  BottomNavIconChoice(
    name: 'coffee',
    label: 'Coffee',
    icon: Icons.coffee_outlined,
    searchKeywords: <String>['cup'],
  ),
  BottomNavIconChoice(
    name: 'gift',
    label: 'Gift',
    icon: Icons.card_giftcard_rounded,
    searchKeywords: <String>['present'],
  ),
  BottomNavIconChoice(
    name: 'trophy',
    label: 'Trophy',
    icon: Icons.emoji_events_outlined,
    searchKeywords: <String>['award'],
  ),
  BottomNavIconChoice(
    name: 'flag',
    label: 'Flag',
    icon: Icons.flag_outlined,
    searchKeywords: <String>['mark'],
  ),
  BottomNavIconChoice(
    name: 'rocket',
    label: 'Rocket',
    icon: Icons.rocket_launch_outlined,
    searchKeywords: <String>['start'],
  ),
  BottomNavIconChoice(
    name: 'globe',
    label: 'Globe',
    icon: Icons.public_rounded,
    searchKeywords: <String>['world'],
  ),
  BottomNavIconChoice(
    name: 'link',
    label: 'Link',
    icon: Icons.link_rounded,
    searchKeywords: <String>['url'],
  ),
  BottomNavIconChoice(
    name: 'sparkles',
    label: 'Sparkles',
    icon: Icons.auto_awesome_outlined,
    searchKeywords: <String>['magic'],
  ),
  BottomNavIconChoice(
    name: 'zap',
    label: 'Zap',
    icon: Icons.flash_on_outlined,
    searchKeywords: <String>['bolt'],
  ),
  BottomNavIconChoice(
    name: 'crown',
    label: 'Crown',
    icon: Icons.workspace_premium_outlined,
    searchKeywords: <String>['premium'],
  ),
];

final Map<String, IconData> _iconByName = <String, IconData>{
  for (final icon in bottomNavIconLibrary) icon.name: icon.icon,
};

Map<String, String> parseBottomNavIconNames(Object? raw) {
  if (raw is! Map) return <String, String>{};
  final out = <String, String>{};
  for (final entry in raw.entries) {
    final k = entry.key.toString();
    final v = entry.value;
    if (v is! String || v.trim().isEmpty) continue;
    out[k] = v.trim().toLowerCase();
  }
  return out;
}

String resolveBottomNavIconName(String href, Map<String, String>? overrides) {
  final raw = overrides?[href]?.trim().toLowerCase();
  if (raw != null && raw.isNotEmpty && _iconByName.containsKey(raw)) {
    return raw;
  }
  final fallback = defaultBottomNavIconNames[href];
  if (fallback != null && _iconByName.containsKey(fallback)) {
    return fallback;
  }
  return 'message-square';
}

IconData iconDataForBottomNavName(String name, [IconData? fallback]) {
  return _iconByName[name.trim().toLowerCase()] ??
      fallback ??
      Icons.circle_outlined;
}

class BottomNavIconVisualStyle {
  const BottomNavIconVisualStyle({
    this.iconColor,
    this.strokeWidth,
    this.tileBackground,
    this.size,
  });

  final String? iconColor;
  final double? strokeWidth;
  final String? tileBackground;
  final double? size;

  static const Object _sentinel = Object();

  bool get isEmpty {
    return (iconColor == null || iconColor!.trim().isEmpty) &&
        strokeWidth == null &&
        (tileBackground == null || tileBackground!.trim().isEmpty) &&
        size == null;
  }

  BottomNavIconVisualStyle copyWith({
    Object? iconColor = _sentinel,
    Object? strokeWidth = _sentinel,
    Object? tileBackground = _sentinel,
    Object? size = _sentinel,
  }) {
    String? parseString(Object? raw) {
      if (raw == null) return null;
      if (raw is String) {
        final v = raw.trim();
        return v.isEmpty ? null : v;
      }
      return null;
    }

    double? parseDouble(Object? raw) {
      if (raw == null) return null;
      if (raw is num && raw.isFinite) return raw.toDouble();
      return null;
    }

    return BottomNavIconVisualStyle(
      iconColor: identical(iconColor, _sentinel)
          ? this.iconColor
          : parseString(iconColor),
      strokeWidth: identical(strokeWidth, _sentinel)
          ? this.strokeWidth
          : parseDouble(strokeWidth),
      tileBackground: identical(tileBackground, _sentinel)
          ? this.tileBackground
          : parseString(tileBackground),
      size: identical(size, _sentinel) ? this.size : parseDouble(size),
    );
  }

  static BottomNavIconVisualStyle fromJson(Object? raw) {
    if (raw is! Map) return const BottomNavIconVisualStyle();
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    String? asString(Object? value) {
      if (value is! String) return null;
      final t = value.trim();
      return t.isEmpty ? null : t;
    }

    double? asDouble(Object? value) {
      if (value is! num || !value.isFinite) return null;
      return value.toDouble();
    }

    return BottomNavIconVisualStyle(
      iconColor: asString(map['iconColor']),
      strokeWidth: asDouble(map['strokeWidth']),
      tileBackground: asString(map['tileBackground']),
      size: asDouble(map['size']),
    );
  }

  Map<String, Object?> toJson() {
    final out = <String, Object?>{};
    if (iconColor != null && iconColor!.trim().isNotEmpty) {
      out['iconColor'] = iconColor!.trim();
    }
    if (strokeWidth != null) out['strokeWidth'] = strokeWidth;
    if (tileBackground != null && tileBackground!.trim().isNotEmpty) {
      out['tileBackground'] = tileBackground!.trim();
    }
    if (size != null) out['size'] = size;
    return out;
  }
}

Map<String, BottomNavIconVisualStyle> parseBottomNavIconStyles(Object? raw) {
  if (raw is! Map) return <String, BottomNavIconVisualStyle>{};
  final out = <String, BottomNavIconVisualStyle>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    final style = BottomNavIconVisualStyle.fromJson(entry.value);
    if (key.trim().isEmpty || style.isEmpty) continue;
    out[key] = style;
  }
  return out;
}

BottomNavIconVisualStyle mergeBottomNavIconVisualStyles(
  BottomNavIconVisualStyle global,
  BottomNavIconVisualStyle? perHref,
) {
  final local = perHref ?? const BottomNavIconVisualStyle();
  return BottomNavIconVisualStyle(
    iconColor: local.iconColor ?? global.iconColor,
    strokeWidth: local.strokeWidth ?? global.strokeWidth,
    tileBackground: local.tileBackground ?? global.tileBackground,
    size: local.size ?? global.size,
  );
}

LinearGradient defaultBottomNavTileGradient(String href) {
  switch (href) {
    case '/dashboard/chat':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE1382E), Color(0xFFB00F0A)],
      );
    case '/dashboard/contacts':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3D8DFF), Color(0xFF1E56D6)],
      );
    case '/dashboard/meetings':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
      );
    case '/dashboard/calls':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF16A34A), Color(0xFF059669)],
      );
    default:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F86FF), Color(0xFF7A5CF8)],
      );
  }
}

/// Явный отказ от заливки/градиента плитки под иконкой нижнего меню (см. настройки чатов).
bool bottomNavTileBackgroundIsNone(String? raw) {
  final t = raw?.trim().toLowerCase();
  return t == 'none' || t == 'transparent' || t == 'off';
}

Color? parseColorFromHex(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (!value.startsWith('#')) return null;
  final hex = value.substring(1);
  if (hex.length == 6) {
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(0xFF000000 | parsed);
  }
  if (hex.length == 8) {
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
  return null;
}

String colorToHex(Color color) {
  // Компоненты sRGB 0..1 → байты; не смешивать с устаревшими .red/.green/.blue.
  int comp(double v) => (v * 255.0).round().clamp(0, 255);
  final r = comp(color.r).toRadixString(16).padLeft(2, '0').toUpperCase();
  final g = comp(color.g).toRadixString(16).padLeft(2, '0').toUpperCase();
  final b = comp(color.b).toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#$r$g$b';
}
