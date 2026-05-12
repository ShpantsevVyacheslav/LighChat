import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// [audit L-004] Project-wide singleton logger для mobile Flutter.
///
/// Зачем:
///  - Раньше прямые `debugPrint(...)` (~118 в `mobile/app/lib`) шумели в
///    release-логах через `flutter logs` / Xcode console и были видимы в
///    bug-reports пользователей с device-logging.
///  - С wrapper'ом централизуем: в release `Level.warning` (debug/info/trace
///    no-op), в debug `Level.debug` (всё видно).
///  - При желании добавим remote sink (Sentry/Crashlytics) — один файл
///    меняем, не 100.
///
/// Использование:
///   import 'package:lighchat_mobile/core/app_logger.dart';
///
///   appLogger.d('chat send start', ...);            // глушится в release
///   appLogger.i('user signed in', ...);             // info — release silent
///   appLogger.w('typing doc denied', error: e);     // warning — release visible
///   appLogger.e('send message failed',              // error — release visible
///       error: e, stackTrace: st);
///
/// Маппинг от прежнего `debugPrint`:
///  - простой `debugPrint('text')`      → `appLogger.d('text')`
///  - `debugPrint('failed: $e')`        → `appLogger.e('failed', error: e)`
///  - `debugPrint('warn: $e')`          → `appLogger.w('warn', error: e)`
///
/// Намеренно НЕ мигрировать:
///  - `*_diagnostics.dart` (link_preview / video_attachment) — там
///    собственный `kLog…Diagnostics` gate.
///  - QR-pairing flow (`e2ee_qr_pairing_screen.dart`, `pairing_qr.dart`,
///    `device_link_handover.dart`) — diagnostics для open-bug release-debug
///    пользовательской сборки. Будут мигрированы после закрытия багa.
final Logger appLogger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: false, // iOS console / Xcode не любит ANSI escape codes
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);
