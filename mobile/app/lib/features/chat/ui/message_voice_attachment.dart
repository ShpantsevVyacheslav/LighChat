import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'message_audio_waveform.dart';
import 'chat_vlc_network_media.dart';

/// Один активный голосовой плеер (паритет с вебом: остальные ставятся на паузу).
final class _VoicePlaybackExclusive {
  _VoicePlaybackExclusive._();

  static State<StatefulWidget>? _owner;
  static Future<void> Function()? _pause;

  static Future<void> beforeStartOther(
    State<StatefulWidget> owner,
    Future<void> Function() pause,
  ) async {
    if (_owner != null && !identical(_owner, owner) && _pause != null) {
      await _pause!();
    }
    _owner = owner;
    _pause = pause;
  }

  static void clear(State<StatefulWidget> owner) {
    if (identical(_owner, owner)) {
      _owner = null;
      _pause = null;
    }
  }
}

/// Голосовое / аудио вложение (паритет с вебом `AudioMessagePlayer`).
/// Для неподдерживаемых на iOS форматов показываем статус server-side нормализации.
class MessageVoiceAttachment extends StatelessWidget {
  const MessageVoiceAttachment({
    super.key,
    required this.attachment,
    required this.attachmentIndex,
    required this.alignRight,
    this.mediaNorm,
    this.onRetryNorm,
  });

  final ChatAttachment attachment;
  final int attachmentIndex;
  final bool alignRight;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryNorm;

  @override
  Widget build(BuildContext context) {
    final normState = chatMediaNormUiStateForAttachment(
      attachment: attachment,
      attachmentIndex: attachmentIndex,
      mediaNorm: mediaNorm,
    );
    if (normState != ChatMediaNormUiState.none) {
      return ChatMediaNormStatusWidget(
        state: normState,
        mediaKindLabel: 'аудио',
        onRetry: onRetryNorm,
      );
    }
    return _VoiceJustAudioBar(
      key: ValueKey<String>('ja-voice-${attachment.url}'),
      attachment: attachment,
      alignRight: alignRight,
    );
  }
}

class _WebStyleVoiceRow extends StatelessWidget {
  const _WebStyleVoiceRow({
    required this.isMine,
    required this.failed,
    required this.ready,
    required this.playing,
    required this.progressPercent,
    required this.seedUrl,
    required this.displayTime,
    required this.sizeBytes,
    required this.playbackRate,
    required this.onToggle,
    required this.onCycleRate,
    this.onWaveformSeekFromLocal,
  });

  final bool isMine;
  final bool failed;
  final bool ready;
  final bool playing;
  final double progressPercent;
  final String seedUrl;
  final Duration displayTime;
  final int? sizeBytes;
  final double playbackRate;
  final VoidCallback onToggle;
  final VoidCallback onCycleRate;
  /// `localX` — по ширине волны; `width` — maxWidth из [LayoutBuilder].
  final void Function(double localX, double width)? onWaveformSeekFromLocal;

  String _format(Duration d) {
    if (d.inMilliseconds <= 0) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _rateButtonLabel(double r) {
    final t = r.truncateToDouble();
    if ((r - t).abs() < 0.001) return '${t.toInt()}x';
    return '${r}x';
  }

  String _sizeLabel() {
    final b = sizeBytes;
    if (b == null || b <= 0) return '—';
    final kb = b / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metaColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.7)
        : scheme.onSurface.withValues(alpha: 0.55);
    final borderColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.18)
        : scheme.onSurface.withValues(alpha: 0.16);
    final fillColor = isMine
        ? scheme.primary.withValues(alpha: 0.16)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.30);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: failed || !ready ? null : onToggle,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      failed
                          ? Icons.error_outline_rounded
                          : (playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      color: scheme.onPrimary,
                      size: failed ? 22 : 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!failed)
                        LayoutBuilder(
                          builder: (context, cons) {
                            final seek = onWaveformSeekFromLocal;
                            final wave = AudioMessageWaveformBars(
                              progressPercent: progressPercent.clamp(0.0, 100.0),
                              isMine: isMine,
                              seedUrl: seedUrl,
                            );
                            if (seek == null) return wave;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              onHorizontalDragStart: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              onHorizontalDragUpdate: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              child: wave,
                            );
                          },
                        )
                      else
                        Text(
                          'Не удалось загрузить',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: metaColor,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        failed
                            ? 'Голосовое сообщение'
                            : '${_format(displayTime)} · ${_sizeLabel()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: metaColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: failed || !ready ? null : onCycleRate,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _rateButtonLabel(playbackRate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMine
                        ? scheme.onPrimary.withValues(alpha: 0.85)
                        : scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceJustAudioBar extends StatefulWidget {
  const _VoiceJustAudioBar({
    super.key,
    required this.attachment,
    required this.alignRight,
  });

  final ChatAttachment attachment;
  final bool alignRight;

  @override
  State<_VoiceJustAudioBar> createState() => _VoiceJustAudioBarState();
}

class _VoiceJustAudioBarState extends State<_VoiceJustAudioBar> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<Duration>? _posSub;
  bool _ready = false;
  bool _failed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  int _rateIndex = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_load());
  }

  Future<void> _load() async {
    final uri = Uri.tryParse(widget.attachment.url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    try {
      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.setSpeed(kAudioMessagePlaybackRates[_rateIndex]);
      _durSub = _player.durationStream.listen((d) {
        if (!mounted || d == null) return;
        setState(() {
          _duration = d;
          _ready = true;
        });
      });
      _posSub = _player.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted) return;
        if (s.processingState == ProcessingState.completed) {
          _VoicePlaybackExclusive.clear(this);
          setState(() {
            _playing = false;
            _position = _duration;
          });
          unawaited(_player.seek(Duration.zero));
          return;
        }
        setState(() => _playing = s.playing);
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    if (_failed || !_ready) return;
    try {
      if (_playing) {
        await _player.pause();
        _VoicePlaybackExclusive.clear(this);
      } else {
        await _VoicePlaybackExclusive.beforeStartOther(
          this,
          () => _player.pause(),
        );
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _seekFromWaveformLocal(double localX, double width) {
    if (_failed || !_ready || width <= 0) return;
    final d = _duration;
    if (d <= Duration.zero) return;
    final f = (localX / width).clamp(0.0, 1.0);
    final ms = (f * d.inMilliseconds).round();
    unawaited(_player.seek(Duration(milliseconds: ms)));
  }

  void _cycleRate() {
    if (_failed || !_ready) return;
    setState(() {
      _rateIndex = (_rateIndex + 1) % kAudioMessagePlaybackRates.length;
    });
    unawaited(_player.setSpeed(kAudioMessagePlaybackRates[_rateIndex]));
  }

  @override
  void dispose() {
    _VoicePlaybackExclusive.clear(this);
    unawaited(_durSub?.cancel());
    unawaited(_posSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.alignRight;
    final progressPct = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds) * 100.0
        : 0.0;
    final displayTime = _playing ? _position : _duration;

    return _WebStyleVoiceRow(
      isMine: mine,
      failed: _failed,
      ready: _ready,
      playing: _playing,
      progressPercent: progressPct,
      seedUrl: widget.attachment.url,
      displayTime: displayTime,
      sizeBytes: widget.attachment.size,
      playbackRate: kAudioMessagePlaybackRates[_rateIndex],
      onToggle: () {
        unawaited(_toggle());
      },
      onCycleRate: _cycleRate,
      onWaveformSeekFromLocal: _seekFromWaveformLocal,
    );
  }
}
