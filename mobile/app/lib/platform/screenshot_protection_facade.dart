import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

import 'package:lighchat_mobile/core/app_logger.dart';

/// Запрет скриншотов / превью окна для секретных чатов.
///
/// - **Android**: `FLAG_SECURE` через `flutter_windowmanager_plus` —
///   блокирует скриншоты, превью в task switcher, capture в стриминг-софте.
/// - **macOS**: `NSWindow.sharingType = .none` через MethodChannel
///   `lighchat/screenshot_protection` — окно не появляется в скриншотах
///   и не захватывается ScreenCaptureKit.
/// - **Windows**: `SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)`
///   через тот же MethodChannel — окно становится чёрным в OBS/Teams/Zoom.
/// - **Linux / iOS**: API нет → показываем баннер «Скриншоты не блокируются».
class ScreenshotProtectionFacade {
  ScreenshotProtectionFacade._();
  static final ScreenshotProtectionFacade instance =
      ScreenshotProtectionFacade._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/screenshot_protection');

  bool _applied = false;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isMacOS || Platform.isWindows;
  }

  Future<void> enable() async {
    if (!isSupported || _applied) return;
    _applied = true;
    try {
      if (Platform.isAndroid) {
        await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      } else {
        await _channel.invokeMethod<void>('enable');
      }
    } catch (e) {
      appLogger.w('[screenshot-protection] enable failed', error: e);
      _applied = false;
    }
  }

  Future<void> disable() async {
    if (!_applied) return;
    _applied = false;
    try {
      if (Platform.isAndroid) {
        await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      } else if (Platform.isMacOS || Platform.isWindows) {
        await _channel.invokeMethod<void>('disable');
      }
    } catch (e) {
      appLogger.w('[screenshot-protection] disable failed', error: e);
    }
  }
}
