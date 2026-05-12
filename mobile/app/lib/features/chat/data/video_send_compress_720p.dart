import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

class VideoSendCompress720pResult {
  const VideoSendCompress720pResult({
    required this.file,
    required this.didCompress,
  });

  final XFile file;
  final bool didCompress;
}

/// Сжимает видео до "720p" (без апскейла) только если исходник больше 720p.
///
/// Правило:
/// - если \(w \le 1280\) И \(h \le 720\) → возвращаем исходный файл
/// - иначе → транскодируем в H.264/AAC MP4 с max 1280x720, сохраняя пропорции.
Future<VideoSendCompress720pResult> maybeCompressVideoForSend720p(XFile input) async {
  final inPath = input.path.trim();
  if (inPath.isEmpty) return VideoSendCompress720pResult(file: input, didCompress: false);

  final io = File(inPath);
  if (!await io.exists()) {
    return VideoSendCompress720pResult(file: input, didCompress: false);
  }

  VideoPlayerController? c;
  try {
    c = VideoPlayerController.file(io);
    await c.initialize();
    final size = c.value.size;
    final w = size.width.round();
    final h = size.height.round();
    if (w <= 0 || h <= 0) {
      return VideoSendCompress720pResult(file: input, didCompress: false);
    }

    // Уже <=720p — не трогаем.
    if (w <= 1280 && h <= 720) {
      return VideoSendCompress720pResult(file: input, didCompress: false);
    }
  } catch (e) {
    appLogger.w('maybeCompressVideoForSend720p: probe failed', error: e);
    return VideoSendCompress720pResult(file: input, didCompress: false);
  } finally {
    try {
      await c?.dispose();
    } catch (_) {}
  }

  try {
    final outDir = Directory('${Directory.systemTemp.path}/lighchat_video_send');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final outPath =
        '${outDir.path}/vid_720p_${DateTime.now().microsecondsSinceEpoch}.mp4';

    // Без апскейла: min(1280, iw), min(720, ih), aspect ratio сохраняем.
    // setsar=1 — чтобы избежать странных пиксельных аспектов.
    final cmd = [
      '-y',
      '-i',
      '"$inPath"',
      '-vf',
      '"scale=w=min(1280,iw):h=min(720,ih):force_original_aspect_ratio=decrease,setsar=1"',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '28',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-b:a',
      '96k',
      '-ac',
      '2',
      '-movflags',
      '+faststart',
      '"$outPath"',
    ].join(' ');

    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      appLogger.w('maybeCompressVideoForSend720p: ffmpeg failed code=$code');
      return VideoSendCompress720pResult(file: input, didCompress: false);
    }
    if (!await File(outPath).exists()) {
      return VideoSendCompress720pResult(file: input, didCompress: false);
    }

    return VideoSendCompress720pResult(
      file: XFile(outPath, mimeType: 'video/mp4'),
      didCompress: true,
    );
  } catch (e) {
    appLogger.w('maybeCompressVideoForSend720p: compress failed', error: e);
    return VideoSendCompress720pResult(file: input, didCompress: false);
  }
}

