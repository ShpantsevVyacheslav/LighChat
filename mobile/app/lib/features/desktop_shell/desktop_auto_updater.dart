import 'dart:async';
import 'dart:io' show Platform;

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';

/// Авто-обновление для desktop-сборок.
///
/// - **macOS**: Sparkle (через embedded framework auto_updater).
///   Требует `SUFeedURL` в `Info.plist` (выставляется автоматически из
///   [feedUrl] при вызове `setFeedURL`).
/// - **Windows**: Squirrel.Windows. Требует подписанный installer и
///   `Releases` файл рядом с MSI/EXE на сервере.
/// - **Linux**: AppImageUpdate. Включён только если бинарь упакован как
///   AppImage с встроенной zsync информацией.
///
/// Сервер: ожидает что вы выложите `appcast.xml` для macOS и `RELEASES`
/// для Windows на стабильный URL (например GitHub Pages вашего репо).
class DesktopAutoUpdater {
  DesktopAutoUpdater._();
  static final DesktopAutoUpdater instance = DesktopAutoUpdater._();

  bool _initialized = false;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Подключает feed и запускает проверку обновлений раз в час.
  ///
  /// Можно безопасно вызвать несколько раз — повторные вызовы игнорируются.
  Future<void> initialize({String? feedUrl}) async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    final url = feedUrl ?? _defaultFeedUrl;
    try {
      await autoUpdater.setFeedURL(url);
      // Проверка раз в час; пользователь получит prompt при наличии обновления.
      await autoUpdater.setScheduledCheckInterval(3600);
      // Первая проверка через 30 секунд после старта, чтобы не блокировать UI.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 30), () {
          autoUpdater.checkForUpdates().catchError((Object e) {
            if (kDebugMode) debugPrint('[auto-updater] check failed: $e');
          });
        }),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[auto-updater] init failed: $e');
    }
  }

  /// Принудительная проверка по запросу пользователя (Settings → «Проверить
  /// обновления»). Возвращает быстро; диалог рендерит Sparkle/Squirrel сами.
  Future<void> checkNow() async {
    if (!isSupported) return;
    try {
      await autoUpdater.checkForUpdates();
    } catch (e) {
      if (kDebugMode) debugPrint('[auto-updater] manual check failed: $e');
    }
  }

  /// GitHub Releases на стандартном пути. Sparkle ожидает XML appcast,
  /// Squirrel — JSON `RELEASES`; здесь публичная заглушка-feed под наш
  /// домен. В production замените на свой CDN.
  String get _defaultFeedUrl {
    if (Platform.isMacOS) {
      return 'https://lighchat.online/updates/appcast.xml';
    }
    if (Platform.isWindows) {
      return 'https://lighchat.online/updates/windows';
    }
    return 'https://lighchat.online/updates/linux';
  }
}
