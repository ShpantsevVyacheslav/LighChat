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
