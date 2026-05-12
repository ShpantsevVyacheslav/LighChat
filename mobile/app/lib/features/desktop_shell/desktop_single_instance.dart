import 'dart:async';
import 'dart:io' show InternetAddress, Platform, ServerSocket, Socket;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

/// Single-instance guard для desktop.
///
/// Реализация: bind на `127.0.0.1:<fixedPort>`. Первый процесс успешно
/// связывается и слушает; каждый последующий получает ECONNREFUSED→ соединяется,
/// шлёт `focus`-команду и завершается. Первый процесс при получении команды
/// поднимает окно поверх остальных.
///
/// Порт выбран в private-диапазоне (49000–49999) — конфликт с легитимными
/// сервисами маловероятен. Если порт занят посторонним процессом —
/// инстанс просто стартует как обычно (graceful degradation).
class DesktopSingleInstance {
  DesktopSingleInstance._();
  static final DesktopSingleInstance instance = DesktopSingleInstance._();

  static const int _port = 49753;
  ServerSocket? _server;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Возвращает `true`, если этот инстанс — основной (продолжаем запуск).
  /// `false` — другой инстанс уже работает, мы передали ему фокус и
  /// вызывающий код должен завершить процесс (`exit(0)`).
  Future<bool> acquire() async {
    if (!isSupported) return true;

    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _server!.listen(_handleClient);
      return true;
    } on Exception catch (e) {
      // Порт занят — попробуем достучаться до владельца.
      appLogger.w('[single-instance] bind failed', error: e);
      try {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          _port,
          timeout: const Duration(seconds: 2),
        );
        socket.write('focus\n');
        await socket.flush();
        await socket.close();
        return false;
      } catch (e2) {
        // Не отвечает — видимо, порт держит чужое приложение.
        // Стартуем как обычно — лучше двойной инстанс, чем пустой экран.
        if (kDebugMode) {
          appLogger.w('[single-instance] peer connect failed', error: e2);
        }
        return true;
      }
    }
  }

  Future<void> release() async {
    await _server?.close();
    _server = null;
  }

  Future<void> _handleClient(Socket client) async {
    try {
      await for (final chunk in client) {
        final cmd = String.fromCharCodes(chunk).trim();
        if (cmd == 'focus') {
          await _focusWindow();
        }
      }
    } catch (_) {/* ignore */}
    await client.close();
  }

  Future<void> _focusWindow() async {
    try {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      if (!await windowManager.isVisible()) {
        await windowManager.show();
      }
      await windowManager.focus();
    } catch (e) {
      appLogger.w('[single-instance] focus failed', error: e);
    }
  }
}
