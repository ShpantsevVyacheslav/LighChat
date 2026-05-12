import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Color, Size;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_tray.dart';

/// Точка инициализации десктоп-оболочки: окно, трей, восстановление размера.
///
/// Должна вызываться из `main()` _до_ `runApp`, потому что `window_manager`
/// требует ранней регистрации обработчиков.
class DesktopShell {
  DesktopShell._();
  static final DesktopShell instance = DesktopShell._();

  bool _initialized = false;
  bool _trayInitialized = false;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Инициализация окна: загрузить размер/позицию из prefs, выставить
  /// минимальный размер, показать.
  Future<void> initWindow() async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    await windowManager.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    // Default 1440×900 на первом запуске — это >= `_fourPaneBreakpoint`
    // в `WorkspaceShellScreen`, чтобы пользователь сразу видел rail +
    // folders rail + chat list + chat detail (а не compact single-pane).
    // Persisted значения от предыдущих запусков имеют приоритет.
    final width = prefs.getDouble(_kWidthKey) ?? 1440.0;
    final height = prefs.getDouble(_kHeightKey) ?? 900.0;

    final options = WindowOptions(
      size: Size(width, height),
      // Минимальный размер 720×540 — на маленьких ноутбуках/окнах
      // WorkspaceShellScreen честно скроется в single-pane fallback.
      minimumSize: const Size(720, 540),
      center: true,
      backgroundColor: const Color(0xFF0A0E17),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'LighChat',
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setTitle('LighChat');
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(_WindowSizeListener(prefs));
  }

  /// Поднимает системный трей (иконка + меню).
  Future<void> initTray() async {
    if (!isSupported || _trayInitialized) return;
    _trayInitialized = true;
    await DesktopTray.instance.initialize();
  }

  /// Обновить badge непрочитанных в Dock/Taskbar.
  Future<void> setBadgeCount(int count) async {
    if (!isSupported) return;
    await DesktopTray.instance.setBadgeCount(count);
  }

  /// Регистрирует текущего пользователя как имеющего desktop-устройство.
  /// Пишет `arrayUnion('desktop')` в `users/{uid}.devicePlatforms` —
  /// поле, по которому Cloud Function `mirrorPushToFirestore` решает,
  /// зеркалить ли FCM в Firestore (для Windows/Linux fallback).
  ///
  /// Идемпотентно. Вызывается из MyApp.initState после получения uid
  /// (через authUserProvider listener). Не блокирует UI — best-effort.
  Future<void> markDesktopDevice() async {
    if (!isSupported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        <String, dynamic>{
          'devicePlatforms': FieldValue.arrayUnion(<String>['desktop']),
          'lastDesktopActiveAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      appLogger.w('[desktop-shell] markDesktopDevice failed', error: e);
    }
  }

  static const _kWidthKey = 'desktop.window.width';
  static const _kHeightKey = 'desktop.window.height';
}

class _WindowSizeListener with WindowListener {
  _WindowSizeListener(this._prefs);

  final SharedPreferences _prefs;
  Timer? _debounce;

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final size = await windowManager.getSize();
      await _prefs.setDouble(DesktopShell._kWidthKey, size.width);
      await _prefs.setDouble(DesktopShell._kHeightKey, size.height);
    });
  }
}
