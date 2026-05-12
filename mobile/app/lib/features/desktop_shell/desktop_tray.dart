import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Системный трей: иконка + меню (Open / Quit). Бейдж непрочитанных
/// рендерится через нативный API на каждой ОС.
class DesktopTray with TrayListener {
  DesktopTray._();
  static final DesktopTray instance = DesktopTray._();

  bool _initialized = false;
  int _unreadCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Иконка: для macOS — template image, для Windows/Linux — обычный PNG.
    // Используем lighchat_mark.png из ассетов (он уже зарегистрирован).
    final iconPath = _trayIconAsset;
    try {
      await trayManager.setIcon(iconPath, isTemplate: Platform.isMacOS);
    } catch (e) {
      if (kDebugMode) debugPrint('[tray] setIcon failed: $e');
    }

    await trayManager.setContextMenu(_buildMenu());
    trayManager.addListener(this);
  }

  Future<void> setBadgeCount(int count) async {
    if (_unreadCount == count) return;
    _unreadCount = count;
    final label = count > 0 ? (count > 99 ? '99+' : count.toString()) : '';
    try {
      await trayManager.setTitle(label);
    } catch (_) {/* tray может быть не готов */}
    // Дополнительно — обновить меню (показывать "У вас N новых...").
    await trayManager.setContextMenu(_buildMenu());
  }

  Menu _buildMenu() {
    return Menu(
      items: <MenuItem>[
        MenuItem(
          key: 'show',
          label: _unreadCount > 0
              ? 'Открыть LighChat ($_unreadCount)'
              : 'Открыть LighChat',
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Выйти'),
      ],
    );
  }

  @override
  void onTrayIconMouseDown() {
    _restore();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _restore();
        break;
      case 'quit':
        windowManager.destroy();
        break;
    }
  }

  Future<void> _restore() async {
    if (!await windowManager.isVisible()) {
      await windowManager.show();
    }
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.focus();
  }

  /// Иконка для трея. Используем существующий ассет lighchat_mark.png.
  String get _trayIconAsset {
    // tray_manager на Windows ждёт .ico, на остальных — .png.
    if (Platform.isWindows) {
      return 'assets/lighchat_mark.png';
    }
    return 'assets/lighchat_mark.png';
  }
}
