import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_chat_repository.dart';

/// Контракт-тесты [MeetingChatRepository] через `fake_cloud_firestore`.
/// Тестируем wire-формат, который ловит web (см. `meetings-wire-protocol.md`).
void main() {
  const meetingId = 'mtg-1';

  group('MeetingChatRepository.sendMessage', () {
    test('writes minimal text message without optional fields', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);

      await repo.sendMessage(
        meetingId: meetingId,
        senderId: 'u-1',
        senderName: 'Alice',
        text: 'hi',
        attachmentMaps: const [],
      );

      final docs = await fs
          .collection('meetings/$meetingId/messages')
          .get();
      expect(docs.docs, hasLength(1));
      final data = docs.docs.first.data();
      expect(data['senderId'], 'u-1');
      expect(data['senderName'], 'Alice');
      expect(data['text'], 'hi');
      expect(data['attachments'], <dynamic>[]);
      expect(data.containsKey('replyTo'), isFalse);
      expect(data.containsKey('senderAvatar'), isFalse);
    });

    test('persists replyToMap when reply is present', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);

      await repo.sendMessage(
        meetingId: meetingId,
        senderId: 'u-2',
        senderName: 'Bob',
        text: 'reply',
        attachmentMaps: const [],
        replyToMap: const <String, dynamic>{
          'messageId': 'm-orig',
          'senderId': 'u-1',
          'senderName': 'Alice',
          'preview': 'original',
        },
      );

      final docs = await fs
          .collection('meetings/$meetingId/messages')
          .get();
      final data = docs.docs.single.data();
      expect(data['replyTo'], <String, dynamic>{
        'messageId': 'm-orig',
        'senderId': 'u-1',
        'senderName': 'Alice',
        'preview': 'original',
      });
    });

    test('persists senderAvatar when non-empty', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);

      await repo.sendMessage(
        meetingId: meetingId,
        senderId: 'u-1',
        senderName: 'Alice',
        text: 'hi',
        attachmentMaps: const [],
        senderAvatar: 'https://cdn.lighchat/u-1.png',
      );

      final data = (await fs
              .collection('meetings/$meetingId/messages')
              .get())
          .docs
          .single
          .data();
      expect(data['senderAvatar'], 'https://cdn.lighchat/u-1.png');
    });

    test('skips senderAvatar field when empty string', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);

      await repo.sendMessage(
        meetingId: meetingId,
        senderId: 'u-1',
        senderName: 'Alice',
        text: 'hi',
        attachmentMaps: const [],
        senderAvatar: '',
      );

      final data = (await fs
              .collection('meetings/$meetingId/messages')
              .get())
          .docs
          .single
          .data();
      expect(data.containsKey('senderAvatar'), isFalse);
    });

    test('drops empty text+attachments without writing a doc', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);

      await repo.sendMessage(
        meetingId: meetingId,
        senderId: 'u-1',
        senderName: 'Alice',
        text: '   ',
        attachmentMaps: const [],
      );

      final docs = await fs
          .collection('meetings/$meetingId/messages')
          .get();
      expect(docs.docs, isEmpty);
    });
  });

  group('MeetingChatRepository.toggleReaction', () {
    Future<DocumentReference<Map<String, dynamic>>> seedMessage(
      FakeFirebaseFirestore fs, {
      Map<String, dynamic>? reactions,
    }) async {
      final col = fs.collection('meetings/$meetingId/messages');
      final ref = await col.add(<String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'hi',
        'attachments': <dynamic>[],
        'createdAt': FieldValue.serverTimestamp(),
        if (reactions != null) 'reactions': reactions,
      });
      return ref;
    }

    test('adds uid to reactions.<emoji> via arrayUnion semantics', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final ref = await seedMessage(fs);

      await repo.toggleReaction(
        meetingId: meetingId,
        messageId: ref.id,
        userId: 'u-2',
        emoji: '👍',
        currentlyReacted: false,
      );

      final after = await ref.get();
      final reactions = (after.data()!['reactions'] as Map?) ?? const {};
      expect(reactions['👍'], ['u-2']);
    });

    test('removes uid from reactions.<emoji> via arrayRemove semantics',
        () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final ref = await seedMessage(fs, reactions: <String, dynamic>{
        '👍': <String>['u-1', 'u-2'],
      });

      await repo.toggleReaction(
        meetingId: meetingId,
        messageId: ref.id,
        userId: 'u-1',
        emoji: '👍',
        currentlyReacted: true,
      );

      final after = await ref.get();
      final reactions = (after.data()!['reactions'] as Map?) ?? const {};
      expect(reactions['👍'], ['u-2']);
    });

    test('two users on the same emoji accumulate without overwriting',
        () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final ref = await seedMessage(fs);

      await repo.toggleReaction(
        meetingId: meetingId,
        messageId: ref.id,
        userId: 'u-1',
        emoji: '🔥',
        currentlyReacted: false,
      );
      await repo.toggleReaction(
        meetingId: meetingId,
        messageId: ref.id,
        userId: 'u-2',
        emoji: '🔥',
        currentlyReacted: false,
      );

      final after = await ref.get();
      final reactions = (after.data()!['reactions'] as Map?) ?? const {};
      expect(reactions['🔥'], unorderedEquals(<String>['u-1', 'u-2']));
    });
  });

  group('MeetingChatRepository.updateMessageText', () {
    test('writes trimmed text + updatedAt ISO string', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final col = fs.collection('meetings/$meetingId/messages');
      final ref = await col.add(<String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'old',
        'attachments': <dynamic>[],
      });

      await repo.updateMessageText(
        meetingId: meetingId,
        messageId: ref.id,
        text: '  new text  ',
      );

      final data = (await ref.get()).data()!;
      expect(data['text'], 'new text');
      expect(data['updatedAt'], isA<String>());
      // ISO-8601 UTC marker.
      expect((data['updatedAt'] as String).endsWith('Z'), isTrue);
    });

    test('throws on empty trimmed text (paritet web-input)', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final ref = await fs.collection('meetings/$meetingId/messages').add({
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'x',
        'attachments': <dynamic>[],
      });
      expect(
        () => repo.updateMessageText(
          meetingId: meetingId,
          messageId: ref.id,
          text: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MeetingChatRepository.softDeleteMessage', () {
    test('flips isDeleted true', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final ref = await fs.collection('meetings/$meetingId/messages').add({
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'gone',
        'attachments': <dynamic>[],
      });

      await repo.softDeleteMessage(
        meetingId: meetingId,
        messageId: ref.id,
      );

      final data = (await ref.get()).data()!;
      expect(data['isDeleted'], isTrue);
    });
  });

  group('MeetingChatRepository.watchMessages', () {
    test('streams parsed messages in chronological order', () async {
      final fs = FakeFirebaseFirestore();
      final repo = MeetingChatRepository(fs);
      final col = fs.collection('meetings/$meetingId/messages');

      // Создаём в любом порядке — `watchMessages` сортирует по createdAt asc.
      await col.add(<String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'second',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 12, 10, 1)),
      });
      await col.add(<String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'first',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 12, 10, 0)),
      });

      final list = await repo.watchMessages(meetingId).first;
      expect(list.map((m) => m.text), ['first', 'second']);
    });
  });
}
