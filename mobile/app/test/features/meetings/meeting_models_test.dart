import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_models.dart';

/// Контракт-тесты wire-формата митингов.
///
/// Цель — предотвратить регресс сериализации и несовместимость с web-клиентом.
/// Пары (вход -> ожидаемое поле) повторяют `src/lib/types.ts` + продакшн-данные
/// из фичи `meetings` (см. `docs/arcitecture/meetings-wire-protocol.md`).
void main() {
  group('MeetingDoc.fromFirestore', () {
    test('parses minimal meeting with string createdAt', () {
      final doc = MeetingDoc.fromFirestore('m-1', <String, dynamic>{
        'name': 'Planning',
        'hostId': 'u-1',
        'isPrivate': true,
        'createdAt': '2026-04-01T10:00:00.000Z',
      });
      expect(doc, isNotNull);
      expect(doc!.id, 'm-1');
      expect(doc.name, 'Planning');
      expect(doc.hostId, 'u-1');
      expect(doc.isPrivate, true);
      expect(doc.status, 'active'); // fallback
      expect(doc.adminIds, isEmpty);
      expect(doc.isAdmin('u-1'), true);
      expect(doc.isAdmin('u-2'), false);
      expect(doc.createdAt.toUtc(),
          DateTime.utc(2026, 4, 1, 10, 0, 0));
    });

    test('parses adminIds from list', () {
      final doc = MeetingDoc.fromFirestore('m-1', <String, dynamic>{
        'name': 'Planning',
        'hostId': 'u-1',
        'isPrivate': false,
        'createdAt': '2026-04-01T10:00:00Z',
        'adminIds': <dynamic>['u-2', 42, 'u-3'], // нестрочные — отбрасываем
      });
      expect(doc!.adminIds, ['u-2', 'u-3']);
      expect(doc.isAdmin('u-2'), true);
    });

    test('parses Timestamp createdAt', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 4, 1));
      final doc = MeetingDoc.fromFirestore('m-1', <String, dynamic>{
        'name': 'x',
        'hostId': 'u-1',
        'isPrivate': false,
        'createdAt': ts,
      });
      expect(doc!.createdAt.toUtc(), DateTime.utc(2026, 4, 1));
    });

    test('returns null on missing required fields', () {
      expect(MeetingDoc.fromFirestore('m', null), isNull);
      expect(
        MeetingDoc.fromFirestore('m', <String, dynamic>{'hostId': 'u'}),
        isNull,
      );
      expect(
        MeetingDoc.fromFirestore('m', <String, dynamic>{'name': 'x'}),
        isNull,
      );
      expect(
        MeetingDoc.fromFirestore('m', <String, dynamic>{
          'name': 'x',
          'hostId': 'u',
        }),
        isNull,
      );
    });
  });

  group('MeetingParticipant.fromFirestore', () {
    test('parses all boolean flags defaulting to false', () {
      final p = MeetingParticipant.fromFirestore('u-1', <String, dynamic>{
        'name': 'Alice',
      });
      expect(p, isNotNull);
      expect(p!.id, 'u-1');
      expect(p.name, 'Alice');
      expect(p.isAudioMuted, false);
      expect(p.isVideoMuted, false);
      expect(p.isHandRaised, false);
      expect(p.isScreenSharing, false);
      expect(p.forceMuteAudio, false);
      expect(p.forceMuteVideo, false);
    });

    test('carries force-mute flags', () {
      final p = MeetingParticipant.fromFirestore('u-1', <String, dynamic>{
        'name': 'Alice',
        'forceMuteAudio': true,
        'forceMuteVideo': true,
        'facingMode': 'environment',
      })!;
      expect(p.forceMuteAudio, true);
      expect(p.forceMuteVideo, true);
      expect(p.facingMode, 'environment');
    });

    test('rejects empty name', () {
      final p = MeetingParticipant.fromFirestore('u-1', <String, dynamic>{
        'name': '',
      });
      expect(p, isNull);
    });

    test('carries reaction and screen share flags', () {
      final p = MeetingParticipant.fromFirestore('u-1', <String, dynamic>{
        'name': 'Alice',
        'isHandRaised': true,
        'isScreenSharing': true,
        'reaction': '🎉',
      })!;
      expect(p.isHandRaised, true);
      expect(p.isScreenSharing, true);
      expect(p.reaction, '🎉');
    });

    test('treats non-string reaction as null', () {
      final p = MeetingParticipant.fromFirestore('u-1', <String, dynamic>{
        'name': 'Alice',
        'reaction': 42,
      })!;
      expect(p.reaction, isNull);
    });
  });

  group('MeetingSignalDoc.fromFirestore', () {
    test('parses candidate payload verbatim', () {
      final doc = MeetingSignalDoc.fromFirestore('s-1', <String, dynamic>{
        'from': 'u-1',
        'to': 'u-2',
        'type': 'candidate',
        'data': <String, dynamic>{
          'candidate': 'candidate:1 1 udp 1 1.2.3.4 9999 typ host',
          'sdpMid': '0',
          'sdpMLineIndex': 0,
        },
      });
      expect(doc, isNotNull);
      expect(doc!.from, 'u-1');
      expect(doc.to, 'u-2');
      expect(doc.type, 'candidate');
      expect(doc.data['candidate'], contains('typ host'));
      expect(doc.data['sdpMLineIndex'], 0);
    });

    test('rejects non-map payload', () {
      expect(
        MeetingSignalDoc.fromFirestore('s-1', <String, dynamic>{
          'from': 'a',
          'to': 'b',
          'type': 'offer',
          'data': 'not-a-map',
        }),
        isNull,
      );
    });
  });

  group('MeetingRequestDoc.fromFirestore', () {
    test('parses status enum-like values', () {
      for (final status in <String>['pending', 'approved', 'denied']) {
        final r = MeetingRequestDoc.fromFirestore('u-1', <String, dynamic>{
          'name': 'Guest',
          'status': status,
        });
        expect(r, isNotNull, reason: status);
        expect(r!.status, status);
      }
    });

    test('null on missing required fields', () {
      expect(
        MeetingRequestDoc.fromFirestore('u-1', <String, dynamic>{
          'status': 'pending',
        }),
        isNull,
      );
      expect(
        MeetingRequestDoc.fromFirestore('u-1', <String, dynamic>{
          'name': 'x',
        }),
        isNull,
      );
    });
  });
}
