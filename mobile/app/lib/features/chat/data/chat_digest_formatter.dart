import 'package:lighchat_models/lighchat_models.dart';

/// Форматирует список сообщений в компактный plain-text вид для подачи
/// в `AppleIntelligence.summarizeMessages`. Каждое сообщение — отдельная
/// строка `Sender: text`, нетекстовые типы сворачиваются в маркеры
/// (`[Image]`, `[Voice]`, `[Location]`, …) — так модель видит ход беседы
/// и может корректно описать содержание.
///
/// Параметры:
///  - [messages] — сообщения в хронологическом порядке (ascending).
///  - [nameFor] — резолвер имени по `senderId` (нужен, чтобы модель
///    видела участников по именам, а не сырым uid). Должен вернуть
///    короткую человекочитаемую подпись, например `"Слава"` для
///    другого участника и `"You"` для собственных сообщений.
///  - [limit] — максимум сообщений в результате (по умолчанию 20).
///    Если на входе больше — берётся последние [limit] (хвост диалога).
///  - [maxCharsPerMessage] — обрезает индивидуальное сообщение,
///    чтобы один длинный пост не съел контекст модели целиком.
String formatMessagesForDigest({
  required List<ChatMessage> messages,
  required String Function(String senderId) nameFor,
  int limit = 20,
  int maxCharsPerMessage = 280,
}) {
  if (messages.isEmpty) return '';
  final tail = messages.length > limit
      ? messages.sublist(messages.length - limit)
      : messages;
  final buf = StringBuffer();
  for (final m in tail) {
    if (m.isDeleted) continue;
    if (m.systemEvent != null) continue;
    final body = _messageBody(m, maxCharsPerMessage);
    if (body.isEmpty) continue;
    final name = nameFor(m.senderId).trim();
    buf
      ..write(name.isEmpty ? '?' : name)
      ..write(': ')
      ..write(body)
      ..writeln();
  }
  return buf.toString().trim();
}

String _messageBody(ChatMessage m, int maxChars) {
  // E2EE-сообщения, которые ещё не расшифрованы, дают пустой text —
  // их пропускаем (digest работает только с уже видимым контентом).
  final raw = (m.text ?? '').trim();
  if (raw.isNotEmpty) {
    final stripped = _stripHtmlLightly(raw);
    return _clip(stripped, maxChars);
  }
  // Чисто медийные сообщения — отдаём маркеры, чтобы модель понимала
  // что в этой точке диалога был не текст, а файл/звонок/локация.
  if (m.attachments.isNotEmpty) {
    return _attachmentMarker(m.attachments);
  }
  if (m.locationShare != null) return '[Location]';
  if (m.chatPollId != null) return '[Poll]';
  if (m.voiceTranscript != null && m.voiceTranscript!.isNotEmpty) {
    return '[Voice] ${_clip(m.voiceTranscript!, maxChars)}';
  }
  return '';
}

String _attachmentMarker(List<ChatAttachment> atts) {
  final first = atts.first;
  final type = (first.type ?? '').toLowerCase();
  // Порядок важен: `image/gif` совпадает и с image, и с gif — gif
  // проверяется первым, чтобы получить более точный маркер. Stickers
  // часто mimetype = `image/webp`, поэтому проверяем по слову sticker
  // перед image.
  if (type.contains('gif')) return '[GIF]';
  if (type.contains('sticker')) return '[Sticker]';
  if (type.contains('image')) return '[Image]';
  if (type.contains('video')) return '[Video]';
  if (type.contains('audio') || type.contains('voice')) return '[Voice]';
  return '[File]';
}

/// Минимальная санитизация: убираем простые HTML-теги (наши сообщения
/// хранятся в html через `lighchat_ui::messageHtmlToPlainText`, но здесь
/// мы избегаем зависимости от UI-пакета — для AI-промпта достаточно
/// удалить `<tag>` и расшифровать пару базовых сущностей).
String _stripHtmlLightly(String raw) {
  var t = raw.replaceAll(RegExp(r'<[^>]+>'), ' ');
  t = t
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _clip(String s, int max) =>
    s.length <= max ? s : '${s.substring(0, max - 1)}…';
