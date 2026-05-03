import 'package:flutter/foundation.dart';

/// Включает подробное логирование жизненного цикла link-preview.
/// По умолчанию — только в debug-сборке. Можно вручную выставить `true`
/// в profile/release-сборке, если нужно отловить баг у пользователя.
bool kLogLinkPreviewDiagnostics = kDebugMode;

/// Детектор регрессии «skeleton↔content мерцания»: если для одного и того же
/// URL карточка хоть раз достигла `ConnectionState.done`, а затем снова
/// показала skeleton (`waiting` или `none`) — это значит, что Future-кеш
/// потерял идентичность, FutureBuilder пересубскрайбился и всё снова
/// мерцает. Это **тот самый баг**, который мы починили в 5998afe.
///
/// Использование: `LinkPreviewFlickerDetector.recordWaiting(url)` /
/// `recordDone(url)` зовём из билдера `MessageLinkPreviewCard`.
class LinkPreviewFlickerDetector {
  LinkPreviewFlickerDetector._();

  /// URL → счётчик переходов в done.
  static final Map<String, int> _doneCounts = <String, int>{};

  /// URL → счётчик показов skeleton ПОСЛЕ первого done. >0 = регрессия.
  static final Map<String, int> _skeletonAfterDoneCounts = <String, int>{};

  static void recordDone(String url) {
    _doneCounts[url] = (_doneCounts[url] ?? 0) + 1;
    if (kLogLinkPreviewDiagnostics) {
      debugPrint(
        '[link-preview] DONE url=${_short(url)} done#${_doneCounts[url]}',
      );
    }
  }

  static void recordWaiting(String url) {
    final doneCount = _doneCounts[url] ?? 0;
    if (doneCount > 0) {
      // Это регрессия — значит, FutureBuilder снова сбрасывается.
      _skeletonAfterDoneCounts[url] =
          (_skeletonAfterDoneCounts[url] ?? 0) + 1;
      // Печатаем ВСЕГДА (не под флагом), потому что это сигнал «баг вернулся».
      debugPrint(
        '⚠️  [link-preview] REGRESSION: skeleton после done. '
        'url=${_short(url)} after-done#${_skeletonAfterDoneCounts[url]} '
        '(было done#$doneCount). '
        'Кеш потерял identity Future — лента дёргается.',
      );
    } else if (kLogLinkPreviewDiagnostics) {
      debugPrint('[link-preview] waiting url=${_short(url)} (initial)');
    }
  }

  /// Сброс — например, для unit-тестов. В рантайме чата не нужен.
  static void reset() {
    _doneCounts.clear();
    _skeletonAfterDoneCounts.clear();
  }

  /// Снапшот текущей телеметрии. Полезно, чтобы напечатать сводку
  /// в конце сессии чата.
  static Map<String, ({int done, int skeletonAfterDone})> snapshot() {
    final all = <String>{..._doneCounts.keys, ..._skeletonAfterDoneCounts.keys};
    return {
      for (final url in all)
        url: (
          done: _doneCounts[url] ?? 0,
          skeletonAfterDone: _skeletonAfterDoneCounts[url] ?? 0,
        ),
    };
  }

  /// Печатает сводку — сколько карточек было, сколько раз каждая сваливалась
  /// в waiting после done. Если все skeleton-after-done == 0 — баг побеждён.
  static void printSummary() {
    final snap = snapshot();
    if (snap.isEmpty) {
      debugPrint('[link-preview] summary: no cards observed');
      return;
    }
    var totalRegressions = 0;
    snap.forEach((url, s) {
      totalRegressions += s.skeletonAfterDone;
    });
    debugPrint(
      '[link-preview] summary: ${snap.length} unique cards, '
      '$totalRegressions skeleton-after-done events ${totalRegressions == 0 ? '✅ OK' : '❌ REGRESSION'}',
    );
    if (totalRegressions > 0) {
      snap.forEach((url, s) {
        if (s.skeletonAfterDone > 0) {
          debugPrint(
            '  ❌ ${_short(url)}: done#${s.done}, skeleton-after-done#${s.skeletonAfterDone}',
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
