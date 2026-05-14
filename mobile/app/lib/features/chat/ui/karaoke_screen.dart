import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_voice_transcriber.dart';
import 'chat_avatar.dart';

/// Полноэкранный «караоке» режим воспроизведения голосового сообщения —
/// в стиле lyrics-вью у Apple Music / Яндекс Музыки.
///
/// На экране: чёрный фон, наверху close, по центру 3 строки текста
/// (прошлая + текущая + следующая), внизу карточка с аватаром
/// отправителя, прогресс-бар и кнопки управления.
///
/// Слова из [TranscriptSegment]-ов группируются в «строки» эвристикой —
/// по знакам препинания + лимиту слов.
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({
    super.key,
    required this.audioUrl,
    required this.segments,
    required this.senderName,
    required this.senderAvatarUrl,
  });

  final String audioUrl;
  final List<TranscriptSegment> segments;
  final String senderName;
  final String? senderAvatarUrl;

  static Future<void> push(
    BuildContext context, {
    required String audioUrl,
    required List<TranscriptSegment> segments,
    required String senderName,
    required String? senderAvatarUrl,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, secAnim) => KaraokeScreen(
          audioUrl: audioUrl,
          segments: segments,
          senderName: senderName,
          senderAvatarUrl: senderAvatarUrl,
        ),
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  late final AudioPlayer _player;
  late final List<List<TranscriptSegment>> _lines;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _ready = false;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _lines = _groupIntoLines(widget.segments);
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_setup());
  }

  Future<void> _setup() async {
    final uri = Uri.tryParse(widget.audioUrl);
    if (uri == null) return;
    try {
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
      // Авто-старт — пользователь явно выбрал karaoke-режим.
      await _player.play();
    } catch (_) {/* fail silently — UI всё ещё показывает текст */}
  }

  @override
  void dispose() {
    unawaited(_posSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  /// Группируем word-сегменты в «строки» по 4-8 слов, закрывая строку
  /// на сильной пунктуации (`.?!…`) или по лимиту.
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

  /// Активная строка — та, в чей диапазон попадает текущая позиция плеера.
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

  String _lineText(int index) => _lines[index]
      .map((s) => s.text.trim())
      .where((t) => t.isNotEmpty)
      .join(' ');

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
      backgroundColor: const Color(0xFF0B0B0E),
      body: SafeArea(
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
                  onSeekToLine: (i) => unawaited(_player.seek(_lineStart(i))),
                  textForLine: _lineText,
                ),
              ),
              const SizedBox(height: 8),
              _SenderCard(
                name: widget.senderName,
                avatarUrl: widget.senderAvatarUrl,
                subtitle: l10n.voice_attachment_title_voice_message,
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
              const SizedBox(height: 12),
              _Controls(
                playing: _playing,
                ready: _ready,
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
    );
  }
}

const TextStyle _timeStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFF9CA0AB),
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

class _LyricsView extends StatelessWidget {
  const _LyricsView({
    required this.lines,
    required this.activeIndex,
    required this.onSeekToLine,
    required this.textForLine,
  });

  final List<List<TranscriptSegment>> lines;
  final int activeIndex;
  final void Function(int) onSeekToLine;
  final String Function(int) textForLine;

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
            _LyricLine(
              text: textForLine(prev),
              opacity: 0.32,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              onTap: () => onSeekToLine(prev),
            ),
            const SizedBox(height: 22),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _LyricLine(
              key: ValueKey<int>(clampedActive),
              text: textForLine(clampedActive),
              opacity: 1.0,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              onTap: () => onSeekToLine(clampedActive),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 22),
            _LyricLine(
              text: textForLine(next),
              opacity: 0.32,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              onTap: () => onSeekToLine(next),
            ),
          ],
        ],
      ),
    );
  }
}

class _LyricLine extends StatelessWidget {
  const _LyricLine({
    super.key,
    required this.text,
    required this.opacity,
    required this.fontSize,
    required this.fontWeight,
    required this.onTap,
  });

  final String text;
  final double opacity;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.2,
            letterSpacing: -0.4,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _SenderCard extends StatelessWidget {
  const _SenderCard({
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
  });

  final String name;
  final String? avatarUrl;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          ChatAvatar(title: name, radius: 22, avatarUrl: avatarUrl),
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
                      color: Colors.white.withValues(alpha: 0.92),
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
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onTogglePlay,
  });

  final bool playing;
  final bool ready;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: ready ? onSkipBack : null,
          icon: const Icon(Icons.replay_10_rounded),
          iconSize: 36,
          color: Colors.white.withValues(alpha: 0.86),
        ),
        Material(
          color: accent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: ready ? onTogglePlay : null,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: ready ? onSkipForward : null,
          icon: const Icon(Icons.forward_10_rounded),
          iconSize: 36,
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ],
    );
  }
}
