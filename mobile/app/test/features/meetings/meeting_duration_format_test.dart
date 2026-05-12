import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_duration_format.dart';

/// Юнит-тесты [computeMeetingTimer] — детерминированы благодаря явному `now`.
void main() {
  group('computeMeetingTimer (countdown)', () {
    final created = DateTime.utc(2026, 5, 12, 10, 0);

    test('formats remaining mm:ss with normal level above 5 minutes', () {
      final now = DateTime.utc(2026, 5, 12, 10, 5);
      final expiresAt = DateTime.utc(2026, 5, 12, 10, 30);
      final s = computeMeetingTimer(
        now: now,
        createdAt: created,
        expiresAt: expiresAt,
      );
      expect(s.isCountdown, isTrue);
      expect(s.formatted, '25:00');
      expect(s.level, MeetingTimerLevel.normal);
    });

    test('switches to warning under 5 minutes', () {
      final now = DateTime.utc(2026, 5, 12, 10, 0);
      final expiresAt = DateTime.utc(2026, 5, 12, 10, 3, 30);
      final s = computeMeetingTimer(
        now: now,
        createdAt: created,
        expiresAt: expiresAt,
      );
      expect(s.isCountdown, isTrue);
      expect(s.formatted, '03:30');
      expect(s.level, MeetingTimerLevel.warning);
    });

    test('switches to danger at and below 60 seconds', () {
      final s60 = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 10, 0),
        createdAt: created,
        expiresAt: DateTime.utc(2026, 5, 12, 10, 1),
      );
      expect(s60.formatted, '01:00');
      expect(s60.level, MeetingTimerLevel.danger);

      final s1 = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 10, 0, 59),
        createdAt: created,
        expiresAt: DateTime.utc(2026, 5, 12, 10, 1),
      );
      expect(s1.formatted, '00:01');
      expect(s1.level, MeetingTimerLevel.danger);
    });

    test('expired meeting goes negative and falls back to normal level', () {
      final s = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 10, 30),
        createdAt: created,
        expiresAt: DateTime.utc(2026, 5, 12, 10, 25),
      );
      expect(s.isCountdown, isTrue);
      expect(s.formatted, '-05:00');
      expect(s.level, MeetingTimerLevel.normal);
    });

    test('hours appear when remaining ≥ 1h', () {
      final s = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 10, 0),
        createdAt: created,
        expiresAt: DateTime.utc(2026, 5, 12, 11, 30, 15),
      );
      expect(s.formatted, '1:30:15');
      expect(s.level, MeetingTimerLevel.normal);
    });
  });

  group('computeMeetingTimer (elapsed)', () {
    final created = DateTime.utc(2026, 5, 12, 9, 0);

    test('formats elapsed without sign', () {
      final s = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 9, 5, 12),
        createdAt: created,
        expiresAt: null,
      );
      expect(s.isCountdown, isFalse);
      expect(s.formatted, '05:12');
      expect(s.level, MeetingTimerLevel.normal);
    });

    test('uses h:mm:ss past one hour', () {
      final s = computeMeetingTimer(
        now: DateTime.utc(2026, 5, 12, 11, 0, 5),
        createdAt: created,
        expiresAt: null,
      );
      expect(s.formatted, '2:00:05');
    });
  });

  group('meetingTimerColorFor', () {
    test('maps every level to a distinct color', () {
      final colors = MeetingTimerLevel.values
          .map(meetingTimerColorFor)
          .toSet();
      expect(colors.length, MeetingTimerLevel.values.length);
    });

    test('danger is red, warning is amber', () {
      expect(meetingTimerColorFor(MeetingTimerLevel.danger),
          const Color(0xFFF87171));
      expect(meetingTimerColorFor(MeetingTimerLevel.warning),
          const Color(0xFFFBBF24));
    });
  });
}
