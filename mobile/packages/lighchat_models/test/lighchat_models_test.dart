import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_models/lighchat_models.dart';

class _FakeMessageDoc implements DocumentSnapshot<Map<String, Object?>> {
  _FakeMessageDoc(this._data, {this.id = 'm1'});

  final Map<String, Object?> _data;

  @override
  final String id;

  @override
  bool get exists => true;

  @override
  Map<String, Object?>? data() => _data;

  @override
  dynamic get(Object field) => _data[field];

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, Object?>> get reference =>
      throw UnimplementedError();
}

void main() {
  test('UserChatIndex.fromJson parses ids', () {
    final idx = UserChatIndex.fromJson({
      'conversationIds': ['a', 'b', '', 123],
    });
    expect(idx.conversationIds, ['a', 'b']);
  });

  test('ChatMessage.fromDoc parses expireAt timestamp', () {
    final expireAt = Timestamp.fromDate(DateTime.utc(2026, 1, 1, 12, 30));
    final msg = ChatMessage.fromDoc(
      _FakeMessageDoc({
        'senderId': 'u1',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1, 12)),
        'expireAt': expireAt,
      }),
    );

    expect(msg?.expireAt?.toUtc(), DateTime.utc(2026, 1, 1, 12, 30));
  });

  group('ChatLocationTrackPoint.fromJson — Bug 13 (Phase 13)', () {
    test('валидная точка парсится', () {
      final pt = ChatLocationTrackPoint.fromJson({
        'lat': 55.75,
        'lng': 37.61,
        'ts': '2026-05-16T10:00:00Z',
        'accuracyM': 12.5,
      });
      expect(pt, isNotNull);
      expect(pt!.lat, 55.75);
      expect(pt.lng, 37.61);
      expect(pt.ts, '2026-05-16T10:00:00Z');
      expect(pt.accuracyM, 12.5);
    });

    test('accuracyM опционален', () {
      final pt = ChatLocationTrackPoint.fromJson({
        'lat': 0.0,
        'lng': 0.0,
        'ts': '2026-05-16T10:00:00Z',
      });
      expect(pt, isNotNull);
      expect(pt!.accuracyM, isNull);
    });

    test('lat/lng обязательны — без них null', () {
      expect(
        ChatLocationTrackPoint.fromJson({
          'lng': 37.61,
          'ts': '2026-05-16T10:00:00Z',
        }),
        isNull,
      );
      expect(
        ChatLocationTrackPoint.fromJson({
          'lat': 55.75,
          'ts': '2026-05-16T10:00:00Z',
        }),
        isNull,
      );
    });

    test('ts обязателен, пустой — null', () {
      expect(
        ChatLocationTrackPoint.fromJson({
          'lat': 0.0,
          'lng': 0.0,
        }),
        isNull,
      );
      expect(
        ChatLocationTrackPoint.fromJson({
          'lat': 0.0,
          'lng': 0.0,
          'ts': '',
        }),
        isNull,
      );
    });

    test('toJson round-trip', () {
      const original = ChatLocationTrackPoint(
        lat: 1.5,
        lng: -2.5,
        ts: '2026-05-16T10:00:00Z',
        accuracyM: 3.0,
      );
      final back = ChatLocationTrackPoint.fromJson(original.toJson());
      expect(back, isNotNull);
      expect(back!.lat, original.lat);
      expect(back.lng, original.lng);
      expect(back.ts, original.ts);
      expect(back.accuracyM, original.accuracyM);
    });

    test('toJson без accuracyM не включает поле', () {
      const pt = ChatLocationTrackPoint(
        lat: 1.0,
        lng: 2.0,
        ts: 'iso',
      );
      expect(pt.toJson().containsKey('accuracyM'), isFalse);
    });
  });

  group('UserLiveLocationShare.fromJson — Bug #15 conversationId', () {
    Map<String, Object?> baseValid({Object? conversationId}) {
      return <String, Object?>{
        'active': true,
        'lat': 55.75,
        'lng': 37.61,
        'updatedAt': '2026-05-16T10:00:00Z',
        'startedAt': '2026-05-16T09:30:00Z',
        if (conversationId != null) 'conversationId': conversationId,
      };
    }

    test('пропускает conversationId если поле непустая строка', () {
      final v = UserLiveLocationShare.fromJson(
        baseValid(conversationId: 'conv_abc123'),
      );
      expect(v, isNotNull);
      expect(v!.conversationId, 'conv_abc123');
    });

    test('обрабатывает отсутствие conversationId как null (backward compat)', () {
      final v = UserLiveLocationShare.fromJson(baseValid());
      expect(v, isNotNull);
      expect(v!.conversationId, isNull);
    });

    test('игнорирует пустую строку conversationId', () {
      final v = UserLiveLocationShare.fromJson(baseValid(conversationId: ''));
      expect(v, isNotNull);
      expect(v!.conversationId, isNull);
    });

    test('игнорирует не-строковый conversationId (int / map / list)', () {
      for (final bad in <Object?>[42, <String, Object?>{}, <Object?>[]]) {
        final v = UserLiveLocationShare.fromJson(
          baseValid(conversationId: bad),
        );
        expect(v, isNotNull, reason: 'bad=$bad');
        expect(v!.conversationId, isNull, reason: 'bad=$bad');
      }
    });

    test('null lat/lng — вся запись отвергается', () {
      final v = UserLiveLocationShare.fromJson(<String, Object?>{
        'active': true,
        'updatedAt': '2026-05-16T10:00:00Z',
        'startedAt': '2026-05-16T09:30:00Z',
      });
      expect(v, isNull);
    });

    test('active=false тоже парсится (Stop сохраняет state до delete)', () {
      final v = UserLiveLocationShare.fromJson(<String, Object?>{
        'active': false,
        'lat': 55.75,
        'lng': 37.61,
        'updatedAt': '2026-05-16T10:00:00Z',
        'startedAt': '2026-05-16T09:30:00Z',
      });
      expect(v, isNotNull);
      expect(v!.active, isFalse);
    });
  });
}
