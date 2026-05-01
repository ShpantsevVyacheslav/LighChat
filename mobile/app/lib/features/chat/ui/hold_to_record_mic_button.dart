import 'dart:async' show Timer, unawaited;
import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_message_preview_bar.dart';
import 'voice_message_record_sheet.dart';

/// Telegram-like hold-to-record mic button.
///
/// Flow:
///   * **Long press** — starts recording; a thin indicator bar is shown at the
///     bottom of the screen in place of the composer row.
///   * **Slide left** past [_kCancelDx] while holding — arms cancel; releasing
///     discards the recording.
///   * **Slide up** while holding — pauses recording; slide down restores.
///   * **Release** (without slide‑left) — stops recording and opens an **inline
///     preview** over the composer: trash / play / waveform / duration / send
///     (see [VoiceMessagePreviewBar]). The user confirms the send or discards.
///   * **Plain tap** (when [tapToRecord] is enabled) — starts the same visual
///     flow as hold‑to‑record, with pause/stop/cancel controls.
///
/// The recording/preview bar is rendered via an `OverlayEntry`, while parent
/// composer can hide the regular input row via [onOverlayVisibilityChanged].
class HoldToRecordMicButton extends StatefulWidget {
  const HoldToRecordMicButton({
    super.key,
    required this.child,
    required this.enabled,
    required this.onTap,
    required this.onRecorded,
    this.tapToRecord = false,
    this.onOverlayVisibilityChanged,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onTap;

  /// Called when the user confirms a recording in the preview. The callback
  /// owns the file lifecycle — this widget does **not** delete [VoiceMessageRecordResult.filePath]
  /// on success.
  final Future<void> Function(VoiceMessageRecordResult result) onRecorded;
  final bool tapToRecord;
  final ValueChanged<bool>? onOverlayVisibilityChanged;

  @override
  State<HoldToRecordMicButton> createState() => _HoldToRecordMicButtonState();
}

class _HoldToRecordMicButtonState extends State<HoldToRecordMicButton> {
  final AudioRecorder _recorder = AudioRecorder();

  // Recording‑in‑progress indicator.
  OverlayEntry? _recOverlay;
  Timer? _ticker;
  DateTime? _activeRunStartedAt;
  Duration _elapsedBeforePause = Duration.zero;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _paused = false;
  bool _busy = false;
  bool _tapMode = false;
  double _dragDx = 0;
  double _dragDy = 0;
  VoiceMessageRecordResult? _continuePrefix;

  /// Точка старта long press (глобальные координаты) — для `Listener` на весь экран,
  /// пока палец ушёл с маленькой кнопки микрофона.
  Offset? _dragOriginGlobal;

  // Post‑release preview overlay.
  OverlayEntry? _previewOverlay;
  bool _previewBusy = false;
  bool _lastOverlayVisible = false;

  // Slide‑left threshold for cancel (Telegram parity).
  static const double _kCancelDx = -80;
  static const double _kPauseUpDy = -44;
  static const double _kResumeDownDy = -28;

  @override
  void dispose() {
    _ticker?.cancel();
    _recOverlay?.remove();
    _recOverlay = null;
    _previewOverlay?.remove();
    _previewOverlay = null;
    _notifyOverlayVisibility(force: true);
    unawaited(_recorder.dispose());
    super.dispose();
  }

  bool get _isOverlayVisible => _recOverlay != null || _previewOverlay != null;

  void _notifyOverlayVisibility({bool force = false}) {
    final visible = _isOverlayVisible;
    if (!force && visible == _lastOverlayVisible) return;
    _lastOverlayVisible = visible;
    widget.onOverlayVisibilityChanged?.call(visible);
  }

  bool get _cancelArmed => _dragDx <= _kCancelDx;

  /// Накопленное смещение от точки старта: с микрофона (offsetFromOrigin) или с экрана.
  void _updateRecordingDrag(double dx, double dy) {
    if (!_recording || _tapMode) return;
    _dragDx = dx;
    _dragDy = dy;
    if (_dragDy <= _kPauseUpDy && !_paused) {
      unawaited(_pause());
    } else if (_dragDy >= _kResumeDownDy && _paused) {
      unawaited(_resume());
    }
    _recOverlay?.markNeedsBuild();
  }

  Duration _currentElapsed() {
    if (_recording && !_paused && _activeRunStartedAt != null) {
      return _elapsedBeforePause +
          DateTime.now().difference(_activeRunStartedAt!);
    }
    return _elapsedBeforePause;
  }

  Future<String> _newTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
  }

  String _ffQuote(String path) => '"${path.replaceAll('"', r'\"')}"';

  Future<void> _lightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _currentElapsed());
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
        final insetsBottom = MediaQuery.viewInsetsOf(context).bottom;
        final armed = _cancelArmed;
        final pauseHintT = !_tapMode && !_paused && !armed && _dragDy < 0
            ? ((-_dragDy) / (-_kPauseUpDy)).clamp(0.0, 1.0)
            : 0.0;
        final pill = TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _recording ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: _paused
                    ? Border.all(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.85),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _PulsingRecordDot(active: !armed && !_paused),
                    if (_paused) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.pause_circle_rounded,
                        size: 30,
                        color: Color(0xFFFFB74D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Пауза',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ] else
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
                    if (_tapMode) ...[
                      _RecMiniBtn(
                        icon: _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        onTap: _paused ? _resume : _pause,
                      ),
                      const SizedBox(width: 6),
                      _RecMiniBtn(icon: Icons.stop_rounded, onTap: _finish),
                      const SizedBox(width: 6),
                      _RecMiniBtn(icon: Icons.close_rounded, onTap: _cancel),
                    ] else ...[
                      Opacity(
                        opacity: 0.32 + 0.68 * pauseHintT,
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 22,
                          color: Colors.white.withValues(
                            alpha: 0.55 + 0.4 * pauseHintT,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _RecMiniBtn(
                        icon: _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        onTap: _paused ? _resume : _pause,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Colors.white.withValues(
                          alpha: armed ? 0.95 : 0.72,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          armed
                              ? 'Отпустите — отмена'
                              : 'Влево — отмена · Вверх — пауза',
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: armed ? 0.95 : 0.72,
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: Transform.scale(
                  scale: 0.985 + (t * 0.015),
                  child: child,
                ),
              ),
            );
          },
        );
        return Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!_tapMode)
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: (e) {
                    final o = _dragOriginGlobal;
                    if (!_recording || o == null) return;
                    final delta = e.position - o;
                    _updateRecordingDrag(delta.dx, delta.dy);
                  },
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    insetsBottom + bottom + 8,
                  ),
                  child: pill,
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_recOverlay!);
    _notifyOverlayVisibility();
  }

  // ───────────────────────────── Record lifecycle ──────────────────────────

  Future<void> _start({required bool tapMode}) async {
    if (!widget.enabled || _busy || _recording) return;
    if (tapMode) _dragOriginGlobal = null;
    final baseElapsed = _continuePrefix?.duration ?? Duration.zero;
    setState(() {
      _busy = true;
      _tapMode = tapMode;
      _paused = false;
      _dragDx = 0;
      _dragDy = 0;
      _elapsedBeforePause = baseElapsed;
      _elapsed = baseElapsed;
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
      _activeRunStartedAt = DateTime.now();
      _recording = true;
      unawaited(_lightHaptic());
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
      final prefix = _continuePrefix;
      if (prefix != null) {
        await _deleteSilently(prefix.filePath);
      }
    } catch (_) {}
    unawaited(_lightHaptic());
    _stopTicker();
    _recOverlay?.remove();
    _recOverlay = null;
    _activeRunStartedAt = null;
    _elapsedBeforePause = Duration.zero;
    _elapsed = Duration.zero;
    _recording = false;
    _paused = false;
    _tapMode = false;
    _dragDx = 0;
    _dragDy = 0;
    _dragOriginGlobal = null;
    _continuePrefix = null;
    _notifyOverlayVisibility();
    if (mounted) setState(() {});
  }

  /// Stops the recorder and — if the clip is long enough — opens the preview.
  Future<void> _finish() async {
    if (!_recording || _busy) return;
    setState(() => _busy = true);
    try {
      final elapsed = _currentElapsed();
      final path = await _recorder.stop();
      unawaited(_lightHaptic());
      _stopTicker();
      _recOverlay?.remove();
      _recOverlay = null;
      _recording = false;
      _activeRunStartedAt = null;
      _elapsedBeforePause = Duration.zero;
      _elapsed = Duration.zero;
      _paused = false;
      _tapMode = false;
      _dragDx = 0;
      _dragDy = 0;
      _dragOriginGlobal = null;
      if (!mounted) return;
      setState(() {});

      // Cancel branch — user slid left before releasing.
      if (_cancelArmed) {
        if (path != null && path.trim().isNotEmpty) {
          await _deleteSilently(path);
        }
        final prefix = _continuePrefix;
        if (prefix != null) {
          await _deleteSilently(prefix.filePath);
          _continuePrefix = null;
        }
        return;
      }
      // Too short — discard silently (parity with the bottom sheet).
      if (path == null || path.trim().isEmpty || elapsed.inMilliseconds < 350) {
        if (path != null && path.trim().isNotEmpty) {
          await _deleteSilently(path);
        }
        final prefix = _continuePrefix;
        if (prefix != null) {
          _continuePrefix = null;
          _showPreviewOverlay(result: prefix);
          _notifyOverlayVisibility();
          return;
        }
        _notifyOverlayVisibility();
        return;
      }
      final result = await _resultAfterContinuation(
        currentPath: path,
        elapsed: elapsed,
      );
      _showPreviewOverlay(result: result);
      _notifyOverlayVisibility();
    } catch (_) {
      // ignore
    } finally {
      _notifyOverlayVisibility();
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
          bottom: viewInsets + bottomPad + 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: VoiceMessagePreviewBar(
              filePath: result.filePath,
              duration: result.duration,
              busy: _previewBusy,
              onCancel: () async {
                if (_previewBusy) return;
                _dismissPreview();
                await _deleteSilently(result.filePath);
              },
              onSend: (selected) async {
                if (_previewBusy) return;
                _previewBusy = true;
                _previewOverlay?.markNeedsBuild();
                try {
                  await widget.onRecorded(selected);
                } finally {
                  _previewBusy = false;
                  _dismissPreview();
                }
              },
              onContinueRecording: (selected) async {
                if (_previewBusy) return;
                _previewBusy = true;
                _previewOverlay?.markNeedsBuild();
                _dismissPreview();
                await _startContinuation(selected);
              },
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_previewOverlay!);
    _notifyOverlayVisibility();
  }

  void _dismissPreview() {
    _previewOverlay?.remove();
    _previewOverlay = null;
    _notifyOverlayVisibility();
  }

  Future<void> _deleteSilently(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<VoiceMessageRecordResult> _resultAfterContinuation({
    required String currentPath,
    required Duration elapsed,
  }) async {
    final prefix = _continuePrefix;
    _continuePrefix = null;
    if (prefix == null) {
      return VoiceMessageRecordResult(filePath: currentPath, duration: elapsed);
    }

    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/audio_join_${DateTime.now().microsecondsSinceEpoch}.m4a';
    final cmd = <String>[
      '-y',
      '-i',
      _ffQuote(prefix.filePath),
      '-i',
      _ffQuote(currentPath),
      '-filter_complex',
      '"[0:a][1:a]concat=n=2:v=0:a=1[a]"',
      '-map',
      '"[a]"',
      '-c:a',
      'aac',
      '-b:a',
      '96k',
      '-movflags',
      '+faststart',
      _ffQuote(outPath),
    ].join(' ');
    try {
      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code) && await File(outPath).exists()) {
        await _deleteSilently(prefix.filePath);
        await _deleteSilently(currentPath);
        return VoiceMessageRecordResult(filePath: outPath, duration: elapsed);
      }
    } catch (_) {}

    await _deleteSilently(prefix.filePath);
    final currentDuration = elapsed - prefix.duration;
    return VoiceMessageRecordResult(
      filePath: currentPath,
      duration: currentDuration > Duration.zero ? currentDuration : elapsed,
    );
  }

  Future<void> _startContinuation(VoiceMessageRecordResult prefix) async {
    if (_recording || _busy) return;
    _continuePrefix = prefix;
    _elapsedBeforePause = prefix.duration;
    _elapsed = prefix.duration;
    await _start(tapMode: true);
    if (!_recording) {
      final pending = _continuePrefix;
      _continuePrefix = null;
      if (pending != null) {
        _showPreviewOverlay(result: pending);
      }
    }
  }

  // ───────────────────────────── Gesture surface ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled && !_recording && _previewOverlay == null
          ? (widget.tapToRecord
                ? () => unawaited(_start(tapMode: true))
                : widget.onTap)
          : null,
      onLongPressStart: (d) {
        _dragOriginGlobal = d.globalPosition;
        unawaited(_start(tapMode: false));
      },
      onLongPressMoveUpdate: (d) {
        if (!_recording || _tapMode) return;
        _updateRecordingDrag(d.offsetFromOrigin.dx, d.offsetFromOrigin.dy);
      },
      onLongPressEnd: (_) {
        if (_tapMode) return;
        if (_cancelArmed) {
          unawaited(_cancel());
          return;
        }
        // На паузе отпускание пальца не завершает запись — показываем полный
        // ряд кнопок (стоп / отмена), как в tap-to-record.
        if (_paused) {
          if (mounted) {
            setState(() => _tapMode = true);
            _recOverlay?.markNeedsBuild();
          }
          return;
        }
        unawaited(_finish());
      },
      child: widget.child,
    );
  }

  Future<void> _pause() async {
    if (!_recording || _paused) return;
    try {
      await _recorder.pause();
      if (_activeRunStartedAt != null) {
        _elapsedBeforePause += DateTime.now().difference(_activeRunStartedAt!);
      }
      _activeRunStartedAt = null;
      _paused = true;
      _elapsed = _elapsedBeforePause;
      if (mounted) setState(() {});
      _recOverlay?.markNeedsBuild();
      unawaited(_lightHaptic());
    } catch (_) {}
  }

  Future<void> _resume() async {
    if (!_recording || !_paused) return;
    try {
      await _recorder.resume();
      _activeRunStartedAt = DateTime.now();
      _paused = false;
      if (mounted) setState(() {});
      _recOverlay?.markNeedsBuild();
      unawaited(_lightHaptic());
    } catch (_) {}
  }
}

class _RecMiniBtn extends StatelessWidget {
  const _RecMiniBtn({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(onTap()),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
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
