import 'dart:async' show StreamSubscription, unawaited;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Discrete threshold positions for the "Power saving mode" slider.
///
/// Mirrors Telegram's "Энергосбережение" page where the user picks a battery
/// percentage at which resource-heavy effects are auto-disabled. Position 0 ==
/// off (effects always on), position 6 == always on (effects always off).
enum EnergySavingThreshold {
  off(0),
  at5(5),
  at10(10),
  at15(15),
  at20(20),
  at25(25),
  always(100);

  const EnergySavingThreshold(this.percent);

  final int percent;

  static EnergySavingThreshold fromIndex(int idx) {
    if (idx <= 0) return EnergySavingThreshold.off;
    if (idx >= EnergySavingThreshold.values.length) {
      return EnergySavingThreshold.always;
    }
    return EnergySavingThreshold.values[idx];
  }
}

class EnergySavingState {
  const EnergySavingState({
    required this.threshold,
    required this.autoplayVideo,
    required this.autoplayGif,
    required this.animatedStickers,
    required this.animatedEmoji,
    required this.interfaceAnimations,
    required this.mediaPreload,
    required this.backgroundUpdate,
    required this.batteryLevelPercent,
  });

  /// Default values match Telegram's defaults: every effect is on, threshold
  /// is 15% (a sensible middle of the slider).
  factory EnergySavingState.defaults() => const EnergySavingState(
    threshold: EnergySavingThreshold.at15,
    autoplayVideo: true,
    autoplayGif: true,
    animatedStickers: true,
    animatedEmoji: true,
    interfaceAnimations: true,
    mediaPreload: true,
    backgroundUpdate: true,
    batteryLevelPercent: null,
  );

  final EnergySavingThreshold threshold;
  final bool autoplayVideo;
  final bool autoplayGif;
  final bool animatedStickers;
  final bool animatedEmoji;
  final bool interfaceAnimations;
  final bool mediaPreload;
  final bool backgroundUpdate;

  /// Last reported battery level (0-100) or null if unknown.
  final int? batteryLevelPercent;

  /// Whether the auto-disable rule is currently kicking in given the battery
  /// level and selected threshold.
  bool get isLowPowerActive {
    final lvl = batteryLevelPercent;
    switch (threshold) {
      case EnergySavingThreshold.off:
        return false;
      case EnergySavingThreshold.always:
        return true;
      default:
        if (lvl == null) return false;
        return lvl <= threshold.percent;
    }
  }

  /// Effective getters: read these from feature code instead of the raw flags.
  bool get effectiveAutoplayVideo => autoplayVideo && !isLowPowerActive;
  bool get effectiveAutoplayGif => autoplayGif && !isLowPowerActive;
  bool get effectiveAnimatedStickers => animatedStickers && !isLowPowerActive;
  bool get effectiveAnimatedEmoji => animatedEmoji && !isLowPowerActive;
  bool get effectiveInterfaceAnimations =>
      interfaceAnimations && !isLowPowerActive;
  bool get effectiveMediaPreload => mediaPreload && !isLowPowerActive;
  bool get effectiveBackgroundUpdate => backgroundUpdate && !isLowPowerActive;

  EnergySavingState copyWith({
    EnergySavingThreshold? threshold,
    bool? autoplayVideo,
    bool? autoplayGif,
    bool? animatedStickers,
    bool? animatedEmoji,
    bool? interfaceAnimations,
    bool? mediaPreload,
    bool? backgroundUpdate,
    Object? batteryLevelPercent = _sentinel,
  }) {
    return EnergySavingState(
      threshold: threshold ?? this.threshold,
      autoplayVideo: autoplayVideo ?? this.autoplayVideo,
      autoplayGif: autoplayGif ?? this.autoplayGif,
      animatedStickers: animatedStickers ?? this.animatedStickers,
      animatedEmoji: animatedEmoji ?? this.animatedEmoji,
      interfaceAnimations: interfaceAnimations ?? this.interfaceAnimations,
      mediaPreload: mediaPreload ?? this.mediaPreload,
      backgroundUpdate: backgroundUpdate ?? this.backgroundUpdate,
      batteryLevelPercent: identical(batteryLevelPercent, _sentinel)
          ? this.batteryLevelPercent
          : batteryLevelPercent as int?,
    );
  }
}

const Object _sentinel = Object();

const _kThresholdKey = 'energySaving.threshold';
const _kAutoplayVideoKey = 'energySaving.autoplayVideo';
const _kAutoplayGifKey = 'energySaving.autoplayGif';
const _kAnimatedStickersKey = 'energySaving.animatedStickers';
const _kAnimatedEmojiKey = 'energySaving.animatedEmoji';
const _kInterfaceAnimationsKey = 'energySaving.interfaceAnimations';
const _kMediaPreloadKey = 'energySaving.mediaPreload';
const _kBackgroundUpdateKey = 'energySaving.backgroundUpdate';

