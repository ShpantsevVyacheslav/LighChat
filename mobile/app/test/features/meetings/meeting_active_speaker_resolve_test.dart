import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_active_speaker_resolve.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_models.dart';

void main() {
  final ab = [
    const MeetingParticipant(id: 'a', name: 'A'),
    const MeetingParticipant(id: 'b', name: 'B'),
  ];

  group('resolveActiveSpeaker', () {
    test('null when below minScore', () {
      expect(
        resolveActiveSpeaker(
          scores: {'a': 0.5, 'b': 0.3},
          participants: ab,
        ),
        isNull,
      );
    });

    test('picks loudest', () {
      expect(
        resolveActiveSpeaker(
          scores: {'a': 2, 'b': 8},
          participants: ab,
          minScore: 2,
        ),
        'b',
      );
    });

    test('stickiness keeps previous when close', () {
      expect(
        resolveActiveSpeaker(
          scores: {'a': 10, 'b': 12},
          participants: ab,
          previous: 'a',
          minScore: 2,
          stickiness: 0.72,
        ),
        'a',
      );
    });

    test('switches when previous falls behind', () {
      expect(
        resolveActiveSpeaker(
          scores: {'a': 5, 'b': 12},
          participants: ab,
          previous: 'a',
          minScore: 2,
          stickiness: 0.72,
        ),
        'b',
      );
    });

    test('ignores audio-muted participants', () {
      final muted = [
        const MeetingParticipant(id: 'a', name: 'A', isAudioMuted: true),
        const MeetingParticipant(id: 'b', name: 'B'),
      ];
      expect(
        resolveActiveSpeaker(
          scores: {'a': 100, 'b': 3},
          participants: muted,
          minScore: 2,
        ),
        'b',
      );
    });
  });
}
