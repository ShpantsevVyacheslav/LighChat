import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;

/// Глобальные счётчики для диагностики scroll-jitter в чате с
/// большим количеством location-артефактов (карты, end-of-share
/// pill'ы, location-request bubble'ы). Каждое тяжёлое-в-рендере
/// место location-фичи инкрементит свой счётчик; раз в секунду —
/// snapshot в debug-log.
///
/// Зачем: jitter сложно поймать одним trace'ом. Проще раз/сек
/// видеть «активных подписок 18, build'ов карты за секунду 240,
/// scroll tick'ов 60» — мгновенно становится понятно, где
/// перерасход.
///
/// Использование:
///   `LocationScrollDiag.tickScroll(position.pixels)` в scroll
///   listener; `LocationScrollDiag.tickCardBuild()` в
///   `MessageLocationCard.build`; `tickCardSubscribe/Unsubscribe`
///   в `initState/dispose` StreamBuilder'ов; `tickMapBuild` в
///   `ChatLocationMapView.build` итд.
class LocationScrollDiag {
  LocationScrollDiag._();

  static int _scrollTicks = 0;
  static double? _lastPixels;
  static int _cardBuilds = 0;
  static int _mapBuilds = 0;
  static int _activeCardSubs = 0;
  static int _activeTrackSubs = 0;
  static int _countdownTicks = 0;
  static int _maxJumpPx = 0;
  static Timer? _flushTimer;

  /// В тестовом binding'е `Timer.periodic` ловит `!timersPending`
  /// assertion при teardown. Diagnostics в тестах не нужны — кто
  /// захочет mock'нуть, выставит флаг вручную.
  static bool _isTestEnv() {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
  }

  /// Инициализируется лениво при первом tick'е, чтобы не
  /// добавлять стартовый оверхед на холодный старт чата.
  static void _ensureTimer() {
    if (_flushTimer != null || !kDebugMode) return;
    if (_isTestEnv()) return;
    _flushTimer = Timer.periodic(const Duration(seconds: 1), (_) => _flush());
  }

  static void _flush() {
    // Печатаем только если за секунду было хоть какое-то движение —
    // молчаливые тики не интересны.
    if (_scrollTicks == 0 &&
        _cardBuilds == 0 &&
        _mapBuilds == 0 &&
        _countdownTicks == 0) {
      return;
    }
    debugPrint(
      '[loc-scroll-diag] scrollTicks=$_scrollTicks maxJumpPx=$_maxJumpPx '
      'cardBuilds=$_cardBuilds mapBuilds=$_mapBuilds '
      'cardSubs=$_activeCardSubs trackSubs=$_activeTrackSubs '
      'countdownTicks=$_countdownTicks',
    );
    _scrollTicks = 0;
    _cardBuilds = 0;
    _mapBuilds = 0;
    _countdownTicks = 0;
    _maxJumpPx = 0;
  }

  static void tickScroll(double pixels) {
    if (!kDebugMode) return;
    _ensureTimer();
    _scrollTicks++;
    final prev = _lastPixels;
    if (prev != null) {
      final jump = (pixels - prev).abs().round();
      if (jump > _maxJumpPx) _maxJumpPx = jump;
    }
    _lastPixels = pixels;
  }

  static void tickCardBuild() {
    if (!kDebugMode) return;
    _ensureTimer();
    _cardBuilds++;
  }

  static void tickMapBuild() {
    if (!kDebugMode) return;
    _ensureTimer();
    _mapBuilds++;
  }

  static void cardSubscribe() {
    if (!kDebugMode) return;
    _activeCardSubs++;
  }

  static void cardUnsubscribe() {
    if (!kDebugMode) return;
    if (_activeCardSubs > 0) _activeCardSubs--;
  }

  static void trackSubscribe() {
    if (!kDebugMode) return;
    _activeTrackSubs++;
  }

  static void trackUnsubscribe() {
    if (!kDebugMode) return;
    if (_activeTrackSubs > 0) _activeTrackSubs--;
  }

  static void tickCountdown() {
    if (!kDebugMode) return;
    _ensureTimer();
    _countdownTicks++;
  }
}
