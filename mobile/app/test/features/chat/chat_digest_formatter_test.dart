import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/chat_digest_formatter.dart';
import 'package:lighchat_models/lighchat_models.dart';

ChatMessage _msg({
  required String id,
  required String senderId,
  String? text,
  List<ChatAttachment> attachments = const [],
  bool isDeleted = false,
  ChatSystemEvent? systemEvent,
  String? voiceTranscript,
  ChatLocationShare? locationShare,
  String? chatPollId,
}) {
  return ChatMessage(
    id: id,
    senderId: senderId,
    text: text,
    attachments: attachments,
    isDeleted: isDeleted,
    createdAt: DateTime.utc(2026, 5, 15, 10, 0),
    systemEvent: systemEvent,
    voiceTranscript: voiceTranscript,
    locationShare: locationShare,
    chatPollId: chatPollId,
  );
}

String _nameFor(String uid) {
  switch (uid) {
    case 'me':
      return 'You';
    case 'a':
      return 'Alice';
    case 'b':
      return 'Bob';
    default:
      return '?';
  }
}

void main() {
  group('formatMessagesForDigest', () {
    test('пустой список → пустая строка', () {
      expect(
        formatMessagesForDigest(messages: [], nameFor: _nameFor),
        isEmpty,
      );
    });

    test('обычные текстовые сообщения форматируются как Sender: text', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(id: '1', senderId: 'a', text: 'Hello'),
          _msg(id: '2', senderId: 'me', text: 'Hi there'),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Alice: Hello\nYou: Hi there');
    });

    test('isDeleted и systemEvent пропускаются', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(id: '1', senderId: 'a', text: 'Real msg'),
          _msg(id: '2', senderId: 'a', text: 'Deleted', isDeleted: true),
          _msg(
            id: '3',
            senderId: 'a',
            systemEvent: const ChatSystemEvent(
              type: ChatSystemEventType.gameStarted,
            ),
          ),
          _msg(id: '4', senderId: 'b', text: 'After deleted'),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Alice: Real msg\nBob: After deleted');
    });

    test('limit обрезает к последним N сообщениям', () {
      final messages = [
        for (var i = 0; i < 25; i++)
          _msg(id: '$i', senderId: 'a', text: 'msg $i'),
      ];
      final out = formatMessagesForDigest(
        messages: messages,
        nameFor: _nameFor,
        limit: 5,
      );
      // Должны быть msg 20..24
      final lines = out.split('\n');
      expect(lines, hasLength(5));
      expect(lines.first, 'Alice: msg 20');
      expect(lines.last, 'Alice: msg 24');
    });

    test('HTML-теги сворачиваются в plain text', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(id: '1', senderId: 'a', text: '<b>Bold</b> &amp; <i>italic</i>'),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Alice: Bold & italic');
    });

    test('длинное сообщение клипуется до maxCharsPerMessage с многоточием', () {
      final long = List.filled(500, 'a').join();
      final out = formatMessagesForDigest(
        messages: [_msg(id: '1', senderId: 'a', text: long)],
        nameFor: _nameFor,
        maxCharsPerMessage: 50,
      );
      expect(out.length, lessThan(80)); // 'Alice: ' + 50 chars + ellipsis
      expect(out, endsWith('…'));
    });

    test('пустой text без вложений пропускается', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(id: '1', senderId: 'a', text: ''),
          _msg(id: '2', senderId: 'a', text: '   '), // whitespace only
          _msg(id: '3', senderId: 'b', text: 'visible'),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Bob: visible');
    });

    test('вложение-картинка превращается в маркер [Image]', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(
            id: '1',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'http://x', name: 'a.jpg', type: 'image/jpeg'),
            ],
          ),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Alice: [Image]');
    });

    test('видео/аудио/стикер/gif/файл — разные маркеры', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(
            id: 'v',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'x', name: 'v.mp4', type: 'video/mp4'),
            ],
          ),
          _msg(
            id: 'au',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'x', name: 'a.m4a', type: 'audio/m4a'),
            ],
          ),
          _msg(
            id: 's',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'x', name: 's.png', type: 'sticker'),
            ],
          ),
          _msg(
            id: 'g',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'x', name: 'g.gif', type: 'image/gif'),
            ],
          ),
          _msg(
            id: 'f',
            senderId: 'a',
            attachments: const [
              ChatAttachment(url: 'x', name: 'f.pdf', type: 'application/pdf'),
            ],
          ),
        ],
        nameFor: _nameFor,
      );
      expect(out, contains('[Video]'));
      expect(out, contains('[Voice]'));
      expect(out, contains('[Sticker]'));
      expect(out, contains('[GIF]'));
      expect(out, contains('[File]'));
    });

    test('locationShare и chatPollId дают маркеры', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(
            id: 'loc',
            senderId: 'a',
            locationShare: const ChatLocationShare(
              lat: 55,
              lng: 37,
              mapsUrl: 'https://maps.example/x',
              capturedAt: '2026-05-15T10:00:00Z',
            ),
          ),
          _msg(id: 'poll', senderId: 'b', chatPollId: 'p1'),
        ],
        nameFor: _nameFor,
      );
      expect(out, contains('Alice: [Location]'));
      expect(out, contains('Bob: [Poll]'));
    });

    test('voiceTranscript показывается как [Voice] + текст', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(
            id: '1',
            senderId: 'a',
            voiceTranscript: 'Привет, как дела',
          ),
        ],
        nameFor: _nameFor,
      );
      expect(out, 'Alice: [Voice] Привет, как дела');
    });

    test('неизвестный sender — name() возвращает ?, используется как есть', () {
      final out = formatMessagesForDigest(
        messages: [
          _msg(id: '1', senderId: 'unknown_uid', text: 'hi'),
        ],
        nameFor: _nameFor,
      );
      expect(out, '?: hi');
    });
  });
}
