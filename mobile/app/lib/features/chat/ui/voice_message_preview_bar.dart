import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'message_audio_waveform.dart';

/// Telegram‑style preview bar for a just‑recorded voice message.
///
/// Matches the visual spec in the product screenshots:
///   [trash]   [▶ / ⏸]   ─── waveform ───   0:02   [send]
///
/// Fully self‑contained:
///   * plays back the file at [filePath] via `just_audio`
///   * draws a progress waveform using the shared [AudioMessageWaveformBars]
///   * invokes [onCancel] when the user taps the trash icon
///   * invokes [onSend] when the user taps the send icon
///
/// The widget does **not** delete the source file on cancel / send — the
/// caller owns the lifecycle of [filePath]. This keeps the widget reusable
/// and easy to unit test.
class VoiceMessagePreviewBar extends StatefulWidget {
  const VoiceMessagePreviewBar({
    super.key,
    required this.filePath,
    required this.duration,
    required this.onCancel,
    required this.onSend,
    this.busy = false,
  });

  final String filePath;
  final Duration duration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  /// If true — "send" is displayed as a spinner and both actions are disabled.
  /// Used by the caller during async upload to prevent double‑sends.
  final bool busy;

  @override
  State<VoiceMessagePreviewBar> createState() => _VoiceMessagePreviewBarState();
}

class _VoiceMessagePreviewBarState extends State<VoiceMessagePreviewBar> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  bool _ready = false;
  bool _failed = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _effectiveDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _effectiveDuration = widget.duration;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await _player.setAudioSource(AudioSource.file(widget.filePath));
      _durSub = _player.durationStream.listen((d) {
        if (!mounted || d == null) return;
        setState(() {
          if (d > Duration.zero) _effectiveDuration = d;
          _ready = true;
        });
      });
      _posSub = _player.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing);
        if (s.processingState == ProcessingState.completed) {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_durSub?.cancel());
    unawaited(_posSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_failed || !_ready || widget.busy) return;
    try {
      if (_playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _seekFromLocal(double localX, double width) {
    if (_failed || !_ready || width <= 0) return;
    final d = _effectiveDuration;
    if (d <= Duration.zero) return;
    final f = (localX / width).clamp(0.0, 1.0);
    unawaited(
      _player.seek(Duration(milliseconds: (f * d.inMilliseconds).round())),
    );
  }

  String _fmt(Duration d) {
    final total = d.inSeconds.clamp(0, 99 * 3600);
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0F172A);
    final meta = fg.withValues(alpha: 0.62);
    final bg = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final accent = const Color(0xFF2A79FF);

    final displayDuration = _playing || _position > Duration.zero
        ? _position
        : _effectiveDuration;
    final progressPct = _effectiveDuration.inMilliseconds > 0
        ? (_position.inMilliseconds / _effectiveDuration.inMilliseconds) * 100.0
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trash (cancel) — left.
          _CircleIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Отменить',
            onTap: widget.busy ? null : widget.onCancel,
            color: fg.withValues(alpha: 0.82),
            background: Colors.transparent,
            size: 40,
            iconSize: 22,
          ),
          const SizedBox(width: 4),
          // Main pill: play + waveform + time.
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Row(
                    children: [
                      Material(
                        color: accent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: widget.busy ? null : _toggle,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              _failed
                                  ? Icons.error_outline_rounded
                                  : (_playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (d) => _seekFromLocal(
                              d.localPosition.dx,
                              cons.maxWidth,
                            ),
                            onHorizontalDragStart: (d) => _seekFromLocal(
                              d.localPosition.dx,
                              cons.maxWidth,
                            ),
                            onHorizontalDragUpdate: (d) => _seekFromLocal(
                              d.localPosition.dx,
                              cons.maxWidth,
                            ),
                            child: AudioMessageWaveformBars(
                              progressPercent: progressPct.clamp(0.0, 100.0),
                              // Slightly higher contrast for the composer
                              // preview than for incoming bubbles.
                              isMine: true,
                              seedUrl: widget.filePath,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(displayDuration),
                      style: TextStyle(
                        color: meta,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        decoration: TextDecoration.none,
                        decorationThickness: 0,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
          const SizedBox(width: 6),
          // Send — right.
          _CircleIconButton(
            icon: Icons.send_rounded,
            tooltip: 'Отправить',
            onTap: widget.busy ? null : widget.onSend,
            color: Colors.white,
            background: accent,
            size: 44,
            iconSize: 20,
            busy: widget.busy,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.background,
    required this.size,
    required this.iconSize,
    this.tooltip,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: busy
              ? Center(
                  child: SizedBox(
                    width: iconSize * 0.9,
                    height: iconSize * 0.9,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                )
              : Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
