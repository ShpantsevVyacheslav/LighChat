import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Post-processing for recorded "video circles".
///
/// We mirror the final file for front camera recordings to match the on-screen
/// preview (selfie-style). If processing fails, returns the original file.
Future<XFile> mirrorVideoCircleIfNeeded({
  required XFile input,
  required bool mirror,
}) async {
  if (!mirror) return input;

  final inPath = input.path.trim();
  if (inPath.isEmpty) return input;
  final exists = await File(inPath).exists();
  if (!exists) return input;

  try {
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/video_circle_mirrored_${DateTime.now().microsecondsSinceEpoch}.mp4';

    // `hflip` mirrors horizontally. We re-encode video for compatibility.
    // Audio is kept if present; if it fails on some devices, we fall back.
    final cmd = [
      '-y',
      '-i',
      _q(inPath),
      '-vf',
      _q('hflip'),
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-preset',
      'veryfast',
      '-crf',
      '23',
      '-c:a',
      'aac',
      '-b:a',
      '128k',
      '-movflags',
      '+faststart',
      _q(outPath),
    ].join(' ');

    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      return input;
    }
    if (!await File(outPath).exists()) return input;

    return XFile(outPath, mimeType: 'video/mp4');
  } catch (e) {
    debugPrint('videoCircle mirror postprocess failed: $e');
    return input;
  }
}

String _q(String path) => '"${path.replaceAll('"', '\\"')}"';

