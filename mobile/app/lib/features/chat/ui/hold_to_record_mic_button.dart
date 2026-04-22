import 'dart:async' show Timer, unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_message_preview_bar.dart';
import 'voice_message_record_sheet.dart';

/// Telegram-like hold-to-record mic button.
///
/// Flow:
///   * **Long press** — starts recording; a thin indicator bar is shown at the
///     bottom of the screen with elapsed time and the hint "← Влево — отмена".
///   * **Slide left** past [_kCancelDx] while holding — arms cancel; releasing
///     discards the recording.
///   * **Release** (without slide‑left) — stops recording and opens an **inline
///     preview** over the composer: trash / play / waveform / duration / send
///     (see [VoiceMessagePreviewBar]). The user confirms the send or discards.
///   * **Plain tap** — delegated to [onTap] (opens the classic modal sheet),
///     preserving the existing tap‑to‑record flow.
///
/// The preview is rendered via an `OverlayEntry` so no changes are needed in
/// the composer / chat screen widget tree.
class HoldToRecordMicButton extends StatefulWidget {
  const HoldToRecordMicButton({
    super.key,
    required this.child,
    required this.enabled,
    required this.onTap,
    required this.onRecorded,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onTap;

  /// Called when the user confirms a recording in the preview. The callback
  /// owns the file lifecycle — this widget does **not** delete [VoiceMessageRecordResult.filePath]
  /// on success.
  final Future<void> Function(VoiceMessageRecordResult result) onRecorded;

  @override
  State<HoldToRecordMicButton> createState() => _HoldToRecordMicButtonState();
}

class _HoldToRecordMicButtonState extends State<HoldToRecordMicButton> {
  final AudioRecorder _recorder = AudioRecorder();

  // Recording‑in‑progress indicator.
  OverlayEntry? _recOverlay;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _busy = false;
  double _dragDx = 0;

  // Post‑release preview overlay.
  OverlayEntry? _previewOverlay;
  bool _previewBusy = false;

  // Slide‑left threshold for cancel (Telegram parity).
  static const double _kCancelDx = -80;

  @override
  void dispose() {
    _ticker?.cancel();
    _recOverlay?.remove();
    _previewOverlay?.remove();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  bool get _cancelArmed => _dragDx <= _kCancelDx;

  Future<String> _newTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final s = _startedAt;
      if (!mounted || s == null) return;
      setState(() => _elapsed = DateTime.now().difference(s));
      _recOverlay?.markNeedsBuild();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _fmt(Duration d) {
    final sec = d.inSeconds.clamp(0, 99 * 3600);
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ───────────────────────────── Recording overlay ─────────────────────────

  void _showRecordingOverlay() {
    _recOverlay?.remove();
    _recOverlay = OverlayEntry(
      builder: (context) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        final armed = _cancelArmed;
        return Positioned(
          left: 12,
          right: 12,
          // Sit just above the composer (≈ composer height + safe area).
          bottom: bottom + 62,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _recording ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: Material(
                color: Colors.black.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Pulsing red dot + timer (screenshot‑1 parity).
                      _PulsingRecordDot(active: !armed),
                      const SizedBox(width: 10),
                      Text(
                        _fmt(_elapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Colors.white.withValues(
                          alpha: armed ? 0.95 : 0.72,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        armed ? 'Отпустите — отмена' : 'Влево — отмена',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: armed ? 0.95 : 0.72,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_recOverlay!);
  }

  // ───────────────────────────── Record lifecycle ──────────────────────────

  Future<void> _start() async {
    if (!widget.enabled || _busy || _recording) return;
    setState(() {
      _busy = true;
      _dragDx = 0;
      _elapsed = Duration.zero;
    });
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) return;
      final path = await _newTempPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
      if (!mounted) return;
      _startedAt = DateTime.now();
      _recording = true;
      _showRecordingOverlay();
      _startTicker();
      setState(() {});
    } catch (_) {
      // ignore — user falls back to tap flow
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (!_recording) return;
    try {
      final p = await _recorder.stop();
      if (p != null && p.trim().isNotEmpty) {
        await _deleteSilently(p);
      }
    } catch (_) {}
    _stopTicker();
    _recOverlay?.remove();
    _recOverlay = null;
    _startedAt = null;
    _recording = false;
    _dragDx = 0;
    if (mounted) setState(() {});
  }

  /// Stops the recorder and — if the clip is long enough — opens the preview.
  Future<void> _finish() async {
    if (!_recording || _busy) return;
    setState(() => _busy = true);
    try {
      final started = _startedAt;
      final elapsed = started == null
          ? Duration.zero
          : DateTime.now().difference(started);
      final path = await _recorder.stop();
      _stopTicker();
      _recOverlay?.remove();
      _recOverlay = null;
      _recording = false;
      _startedAt = null;
      _dragDx = 0;
      if (!mounted) return;
      setState(() {});

      // Cancel branch — user slid left before releasing.
      if (_cancelArmed) {
        if (path != null && path.trim().isNotEmpty) {
          await _deleteSilently(path);
        }
        return;
      }
      // Too short — discard silently (parity with the bottom sheet).
      if (path == null ||
          path.trim().isEmpty ||
          elapsed.inMilliseconds < 350) {
        if (path != null && path.trim().isNotEmpty) {
          await _deleteSilently(path);
        }
        return;
      }
      _showPreviewOverlay(
        result: VoiceMessageRecordResult(filePath: path, duration: elapsed),
      );
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ───────────────────────────── Preview overlay ───────────────────────────

  void _showPreviewOverlay({required VoiceMessageRecordResult result}) {
    _previewOverlay?.remove();
    _previewBusy = false;
    _previewOverlay = OverlayEntry(
      builder: (ctx) {
        final bottomPad = MediaQuery.paddingOf(ctx).bottom;
        final viewInsets = MediaQuery.viewInsetsOf(ctx).bottom;
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: viewInsets > 0 ? 0 : bottomPad > 0 ? 0 : 4,
                ),
                child: VoiceMessagePreviewBar(
                  filePath: result.filePath,
                  duration: result.duration,
                  busy: _previewBusy,
                  onCancel: () async {
                    if (_previewBusy) return;
                    _dismissPreview();
                    await _deleteSilently(result.filePath);
                  },
                  onSend: () async {
                    if (_previewBusy) return;
                    _previewBusy = true;
                    _previewOverlay?.markNeedsBuild();
                    try {
                      await widget.onRecorded(result);
                    } finally {
                      _previewBusy = false;
                      _dismissPreview();
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_previewOverlay!);
  }

  void _dismissPreview() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  Future<void> _deleteSilently(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ───────────────────────────── Gesture surface ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled && !_recording && _previewOverlay == null
          ? widget.onTap
          : null,
      onLongPressStart: (_) => unawaited(_start()),
      onLongPressMoveUpdate: (d) {
        if (!_recording) return;
        _dragDx = d.offsetFromOrigin.dx;
        _recOverlay?.markNeedsBuild();
      },
      onLongPressEnd: (_) {
        if (_cancelArmed) {
          unawaited(_cancel());
        } else {
          unawaited(_finish());
        }
      },
      child: widget.child,
    );
  }
}

/// Pulsing red dot shown inside the recording indicator pill.
class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot({required this.active});

  final bool active;

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final v = Curves.easeInOut.transform(_ctrl.value);
        final alpha = 0.55 + 0.45 * v;
        final color = widget.active
            ? const Color(0xFFFF4D4F)
            : Colors.white.withValues(alpha: 0.6);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
        );
      },
    );
  }
}
