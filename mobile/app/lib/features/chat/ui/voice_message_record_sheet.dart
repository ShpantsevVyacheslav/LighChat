import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceMessageRecordResult {
  const VoiceMessageRecordResult({
    required this.filePath,
    required this.duration,
  });

  final String filePath;
  final Duration duration;
}

Future<VoiceMessageRecordResult?> showVoiceMessageRecordSheet(
  BuildContext context,
) {
  // На desktop modal bottom sheet использует root navigator, который
  // покрывает всё окно (rail + chat list + chat). Без ограничения
  // ширины запись аудио растягивается на весь экран. Ограничиваем
  // до 560dp — соответствует ширине composer'а на типичном desktop
  // layout'е и центрируется в окне.
  final screenW = MediaQuery.sizeOf(context).width;
  const desktopBreakpoint = 1024.0;
  final isDesktop = screenW >= desktopBreakpoint;
  return showModalBottomSheet<VoiceMessageRecordResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: isDesktop
        ? const BoxConstraints(maxWidth: 560)
        : null,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
      ),
      child: const _VoiceMessageRecordSheetBody(),
    ),
  );
}

class _VoiceMessageRecordSheetBody extends StatefulWidget {
  const _VoiceMessageRecordSheetBody();

  @override
  State<_VoiceMessageRecordSheetBody> createState() =>
      _VoiceMessageRecordSheetBodyState();
}

class _VoiceMessageRecordSheetBodyState
    extends State<_VoiceMessageRecordSheetBody> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _busy = false;
  bool _recording = false;
  String? _recordPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_startRecording());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<String> _newTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
  }

  Future<void> _lightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final s = _startedAt;
      if (!mounted || s == null) return;
      setState(() => _elapsed = DateTime.now().difference(s));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _startRecording() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) {
        setState(() => _error = AppLocalizations.of(context)!.voice_no_mic_access);
        return;
      }
      final path = await _newTempPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
      _recordPath = null;
      _recording = true;
      unawaited(_lightHaptic());
      _startTicker();
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context)!.voice_start_error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    if (_busy || !_recording) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = await _recorder.stop();
      unawaited(_lightHaptic());
      _stopTicker();
      final elapsed = _startedAt == null
          ? Duration.zero
          : DateTime.now().difference(_startedAt!);
      _recording = false;
      _startedAt = null;
      _elapsed = elapsed;
      if (path == null || path.isEmpty) {
        _recordPath = null;
        _error = AppLocalizations.of(context)!.voice_file_not_received;
      } else {
        _recordPath = path;
      }
    } catch (_) {
      _error = AppLocalizations.of(context)!.voice_stop_error;
      _recording = false;
      _startedAt = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelAndClose() async {
    if (_recording) {
      try {
        final path = await _recorder.stop();
        if (path != null && path.isNotEmpty) {
          unawaited(_deleteFileSilently(path));
        }
      } catch (_) {}
    } else if (_recordPath != null && _recordPath!.isNotEmpty) {
      unawaited(_deleteFileSilently(_recordPath!));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteFileSilently(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  void _confirmSend() {
    final path = _recordPath;
    if (path == null || path.isEmpty || _elapsed.inMilliseconds <= 300) {
      return;
    }
    Navigator.of(
      context,
    ).pop(VoiceMessageRecordResult(filePath: path, duration: _elapsed));
  }

  String _durationLabel(Duration d) {
    final total = d.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.93);
    final canSend =
        !_recording &&
        !_busy &&
        _recordPath != null &&
        _recordPath!.isNotEmpty &&
        _elapsed.inMilliseconds > 300;
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.voice_title,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _recording ? Icons.mic_rounded : Icons.pause_circle_filled,
                  color: _recording
                      ? const Color(0xFFFF4D4F)
                      : Colors.white.withValues(alpha: 0.82),
                ),
                const SizedBox(width: 8),
                Text(
                  _recording ? AppLocalizations.of(context)!.voice_recording : AppLocalizations.of(context)!.voice_ready,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _durationLabel(_elapsed),
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.redAccent.shade100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : (_recording ? _stopRecording : _startRecording),
              icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(_recording ? AppLocalizations.of(context)!.voice_stop_button : AppLocalizations.of(context)!.voice_record_again),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _cancelAndClose,
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSend ? _confirmSend : null,
                    icon: const Icon(Icons.near_me_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)!.common_send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
