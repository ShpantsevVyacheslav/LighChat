import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_chat_message.dart';

/// Контракт-тесты wire-формата для чата митинга.
/// Реальные документы с web-клиента выглядят так:
///
/// ```
/// { senderId: 'u-1', senderName: 'Alice', text: 'hi',
///   attachments: [], createdAt: Timestamp(...) }
/// ```
///
/// + опциональные `text` и `updatedAt`.
void main() {
  group('MeetingChatMessage.fromFirestore', () {
    test('parses typical text message', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'hi',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 22, 10)),
      });
      expect(m, isNotNull);
      expect(m!.id, 'm1');
      expect(m.senderId, 'u-1');
      expect(m.senderName, 'Alice');
      expect(m.text, 'hi');
      expect(m.attachmentsCount, 0);
      expect(m.createdAt?.toUtc(), DateTime.utc(2026, 4, 22, 10));
      expect(m.hasPayload, true);
      expect(m.updatedAt, isNull);
    });

    test('counts attachments regardless of payload shape', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'attachments': <dynamic>[
          <String, dynamic>{
            'url': 'https://x/a.jpg',
            'name': 'a.jpg',
            'type': 'image/jpeg',
            'size': 10,
          },
          <String, dynamic>{
            'url': 'https://x/b.pdf',
            'name': 'b.pdf',
            'type': 'application/pdf',
            'size': 20,
          },
        ],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 22)),
      })!;
      expect(m.text, isNull);
      expect(m.attachmentsCount, 2);
      expect(m.attachments.length, 2);
      expect(m.attachments.first.isImage, true);
      expect(m.attachments[1].isImage, false);
      expect(m.hasPayload, true);
    });

    test('parses numeric size as double from JSON-like map', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'attachments': <dynamic>[
          <String, dynamic>{
            'url': 'https://x/f',
            'name': 'f.png',
            'type': 'image/png',
            'size': 42.0,
          },
        ],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 22)),
      })!;
      expect(m.attachments.single.size, 42);
    });

    test('isVisibleRow for soft-deleted message', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'gone',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 22)),
        'isDeleted': true,
      })!;
      expect(m.isDeleted, true);
      expect(m.isVisibleRow, true);
    });

    test('isVisibleRow false when no text and no attachments', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'attachments': <dynamic>[],
      })!;
      expect(m.isVisibleRow, false);
    });

    test('treats empty text as null', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': '',
        'attachments': <dynamic>[],
      })!;
      expect(m.text, isNull);
      expect(m.hasPayload, false);
    });

    test('parses updatedAt from ISO string', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'edited',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 22, 10)),
        'updatedAt': '2026-04-22T10:05:00Z',
      })!;
      expect(m.updatedAt?.toUtc(), DateTime.utc(2026, 4, 22, 10, 5));
    });

    test('null on missing sender fields', () {
      expect(MeetingChatMessage.fromFirestore('m', null), isNull);
      expect(
        MeetingChatMessage.fromFirestore('m', <String, dynamic>{
          'senderName': 'Alice',
        }),
        isNull,
      );
      expect(
        MeetingChatMessage.fromFirestore('m', <String, dynamic>{
          'senderId': 'u-1',
        }),
        isNull,
      );
    });

    test('null on empty sender strings', () {
      expect(
        MeetingChatMessage.fromFirestore('m', <String, dynamic>{
          'senderId': '',
          'senderName': 'Alice',
        }),
        isNull,
      );
      expect(
        MeetingChatMessage.fromFirestore('m', <String, dynamic>{
          'senderId': 'u-1',
          'senderName': '',
        }),
        isNull,
      );
    });

    test('parses replyTo nested map', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-2',
        'senderName': 'Bob',
        'text': 'reply!',
        'attachments': <dynamic>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 12)),
        'replyTo': <String, dynamic>{
          'messageId': 'm-orig',
          'senderId': 'u-1',
          'senderName': 'Alice',
          'preview': 'original text',
        },
      })!;
      expect(m.replyTo, isNotNull);
      expect(m.replyTo!.messageId, 'm-orig');
      expect(m.replyTo!.senderId, 'u-1');
      expect(m.replyTo!.senderName, 'Alice');
      expect(m.replyTo!.preview, 'original text');
    });

    test('replyTo null when payload malformed', () {
      // Отсутствует обязательный messageId.
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-2',
        'senderName': 'Bob',
        'text': 'x',
        'attachments': <dynamic>[],
        'replyTo': <String, dynamic>{
          'senderId': 'u-1',
          'senderName': 'Alice',
        },
      })!;
      expect(m.replyTo, isNull);
    });

    test('parses reactions map and filters empty buckets', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'hi',
        'attachments': <dynamic>[],
        'reactions': <String, dynamic>{
          '👍': <dynamic>['u-1', 'u-2'],
          '🔥': <dynamic>['u-3'],
          // Пустые наборы реакций не сохраняем — иначе UI рисовал бы
          // «пустой» chip с count 0.
          '😢': <dynamic>[],
          // Невалидный uid в массиве — мусор фильтруем.
          '🎉': <dynamic>[null, 42, ''],
        },
      })!;
      expect(m.reactions.keys.toSet(), {'👍', '🔥'});
      expect(m.reactions['👍'], ['u-1', 'u-2']);
      expect(m.reactions['🔥'], ['u-3']);
    });

    test('parses senderAvatar when present', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'hi',
        'attachments': <dynamic>[],
        'senderAvatar': 'https://cdn.lighchat/u-1.png',
      })!;
      expect(m.senderAvatar, 'https://cdn.lighchat/u-1.png');
    });

    test('senderAvatar null on empty string', () {
      final m = MeetingChatMessage.fromFirestore('m1', <String, dynamic>{
        'senderId': 'u-1',
        'senderName': 'Alice',
        'text': 'hi',
        'attachments': <dynamic>[],
        'senderAvatar': '',
      })!;
      expect(m.senderAvatar, isNull);
    });
  });

  group('MeetingChatReplyTo', () {
    test('toMap → fromMap round-trip preserves payload', () {
      const original = MeetingChatReplyTo(
        messageId: 'm-1',
        senderId: 'u-1',
        senderName: 'Alice',
        preview: 'original text',
      );
      final reparsed = MeetingChatReplyTo.fromMap(original.toMap());
      expect(reparsed, isNotNull);
      expect(reparsed!.messageId, 'm-1');
      expect(reparsed.senderId, 'u-1');
      expect(reparsed.senderName, 'Alice');
      expect(reparsed.preview, 'original text');
    });

    test('fromMap returns null for non-map / missing messageId', () {
      expect(MeetingChatReplyTo.fromMap(null), isNull);
      expect(MeetingChatReplyTo.fromMap('string'), isNull);
      expect(
        MeetingChatReplyTo.fromMap(<String, dynamic>{
          'senderId': 'u-1',
          'senderName': 'Alice',
        }),
        isNull,
      );
    });

    test('fromMap defaults missing preview to empty string', () {
      final r = MeetingChatReplyTo.fromMap(<String, dynamic>{
        'messageId': 'm-1',
        'senderId': 'u-1',
        'senderName': 'Alice',
      });
      expect(r, isNotNull);
      expect(r!.preview, '');
    });
  });
}
