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
  });
}
