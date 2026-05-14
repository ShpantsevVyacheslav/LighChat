import 'package:lighchat_models/lighchat_models.dart';

import 'local_voice_transcriber.dart';

/// Описание одного голосового сообщения в чате для karaoke-навигации
/// (prev/next между сообщениями в полноэкранном режиме).
class VoiceMessageTrack {
  const VoiceMessageTrack({
    required this.conversationId,
    required this.messageId,
    required this.audioUrl,
    required this.senderName,
    required this.senderAvatarUrl,
    this.segments,
  });

  final String conversationId;
  final String messageId;
  final String audioUrl;
  final String senderName;
  final String? senderAvatarUrl;

  /// Если транскрипция уже была — передаём готовые сегменты, иначе `null`
  /// и karaoke попробует получить их сам через `LocalVoiceTranscriber`.
  final List<TranscriptSegment>? segments;
}

/// Это голосовое аудио-вложение? Используется при сборке списка треков
/// для prev/next-навигации в karaoke. Эквивалент `_isVoiceAttachment`
/// в `message_attachments.dart`.
bool isVoiceMessageAttachment(ChatAttachment a) {
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('audio/')) return true;
  final n = a.name.toLowerCase();
  if (n.startsWith('audio_')) return true;
  return false;
}
