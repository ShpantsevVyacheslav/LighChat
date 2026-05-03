import 'package:flutter/foundation.dart';

/// Включает подробное логирование для `MessageVideoAttachment`.
/// По умолчанию — только в debug-сборке. Выставьте `true` вручную, если
/// нужно отловить проблемы со скроллом у пользователя в release.
bool kLogVideoAttachmentDiagnostics = kDebugMode;

/// Детектор «прыжка AspectRatio» в инлайн-видео сообщениях.
///
/// Записывает по URL последний наблюдаемый aspect ratio и сигналит, если
/// он изменился между билдами. Это **тот самый сценарий** скачка ленты
/// при подряд идущих видео — фикс из коммита 4a95053+1 запрещает
/// замешивать `arFromController` в `safeAr`, поэтому AspectRatio должен
/// быть стабилен.
///
/// Если в логах появится строка `⚠️ AR JUMP` — значит, фикс где-то обошли,
/// и надо смотреть, откуда снова пришла нестабильность.
class VideoAttachmentAspectMonitor {
  VideoAttachmentAspectMonitor._();

  /// URL → последний известный aspect ratio. Сравниваем строго.
  static final Map<String, double> _lastAr = <String, double>{};

  /// URL → счётчик скачков AR (>0 = регрессия).
  static final Map<String, int> _arJumpCounts = <String, int>{};

  static void observe({
    required String url,
    required double ar,
    required bool hasMetadata,
    required bool controllerInitialized,
  }) {
    if (url.isEmpty || !ar.isFinite || ar <= 0) return;
    final prev = _lastAr[url];
    _lastAr[url] = ar;

    // На первом наблюдении prev == null — это нормально.
    if (prev == null) {
      if (kLogVideoAttachmentDiagnostics) {
        debugPrint(
          '[video-att] AR start url=${_short(url)} ar=${ar.toStringAsFixed(3)} '
          'meta=$hasMetadata initialized=$controllerInitialized',
        );
      }
      return;
    }
    // Допускаем мелкие float-погрешности (1e-4).
    if ((ar - prev).abs() < 1e-4) return;

    _arJumpCounts[url] = (_arJumpCounts[url] ?? 0) + 1;
    // Печатаем ВСЕГДА (вне флага) — это сигнал «фикс пробит».
    debugPrint(
      '⚠️  [video-att] AR JUMP url=${_short(url)} '
      '${prev.toStringAsFixed(3)} → ${ar.toStringAsFixed(3)} '
      'jump#${_arJumpCounts[url]} (meta=$hasMetadata initialized=$controllerInitialized). '
      'Лента под пальцем подскочит — нужно держать AspectRatio стабильным.',
    );
  }

  static void reset() {
    _lastAr.clear();
    _arJumpCounts.clear();
  }

  static Map<String, ({double ar, int jumps})> snapshot() {
    final all = <String>{..._lastAr.keys, ..._arJumpCounts.keys};
    return {
      for (final url in all)
        url: (
          ar: _lastAr[url] ?? 0,
          jumps: _arJumpCounts[url] ?? 0,
        ),
    };
  }

  static void printSummary() {
    final snap = snapshot();
    if (snap.isEmpty) {
      debugPrint('[video-att] summary: no inline videos observed');
      return;
    }
    var totalJumps = 0;
    snap.forEach((_, s) => totalJumps += s.jumps);
    debugPrint(
      '[video-att] summary: ${snap.length} unique videos, '
      '$totalJumps AR-jump events ${totalJumps == 0 ? '✅ OK' : '❌ REGRESSION'}',
    );
    if (totalJumps > 0) {
      snap.forEach((url, s) {
        if (s.jumps > 0) {
          debugPrint(
            '  ❌ ${_short(url)}: ar=${s.ar.toStringAsFixed(3)} jumps#${s.jumps}',
          );
        }
      });
    }
  }

  static String _short(String url) {
    if (url.length <= 60) return url;
    return '${url.substring(0, 57)}...';
  }
}
