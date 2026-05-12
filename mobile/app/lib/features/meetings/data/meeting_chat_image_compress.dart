import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:lighchat_mobile/core/app_logger.dart';

/// Максимальная длинная сторона перед загрузкой в чат встречи (как ориентир
/// по «весу» для экранов и сети; уменьшает пик памяти при `withData: true`).
const int kMeetingChatImageMaxSide = 1280;

/// Качество JPEG после даунскейла или для PNG/WebP/HEIC.
const int kMeetingChatImageJpegQuality = 82;

String? _guessMimeFromName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.gif')) return 'image/gif';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/heic';
  return null;
}

String _withJpgExtension(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'image.jpg';
  final dot = trimmed.lastIndexOf('.');
  if (dot <= 0) return '$trimmed.jpg';
  return '${trimmed.substring(0, dot)}.jpg';
}

bool _isAnimatedGif(Uint8List bytes) {
  // Почти все анимированные GIF содержат расширение Application "NETSCAPE2.0".
  const needle = <int>[0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45];
  outer:
  for (var i = 0; i <= bytes.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

/// Результат подготовки байтов к загрузке в Storage.
class MeetingChatPreparedUploadBytes {
  const MeetingChatPreparedUploadBytes({
    required this.bytes,
    required this.displayName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String displayName;
  final String mimeType;
}

/// Уменьшает растровые изображения и перекодирует в JPEG там, где это даёт
/// меньший объём или нужен даунскейл. GIF (в т.ч. анимированные) и SVG не трогаем.
///
/// При ошибке декодирования или сбое кодирования возвращает исходные [bytes].
MeetingChatPreparedUploadBytes prepareMeetingChatImageForUpload({
  required Uint8List bytes,
  required String displayName,
  String? mimeType,
}) {
  final name = displayName.isNotEmpty ? displayName : 'attachment';
  final mimeRaw = (mimeType ?? _guessMimeFromName(name) ?? '').toLowerCase();
  final mime = mimeRaw.isNotEmpty ? mimeRaw : (_guessMimeFromName(name) ?? '');

  if (mime.contains('svg')) {
    return MeetingChatPreparedUploadBytes(
      bytes: bytes,
      displayName: name,
      mimeType: mimeType ?? mime,
    );
  }
  if (mime == 'image/gif' || name.toLowerCase().endsWith('.gif')) {
    if (_isAnimatedGif(bytes)) {
      return MeetingChatPreparedUploadBytes(
        bytes: bytes,
        displayName: name,
        mimeType: mimeType ?? 'image/gif',
      );
    }
  }

  final isRaster =
      mime.startsWith('image/') &&
      !mime.contains('svg') &&
      mime != 'image/gif' &&
      !name.toLowerCase().endsWith('.gif');

  if (!isRaster) {
    final guessed = mimeType ?? _guessMimeFromName(name);
    return MeetingChatPreparedUploadBytes(
      bytes: bytes,
      displayName: name,
      mimeType: guessed ?? 'application/octet-stream',
    );
  }

  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return MeetingChatPreparedUploadBytes(
        bytes: bytes,
        displayName: name,
        mimeType: mimeType ?? mime,
      );
    }

    final largest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final didResize = largest > kMeetingChatImageMaxSide;
    img.Image work = decoded;

    if (didResize) {
      final scale = kMeetingChatImageMaxSide / largest;
      final newW = (decoded.width * scale).round().clamp(1, kMeetingChatImageMaxSide);
      final newH =
          (decoded.height * scale).round().clamp(1, kMeetingChatImageMaxSide);
      work = img.copyResize(
        decoded,
        width: newW,
        height: newH,
        interpolation: img.Interpolation.average,
      );
    }

    final alreadyJpegNoResize =
        largest <= kMeetingChatImageMaxSide &&
        (mime == 'image/jpeg' ||
            name.toLowerCase().endsWith('.jpg') ||
            name.toLowerCase().endsWith('.jpeg'));

    if (alreadyJpegNoResize) {
      return MeetingChatPreparedUploadBytes(
        bytes: bytes,
        displayName: name,
        mimeType: mimeType ?? 'image/jpeg',
      );
    }

    final jpg = Uint8List.fromList(
      img.encodeJpg(work, quality: kMeetingChatImageJpegQuality),
    );

    // Без даунскейла JPEG может быть крупнее простого PNG/WebP — тогда оставляем исходник.
    if (!didResize && jpg.length >= bytes.length) {
      return MeetingChatPreparedUploadBytes(
        bytes: bytes,
        displayName: name,
        mimeType: mimeType ?? (mime.isNotEmpty ? mime : 'image/jpeg'),
      );
    }

    return MeetingChatPreparedUploadBytes(
      bytes: jpg,
      displayName: _withJpgExtension(name),
      mimeType: 'image/jpeg',
    );
  } catch (e, st) {
    appLogger.w('prepareMeetingChatImageForUpload: fallback to original', error: e, stackTrace: st);
    return MeetingChatPreparedUploadBytes(
      bytes: bytes,
      displayName: name,
      mimeType: mimeType ?? mime,
    );
  }
}
