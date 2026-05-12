import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

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
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final outPath = '${dir.path}/video_circle_mirrored_$stamp.mp4';
    final outPathNoAudio = '${dir.path}/video_circle_mirrored_${stamp}_na.mp4';

    final inLen = await File(inPath).length();

    Future<XFile?> runMirror({
      required String out,
      required String audioMode,
    }) async {
      // `hflip` mirrors horizontally. Re-encode for compatibility.
      // Primary: AAC; fallback file tries `-an` if audio encode fails on device.
      final audioArgs = audioMode == 'aac'
          ? <String>['-c:a', 'aac', '-b:a', '128k']
          : <String>['-an'];
      final cmd = <String>[
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
        'ultrafast',
        '-crf',
        '23',
        ...audioArgs,
        '-movflags',
        '+faststart',
        _q(out),
      ].join(' ');

      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      final ok = ReturnCode.isSuccess(code);
      final log = await session.getOutput();
      if (!ok) {
        appLogger.w(
          'mirrorVideoCircleIfNeeded: ffmpeg failed (audio=$audioMode) code=$code inSize=$inLen\n$log',
        );
        try {
          final f = File(out);
          if (await f.exists()) await f.delete();
        } catch (_) {}
        return null;
      }
      final f = File(out);
      if (!await f.exists() || await f.length() < 32) {
        appLogger.w(
          'mirrorVideoCircleIfNeeded: output missing or tiny (audio=$audioMode) inSize=$inLen\n$log',
        );
        return null;
      }
      return XFile(out, mimeType: 'video/mp4');
    }

    final withAudio = await runMirror(out: outPath, audioMode: 'aac');
    if (withAudio != null) return withAudio;

    appLogger.d('mirrorVideoCircleIfNeeded: retry without audio');
    final noAudio = await runMirror(out: outPathNoAudio, audioMode: 'none');
    return noAudio ?? input;
  } catch (e, st) {
    appLogger.w('videoCircle mirror postprocess failed', error: e, stackTrace: st);
    return input;
  }
}

String _q(String path) => '"${path.replaceAll('"', '\\"')}"';
