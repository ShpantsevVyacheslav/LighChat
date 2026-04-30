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
}
