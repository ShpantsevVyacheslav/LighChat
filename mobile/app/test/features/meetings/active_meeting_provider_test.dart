import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/active_meeting_provider.dart';

/// Юнит-тесты на `activeMeetingProvider` — индикатор «идёт звонок»,
/// который чат-лист использует для пилюли «вернуться в звонок».
void main() {
  group('ActiveMeetingNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeMeetingProvider), isNull);
    });

    test('set assigns ActiveMeetingInfo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeMeetingProvider.notifier).set(
            const ActiveMeetingInfo(meetingId: 'm-1', meetingName: 'LighTech'),
          );
      final value = container.read(activeMeetingProvider);
      expect(value, isNotNull);
      expect(value!.meetingId, 'm-1');
      expect(value.meetingName, 'LighTech');
    });

    test('clear resets state to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeMeetingProvider.notifier).set(
            const ActiveMeetingInfo(meetingId: 'm-1', meetingName: 'LighTech'),
          );
      container.read(activeMeetingProvider.notifier).clear();
      expect(container.read(activeMeetingProvider), isNull);
    });

    test('setting null via set() also clears', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeMeetingProvider.notifier).set(
            const ActiveMeetingInfo(meetingId: 'm', meetingName: 'n'),
          );
      container.read(activeMeetingProvider.notifier).set(null);
      expect(container.read(activeMeetingProvider), isNull);
    });
  });

  group('ActiveMeetingInfo.copyWith', () {
    test('replaces meetingName only', () {
      const a = ActiveMeetingInfo(meetingId: 'm', meetingName: 'old');
      final b = a.copyWith(meetingName: 'new');
      expect(b.meetingId, 'm');
      expect(b.meetingName, 'new');
      expect(b.localStream, isNull);
      expect(b.frontCamera, isTrue);
    });

    test('flips frontCamera independently', () {
      const a = ActiveMeetingInfo(meetingId: 'm', meetingName: 'x');
      final b = a.copyWith(frontCamera: false);
      expect(b.frontCamera, isFalse);
      expect(b.meetingId, 'm');
    });
  });

  group('ActiveMeetingNotifier.updateLocalStream', () {
    test('is no-op when no active meeting', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // localStream==null здесь и есть смысл «нет стрима»; до set() это
      // вообще noop, поэтому state остаётся null.
      container.read(activeMeetingProvider.notifier).updateLocalStream(null);
      expect(container.read(activeMeetingProvider), isNull);
    });

    test('updates frontCamera while preserving other fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeMeetingProvider.notifier).set(
            const ActiveMeetingInfo(meetingId: 'm', meetingName: 'n'),
          );
      container
          .read(activeMeetingProvider.notifier)
          .updateLocalStream(null, frontCamera: false);
      final v = container.read(activeMeetingProvider)!;
      expect(v.meetingId, 'm');
      expect(v.meetingName, 'n');
      expect(v.frontCamera, isFalse);
    });
  });
}
