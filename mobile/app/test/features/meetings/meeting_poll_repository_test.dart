import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_poll_repository.dart';

void main() {
  group('MeetingPollRepository.votesToFirestore', () {
    test('single choice stored as int', () {
      expect(
        MeetingPollRepository.votesToFirestore({'u1': [2]}),
        <String, dynamic>{'u1': 2},
      );
    });

    test('multiple choices stored as list', () {
      expect(
        MeetingPollRepository.votesToFirestore({'u1': [0, 2]}),
        <String, dynamic>{'u1': [0, 2]},
      );
    });

    test('skips empty selections', () {
      expect(
        MeetingPollRepository.votesToFirestore({
          'u1': <int>[],
          'u2': [1],
        }),
        <String, dynamic>{'u2': 1},
      );
    });
  });
}
