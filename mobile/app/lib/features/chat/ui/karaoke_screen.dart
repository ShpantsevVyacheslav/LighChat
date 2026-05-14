import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_voice_transcriber.dart';
import '../data/voice_message_track.dart';
import 'chat_avatar.dart';

/// Полноэкранный «караоке» режим воспроизведения голосового сообщения.
/// Дизайн в духе Apple Music Lyrics с фишками от себя: word-by-word
/// fade-in активной строки, animated cosmic-background, gradient
/// play-button + микро-эквалайзер у аватара.
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({
    super.key,
    required this.tracks,
    required this.initialIndex,
  });

  /// Список голосовых сообщений в чате, между которыми пользователь
  /// сможет переключаться через prev/next в karaoke-режиме.
  final List<VoiceMessageTrack> tracks;

  /// Индекс трека, с которого начинать.
  final int initialIndex;

  static Future<void> push(
    BuildContext context, {
    required List<VoiceMessageTrack> tracks,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (ctx, anim, secAnim) => KaraokeScreen(
          tracks: tracks,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _bgController;
  late final AnimationController _eqController;

  /// Текущий индекс трека в `widget.tracks`.
  late int _index;
  List<List<TranscriptSegment>> _lines = const [];

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _ready = false;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  VoiceMessageTrack get _track => widget.tracks[_index];
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < widget.tracks.length - 1;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.tracks.length - 1);
    _player = AudioPlayer();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_loadTrack(playAfterLoad: true));
  }

  /// Загружает текущий `_track` в плеер. Если у трека ещё нет сегментов —
  /// пробует достать из кэша / запросить транскрипцию.
  Future<void> _loadTrack({required bool playAfterLoad}) async {
    final track = _track;
    _lines = _groupIntoLines(track.segments ?? const []);
    if ((track.segments == null || track.segments!.isEmpty) &&
        track.messageId.isNotEmpty) {
      // Попробуем тихо догрузить транскрипцию.
      final cached = LocalVoiceTranscriber.instance.cachedFor(track.messageId);
      if (cached != null && cached.segments.isNotEmpty) {
        _lines = _groupIntoLines(cached.segments);
      }
    }
    if (mounted) setState(() {});
    await _setup(playAfterLoad: playAfterLoad);
  }

  Future<void> _setup({required bool playAfterLoad}) async {
    final uri = Uri.tryParse(_track.audioUrl);
    if (uri == null) return;
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(uri));
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
          setState(() {
            _playing = false;
            _position = _duration;
          });
          unawaited(_player.seek(Duration.zero));
          return;
        }
        setState(() => _playing = s.playing);
      });
      // Сбрасываем visual-стейт перед новым треком.
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _duration = Duration.zero;
          _ready = false;
        });
      }
      if (playAfterLoad) {
        await _player.play();
      }
    } catch (_) {/* fail silently */}
  }

  Future<void> _goPrev() async {
    if (!_hasPrev) return;
    setState(() => _index -= 1);
    await _loadTrack(playAfterLoad: true);
  }

  Future<void> _goNext() async {
    if (!_hasNext) return;
    setState(() => _index += 1);
    await _loadTrack(playAfterLoad: true);
  }

  @override
  void dispose() {
    unawaited(_posSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    _bgController.dispose();
    _eqController.dispose();
    super.dispose();
  }

  /// Группируем сегменты по 4-8 слов, закрывая строку на пунктуации.
  static List<List<TranscriptSegment>> _groupIntoLines(
    List<TranscriptSegment> segs, {
    int softMax = 6,
    int hardMax = 9,
  }) {
    final lines = <List<TranscriptSegment>>[];
    var current = <TranscriptSegment>[];
    for (final s in segs) {
      current.add(s);
      final last = s.text.trim();
      final endsStrong = last.endsWith('.') ||
          last.endsWith('?') ||
          last.endsWith('!') ||
          last.endsWith('…');
      final endsSoft = last.endsWith(',') || last.endsWith(';');
      if ((current.length >= softMax && (endsStrong || endsSoft)) ||
          current.length >= hardMax) {
        lines.add(current);
        current = <TranscriptSegment>[];
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  int _activeLineIndex(Duration pos) {
    if (_lines.isEmpty) return -1;
    for (var i = 0; i < _lines.length; i++) {
      final start = _lines[i].first.start;
      final end = _lines[i].last.end;
      if (pos >= start && pos < end) return i;
      if (pos < start) return (i - 1).clamp(0, _lines.length - 1);
    }
    return _lines.length - 1;
  }

  Duration _lineStart(int index) => _lines[index].first.start;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _skip(Duration delta) async {
    final target = _position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    await _player.seek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeIdx = _activeLineIndex(_position);
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: Stack(
        children: [
          // Анимированный космический фон — медленно движущиеся «орбы».
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) => CustomPaint(
                painter: _CosmicBackgroundPainter(t: _bgController.value),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _TopBar(
                    title: l10n.voice_karaoke_title,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: _LyricsView(
                      lines: _lines,
                      activeIndex: activeIdx,
                      currentPosition: _position,
                      onSeekToLine: (i) =>
                          unawaited(_player.seek(_lineStart(i))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SenderCard(
                    name: _track.senderName,
                    avatarUrl: _track.senderAvatarUrl,
                    subtitle: l10n.voice_attachment_title_voice_message,
                    eqController: _eqController,
                    playing: _playing,
                  ),
                  const SizedBox(height: 18),
                  _ProgressBar(
                    progress: progress,
                    onSeekRatio: _ready
                        ? (r) => unawaited(_player.seek(
                              Duration(
                                milliseconds:
                                    (r * _duration.inMilliseconds).round(),
                              ),
                            ))
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position), style: _timeStyle),
                      Text(_fmt(_duration), style: _timeStyle),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Controls(
                    playing: _playing,
                    ready: _ready,
                    hasPrev: _hasPrev,
                    hasNext: _hasNext,
                    onPrev: () => unawaited(_goPrev()),
                    onNext: () => unawaited(_goNext()),
                    onSkipBack: () =>
                        unawaited(_skip(const Duration(seconds: -10))),
                    onSkipForward: () =>
                        unawaited(_skip(const Duration(seconds: 10))),
                    onTogglePlay: () => unawaited(_togglePlay()),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- Cosmic animated background ----------------------

class _CosmicBackgroundPainter extends CustomPainter {
  _CosmicBackgroundPainter({required this.t});
  final double t; // 0..1

  // Размытые «орбы» — три цветных пятна, плавающие по орбитам.
  static const _orbs = <_Orb>[
    _Orb(color: Color(0xFF7C5CFF), baseRadius: 0.42, speed: 0.7, phase: 0.0),
    _Orb(color: Color(0xFF3A86FF), baseRadius: 0.36, speed: 0.5, phase: 0.33),
    _Orb(color: Color(0xFFFF5C7A), baseRadius: 0.32, speed: 0.85, phase: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Базовая заливка — тёмная.
    final base = Paint()..color = const Color(0xFF0B0B12);
    canvas.drawRect(Offset.zero & size, base);

    for (final orb in _orbs) {
      final angle = (t * orb.speed + orb.phase) * 2 * math.pi;
      final cx = size.width * (0.5 + 0.32 * math.cos(angle));
      final cy = size.height * (0.45 + 0.28 * math.sin(angle));
      final r = size.shortestSide * orb.baseRadius;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.55),
            orb.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Сверху лёгкий vignette — текст в центре читается контрастнее.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0B0B12).withValues(alpha: 0.5),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter old) => old.t != t;
}

class _Orb {
  const _Orb({
    required this.color,
    required this.baseRadius,
    required this.speed,
    required this.phase,
  });
  final Color color;
  final double baseRadius;
  final double speed;
  final double phase;
}

// ---------------------- Top bar ----------------------

const TextStyle _timeStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFFA0A4AD),
  letterSpacing: 0.3,
);

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: Colors.white.withValues(alpha: 0.7),
              iconSize: 28,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- Lyrics ----------------------

class _LyricsView extends StatelessWidget {
  const _LyricsView({
    required this.lines,
    required this.activeIndex,
    required this.currentPosition,
    required this.onSeekToLine,
  });

  final List<List<TranscriptSegment>> lines;
  final int activeIndex;
  final Duration currentPosition;
  final void Function(int) onSeekToLine;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    final clampedActive = activeIndex.clamp(0, lines.length - 1);
    final prev = clampedActive > 0 ? clampedActive - 1 : null;
    final next =
        clampedActive < lines.length - 1 ? clampedActive + 1 : null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prev != null) ...[
            _LyricLine.staticLine(
              segments: lines[prev],
              opacity: 0.32,
              fontSize: 22,
              onTap: () => onSeekToLine(prev),
            ),
            const SizedBox(height: 22),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.10),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _LyricLine.activeLine(
              key: ValueKey<int>(clampedActive),
              segments: lines[clampedActive],
              fontSize: 30,
              position: currentPosition,
              onTap: () => onSeekToLine(clampedActive),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 22),
            _LyricLine.staticLine(
              segments: lines[next],
              opacity: 0.32,
              fontSize: 22,
              onTap: () => onSeekToLine(next),
            ),
          ],
        ],
      ),
    );
  }
}

class _LyricLine extends StatelessWidget {
  const _LyricLine._({
    super.key,
    required this.segments,
    required this.opacity,
    required this.fontSize,
    required this.onTap,
    required this.position,
    required this.isActive,
  });

  factory _LyricLine.staticLine({
    required List<TranscriptSegment> segments,
    required double opacity,
    required double fontSize,
    required VoidCallback onTap,
  }) =>
      _LyricLine._(
        segments: segments,
        opacity: opacity,
        fontSize: fontSize,
        onTap: onTap,
        position: Duration.zero,
        isActive: false,
      );

  factory _LyricLine.activeLine({
    Key? key,
    required List<TranscriptSegment> segments,
    required double fontSize,
    required Duration position,
    required VoidCallback onTap,
  }) =>
      _LyricLine._(
        key: key,
        segments: segments,
        opacity: 1.0,
        fontSize: fontSize,
        onTap: onTap,
        position: position,
        isActive: true,
      );

  final List<TranscriptSegment> segments;
  final double opacity;
  final double fontSize;
  final VoidCallback onTap;
  final Duration position;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: isActive
            ? _ActiveLineText(
                segments: segments,
                position: position,
                fontSize: fontSize,
              )
            : Text(
                segments.map((s) => s.text.trim()).join(' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.4,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
      ),
    );
  }
}

/// Word-by-word fade-in: каждое слово в активной строке проявляется по
/// мере того, как плеер до него «дошёл». Прошедшие слова — полным белым,
/// будущие — приглушённым.
class _ActiveLineText extends StatelessWidget {
  const _ActiveLineText({
    required this.segments,
    required this.position,
    required this.fontSize,
  });

  final List<TranscriptSegment> segments;
  final Duration position;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            TextSpan(
              text: segments[i].text.trim(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.4,
                color: _colorFor(segments[i]),
              ),
            ),
            if (i < segments.length - 1)
              TextSpan(
                text: ' ',
                style: TextStyle(fontSize: fontSize, height: 1.2),
              ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(TranscriptSegment seg) {
    // Прошедшее слово — полным белым, текущее (если плеер сейчас «на нём») —
    // полным белым тоже, будущее — приглушённым.
    if (position >= seg.start) return Colors.white;
    final delta = (seg.start - position).inMilliseconds;
    if (delta < 200) return Colors.white;
    return Colors.white.withValues(alpha: 0.32);
  }
}

// ---------------------- Sender card with mini equalizer ----------------------

class _SenderCard extends StatelessWidget {
  const _SenderCard({
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
    required this.eqController,
    required this.playing,
  });

  final String name;
  final String? avatarUrl;
  final String subtitle;
  final AnimationController eqController;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              ChatAvatar(title: name, radius: 24, avatarUrl: avatarUrl),
              if (playing)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B0B12),
                      shape: BoxShape.circle,
                    ),
                    child: _EqualizerBars(controller: eqController),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(3, (i) {
              final phase = i * 0.33;
              final v = (math.sin((t + phase) * 2 * math.pi) + 1) / 2;
              final height = 4.0 + 10.0 * v;
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE5DBFF), Color(0xFF8C7AFF)],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ---------------------- Progress + controls ----------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.onSeekRatio});
  final double progress;
  final void Function(double ratio)? onSeekRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        void seek(double dx) {
          final r = (dx / cons.maxWidth).clamp(0.0, 1.0);
          onSeekRatio?.call(r);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeekRatio == null
              ? null
              : (d) => seek(d.localPosition.dx),
          onHorizontalDragUpdate: onSeekRatio == null
              ? null
              : (d) => seek(d.localPosition.dx),
          child: SizedBox(
            height: 16,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5DBFF), Color(0xFFFFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.ready,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onTogglePlay,
  });

  final bool playing;
  final bool ready;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CircleIcon(
              onTap: ready ? onSkipBack : null,
              icon: Icons.replay_10_rounded,
              size: 56,
            ),
            // Большой gradient play/pause с тенью и pulse-обводкой во время play.
            _PlayPauseButton(
              playing: playing,
              ready: ready,
              onTap: onTogglePlay,
            ),
            _CircleIcon(
              onTap: ready ? onSkipForward : null,
              icon: Icons.forward_10_rounded,
              size: 56,
            ),
          ],
        ),
        if (hasPrev || hasNext) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleIcon(
                onTap: hasPrev ? onPrev : null,
                icon: Icons.skip_previous_rounded,
                size: 44,
              ),
              const SizedBox(width: 32),
              _CircleIcon(
                onTap: hasNext ? onNext : null,
                icon: Icons.skip_next_rounded,
                size: 44,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.onTap,
    required this.icon,
    required this.size,
  });
  final VoidCallback? onTap;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.08 : 0.04),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.4),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.ready,
    required this.onTap,
  });

  final bool playing;
  final bool ready;
  final VoidCallback onTap;

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.playing) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.playing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse-обводка во время воспроизведения.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              final scale = 1.0 + 0.25 * t;
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              return IgnorePointer(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB39DFF)
                            .withValues(alpha: 0.5 * opacity),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Material(
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            color: Colors.transparent,
            child: Ink(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE9DBFF),
                    Color(0xFFB39DFF),
                    Color(0xFF7C5CFF),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55B39DFF),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.ready ? widget.onTap : null,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(
                    widget.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFF1B0E3A),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
