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
}
