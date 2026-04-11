import 'package:lighchat_models/lighchat_models.dart';

final _urlRe = RegExp(r'(https?:\/\/[^\s]+)');

/// Счётчики для строки «Медиа, ссылки и файлы» в профиле чата (как web `categorizeAttachmentsFromMessages`).
int profileMediaDocsCount(List<ChatMessage> messages) {
  final media = <String>{};
  final files = <String>{};
  final links = <String>{};

  for (final msg in messages) {
    if (msg.isDeleted) continue;
    for (final att in msg.attachments) {
      final t = att.type ?? '';
      final isSticker = att.name.startsWith('sticker_') || t.contains('svg');
      final isCircle = att.name.startsWith('video-circle_');
      if (isSticker || isCircle) continue;
      if (t.startsWith('image/') || t.startsWith('video/')) {
        media.add(att.url);
      } else if (t.startsWith('audio/')) {
        /* веб в «медиа» для профиля не включает audio отдельно — отнесём к файлам */
        files.add(att.url);
      } else {
        files.add(att.url);
      }
    }
    final text = msg.text;
    if (text != null && text.isNotEmpty) {
      for (final m in _urlRe.allMatches(text)) {
        links.add(m.group(0)!);
      }
    }
  }
  return media.length + files.length + links.length;
}