class EnergySavingNotifier extends Notifier<EnergySavingState> {
  Battery? _battery;
  StreamSubscription<BatteryState>? _batterySub;

  @override
  EnergySavingState build() {
    unawaited(_init());
    ref.onDispose(() {
      unawaited(_batterySub?.cancel());
      _batterySub = null;
      _battery = null;
    });
    return EnergySavingState.defaults();
  }

  Future<void> _init() async {
    await _loadFromPrefs();
    _attachBatteryListener();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = EnergySavingState.defaults();
    final next = state.copyWith(
      threshold: EnergySavingThreshold.fromIndex(
        prefs.getInt(_kThresholdKey) ?? defaults.threshold.index,
      ),
      autoplayVideo:
          prefs.getBool(_kAutoplayVideoKey) ?? defaults.autoplayVideo,
      autoplayGif: prefs.getBool(_kAutoplayGifKey) ?? defaults.autoplayGif,
      animatedStickers:
          prefs.getBool(_kAnimatedStickersKey) ?? defaults.animatedStickers,
      animatedEmoji:
          prefs.getBool(_kAnimatedEmojiKey) ?? defaults.animatedEmoji,
      interfaceAnimations:
          prefs.getBool(_kInterfaceAnimationsKey) ??
          defaults.interfaceAnimations,
      mediaPreload: prefs.getBool(_kMediaPreloadKey) ?? defaults.mediaPreload,
      backgroundUpdate:
          prefs.getBool(_kBackgroundUpdateKey) ?? defaults.backgroundUpdate,
    );
    if (!_eq(state, next)) state = next;
  }

  void _attachBatteryListener() {
    if (_battery != null) return;
    try {
      final battery = Battery();
      _battery = battery;
      unawaited(_refreshBatteryLevel());
      _batterySub = battery.onBatteryStateChanged.listen((_) {
        unawaited(_refreshBatteryLevel());
      });
    } catch (_) {
      // Platform may not support battery info (e.g. desktop test runs).
    }
  }

  Future<void> _refreshBatteryLevel() async {
    final battery = _battery;
    if (battery == null) return;
    try {
      final lvl = await battery.batteryLevel;
      final clamped = lvl.clamp(0, 100);
      if (state.batteryLevelPercent == clamped) return;
      state = state.copyWith(batteryLevelPercent: clamped);
    } catch (_) {
      // Ignore — keep previous value.
    }
  }

  Future<void> setThreshold(EnergySavingThreshold next) async {
    if (state.threshold == next) return;
    state = state.copyWith(threshold: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdKey, next.index);
  }

  Future<void> setAutoplayVideo(bool value) =>
      _setBool(_kAutoplayVideoKey, value, (s, v) => s.copyWith(autoplayVideo: v));

  Future<void> setAutoplayGif(bool value) =>
      _setBool(_kAutoplayGifKey, value, (s, v) => s.copyWith(autoplayGif: v));

  Future<void> setAnimatedStickers(bool value) => _setBool(
    _kAnimatedStickersKey,
    value,
    (s, v) => s.copyWith(animatedStickers: v),
  );

  Future<void> setAnimatedEmoji(bool value) => _setBool(
    _kAnimatedEmojiKey,
    value,
    (s, v) => s.copyWith(animatedEmoji: v),
  );

  Future<void> setInterfaceAnimations(bool value) => _setBool(
    _kInterfaceAnimationsKey,
    value,
    (s, v) => s.copyWith(interfaceAnimations: v),
  );

  Future<void> setMediaPreload(bool value) =>
      _setBool(_kMediaPreloadKey, value, (s, v) => s.copyWith(mediaPreload: v));

  Future<void> setBackgroundUpdate(bool value) => _setBool(
    _kBackgroundUpdateKey,
    value,
    (s, v) => s.copyWith(backgroundUpdate: v),
  );

  Future<void> _setBool(
    String key,
    bool value,
    EnergySavingState Function(EnergySavingState s, bool v) apply,
  ) async {
    final next = apply(state, value);
    if (_eq(state, next)) return;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  bool _eq(EnergySavingState a, EnergySavingState b) =>
      a.threshold == b.threshold &&
      a.autoplayVideo == b.autoplayVideo &&
      a.autoplayGif == b.autoplayGif &&
      a.animatedStickers == b.animatedStickers &&
      a.animatedEmoji == b.animatedEmoji &&
      a.interfaceAnimations == b.interfaceAnimations &&
      a.mediaPreload == b.mediaPreload &&
      a.backgroundUpdate == b.backgroundUpdate &&
      a.batteryLevelPercent == b.batteryLevelPercent;
}

final energySavingProvider =
    NotifierProvider<EnergySavingNotifier, EnergySavingState>(
      EnergySavingNotifier.new,
    );
