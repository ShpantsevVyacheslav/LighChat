import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/settings/data/energy_saving_preference.dart';

EnergySavingState _state({
  EnergySavingThreshold threshold = EnergySavingThreshold.at15,
  bool autoplayVideo = true,
  bool autoplayGif = true,
  bool animatedStickers = true,
  bool animatedEmoji = true,
  bool interfaceAnimations = true,
  bool mediaPreload = true,
  bool backgroundUpdate = true,
  int? batteryLevelPercent,
}) {
  return EnergySavingState(
    threshold: threshold,
    autoplayVideo: autoplayVideo,
    autoplayGif: autoplayGif,
    animatedStickers: animatedStickers,
    animatedEmoji: animatedEmoji,
    interfaceAnimations: interfaceAnimations,
    mediaPreload: mediaPreload,
    backgroundUpdate: backgroundUpdate,
    batteryLevelPercent: batteryLevelPercent,
  );
}

void main() {
  group('EnergySavingThreshold', () {
    test('fromIndex clamps below zero to off', () {
      expect(
        EnergySavingThreshold.fromIndex(-5),
        EnergySavingThreshold.off,
      );
    });

    test('fromIndex clamps above max to always', () {
      expect(
        EnergySavingThreshold.fromIndex(999),
        EnergySavingThreshold.always,
      );
    });

    test('fromIndex round-trips through enum index', () {
      for (final t in EnergySavingThreshold.values) {
        expect(EnergySavingThreshold.fromIndex(t.index), t);
      }
    });

    test('percent values match Telegram-style stops', () {
      expect(EnergySavingThreshold.off.percent, 0);
      expect(EnergySavingThreshold.at5.percent, 5);
      expect(EnergySavingThreshold.at15.percent, 15);
      expect(EnergySavingThreshold.at25.percent, 25);
      expect(EnergySavingThreshold.always.percent, 100);
    });
  });

  group('EnergySavingState.isLowPowerActive', () {
    test('off threshold never activates regardless of battery', () {
      for (final lvl in <int?>[null, 0, 5, 50, 100]) {
        expect(
          _state(
            threshold: EnergySavingThreshold.off,
            batteryLevelPercent: lvl,
          ).isLowPowerActive,
          isFalse,
        );
      }
    });

    test('always threshold activates regardless of battery', () {
      for (final lvl in <int?>[null, 0, 50, 100]) {
        expect(
          _state(
            threshold: EnergySavingThreshold.always,
            batteryLevelPercent: lvl,
          ).isLowPowerActive,
          isTrue,
        );
      }
    });

    test('numeric threshold ignored when battery level is unknown', () {
      expect(
        _state(
          threshold: EnergySavingThreshold.at15,
          batteryLevelPercent: null,
        ).isLowPowerActive,
        isFalse,
      );
    });

    test('activates when battery is at or below threshold', () {
      expect(
        _state(
          threshold: EnergySavingThreshold.at15,
          batteryLevelPercent: 15,
        ).isLowPowerActive,
        isTrue,
      );
      expect(
        _state(
          threshold: EnergySavingThreshold.at15,
          batteryLevelPercent: 5,
        ).isLowPowerActive,
        isTrue,
      );
    });

    test('does not activate when battery is above threshold', () {
      expect(
        _state(
          threshold: EnergySavingThreshold.at15,
          batteryLevelPercent: 16,
        ).isLowPowerActive,
        isFalse,
      );
      expect(
        _state(
          threshold: EnergySavingThreshold.at15,
          batteryLevelPercent: 100,
        ).isLowPowerActive,
        isFalse,
      );
    });
  });

  group('EnergySavingState.effective*', () {
    test('returns raw flag when low-power is not active', () {
      final s = _state(
        threshold: EnergySavingThreshold.at15,
        batteryLevelPercent: 80,
        autoplayVideo: true,
        animatedEmoji: false,
      );
      expect(s.isLowPowerActive, isFalse);
      expect(s.effectiveAutoplayVideo, isTrue);
      expect(s.effectiveAnimatedEmoji, isFalse);
    });

    test('forces every effect off when low-power is active', () {
      final s = _state(
        threshold: EnergySavingThreshold.at15,
        batteryLevelPercent: 10,
      );
      expect(s.isLowPowerActive, isTrue);
      expect(s.effectiveAutoplayVideo, isFalse);
      expect(s.effectiveAutoplayGif, isFalse);
      expect(s.effectiveAnimatedStickers, isFalse);
      expect(s.effectiveAnimatedEmoji, isFalse);
      expect(s.effectiveInterfaceAnimations, isFalse);
      expect(s.effectiveMediaPreload, isFalse);
      expect(s.effectiveBackgroundUpdate, isFalse);
    });

    test('always threshold forces every effect off regardless of battery', () {
      final s = _state(
        threshold: EnergySavingThreshold.always,
        batteryLevelPercent: 100,
      );
      expect(s.effectiveAutoplayVideo, isFalse);
      expect(s.effectiveAnimatedEmoji, isFalse);
    });
  });

  group('EnergySavingState.copyWith', () {
    test('preserves batteryLevelPercent when sentinel is used (no arg)', () {
      final s =
          _state(batteryLevelPercent: 42).copyWith(autoplayVideo: false);
      expect(s.batteryLevelPercent, 42);
      expect(s.autoplayVideo, isFalse);
    });

    test('explicit null clears batteryLevelPercent', () {
      final s = _state(batteryLevelPercent: 42)
          .copyWith(batteryLevelPercent: null);
      expect(s.batteryLevelPercent, isNull);
    });
  });
}
