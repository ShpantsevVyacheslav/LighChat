import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';

import 'chat_gallery_video_local_cache.dart';
import 'video_cached_thumb_image.dart';

/// Сетка «Кружков» в профиле собеседника — визуальный паритет с вебом:
/// - круглые превью с play-оверлеем;
/// - выбранный кружок раскрывается inline (крупный круг + управление).
class VideoCircleGallery extends StatefulWidget {
  const VideoCircleGallery({
    super.key,
    required this.items,
    required this.activeUrl,
    required this.onActiveUrlChanged,
  });

  final List<({ChatMessage message, ChatAttachment attachment})> items;
  final String? activeUrl;
  final ValueChanged<String?> onActiveUrlChanged;

  @override
  State<VideoCircleGallery> createState() => _VideoCircleGalleryState();
}

class _VideoCircleGalleryState extends State<VideoCircleGallery> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _playing = false;
  bool _muted = true;
  double _durationSec = 0;

  String? get _activeUrl => widget.activeUrl;

  @override
  void initState() {
    super.initState();
    unawaited(_syncController());
  }

  @override
  void didUpdateWidget(covariant VideoCircleGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeUrl != widget.activeUrl) {
      unawaited(_syncController());
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onTick);
      unawaited(c.dispose());
    }
    _controller = null;
    _lastUrl = null;
    _ready = false;
    _failed = false;
    _playing = false;
    _durationSec = 0;
  }

  Future<void> _syncController() async {
    final url = _activeUrl;
    if (url == null || url.trim().isEmpty) {
      _disposeController();
      if (mounted) setState(() {});
      return;
    }

    // Если тот же URL — ничего не делаем.
    if (_controller != null && _lastUrl == url) return;

    _disposeController();
    if (mounted) {
      setState(() {
        _failed = false;
        _ready = false;
      });
    }

    final sourceUrl = url.trim();
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    VideoPlayerController? c;
    try {
      if (uri.scheme == 'file') {
        c = VideoPlayerController.file(
          File(uri.toFilePath()),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        final cached = await ChatGalleryVideoLocalCache.cachedFileIfExists(
          sourceUrl,
        );
        if (cached != null) {
          c = VideoPlayerController.file(
            cached,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          unawaited(ChatGalleryVideoLocalCache.warmUp(sourceUrl));
          c = VideoPlayerController.networkUrl(
            uri,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        }
      }
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      if (c.value.hasError) {
        await c.dispose();
        setState(() => _failed = true);
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0);
      c.addListener(_onTick);
      await c.pause();
      await _bumpPreviewFrame(c);

      final d = c.value.duration.inMilliseconds / 1000.0;
      setState(() {
        _controller = c;
        _lastUrl = url;
        _ready = true;
        _failed = false;
        if (d.isFinite && d > 0) _durationSec = d;
      });
    } catch (e) {
      await c?.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  String? _lastUrl;

  Future<void> _bumpPreviewFrame(VideoPlayerController c) async {
    try {
      final d = c.value.duration;
      if (d == Duration.zero) return;
      final ms = d.inMilliseconds;
      final t = (ms * 0.02).round().clamp(1, 100);
      await c.seekTo(Duration(milliseconds: t));
      await c.pause();
    } catch (_) {}
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final playing = c.value.isPlaying;
    final dMs = c.value.duration.inMilliseconds;
    if (dMs > 0) {
      final ds = dMs / 1000.0;
      if (ds != _durationSec && ds.isFinite && ds > 0) {
        _durationSec = ds;
      }
    }
    if (playing != _playing) {
      setState(() => _playing = playing);
    } else {
      // Обновляем прогресс.
      setState(() {});
    }
  }

  double _progress() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return 0;
    final d = c.value.duration.inMilliseconds;
    if (d <= 0) return 0;
    return (c.value.position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  String _formatDuration(double sec) {
    if (!sec.isFinite || sec <= 0) return '0:00';
    final m = sec ~/ 60;
    final s = (sec % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.setVolume(_muted ? 0 : 1);
      await c.play();
    }
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null) return;
    final next = !_muted;
    setState(() => _muted = next);
    await c.setVolume(next ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeUrl = _activeUrl;

    final grid = GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i].attachment;
        final url = a.url;
        final isActive = activeUrl == url;
        return _CircleThumb(
          url: url,
          selected: isActive,
          onTap: () => widget.onActiveUrlChanged(isActive ? null : url),
        );
      },
    );

    if (activeUrl == null) return grid;

    return Column(
      children: [
        const SizedBox(height: 6),
        _ActiveCirclePlayer(
          url: activeUrl,
          controller: _controller,
          ready: _ready,
          failed: _failed,
          playing: _playing,
          muted: _muted,
          durationLabel: _formatDuration(_durationSec),
          progress: _progress(),
          onTogglePlay: () => unawaited(_togglePlay()),
          onToggleMute: () => unawaited(_toggleMute()),
          onClose: () => widget.onActiveUrlChanged(null),
        ),
        const SizedBox(height: 14),
        Expanded(child: grid),
      ],
    );
  }
}

class _CircleThumb extends StatelessWidget {
  const _CircleThumb({
    required this.url,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final ring = selected
        ? const Color(0xFF2F86FF)
        : (dark ? Colors.white : scheme.onSurface).withValues(
            alpha: dark ? 0.10 : 0.10,
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: selected ? 2 : 1),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoCachedThumbImage(videoUrl: url, fit: BoxFit.cover),
              ColoredBox(color: Colors.black.withValues(alpha: 0.16)),
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCirclePlayer extends StatelessWidget {
  const _ActiveCirclePlayer({
    required this.url,
    required this.controller,
    required this.ready,
    required this.failed,
    required this.playing,
    required this.muted,
    required this.durationLabel,
    required this.progress,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onClose,
  });

  final String url;
  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;
  final bool playing;
  final bool muted;
  final String durationLabel;
  final double progress;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final side = (MediaQuery.sizeOf(context).width - 48).clamp(220.0, 420.0);

    Widget inner;
    if (failed) {
      inner = const Center(
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white54,
          size: 44,
        ),
      );
    } else {
      inner = Stack(
        fit: StackFit.expand,
        children: [
          VideoCachedThumbImage(videoUrl: url, fit: BoxFit.cover),
          if (ready && controller != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            ),
          if (!playing) ColoredBox(color: Colors.black.withValues(alpha: 0.20)),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: side * 0.22,
              height: side * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.42),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: side * 0.12,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.40),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                durationLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: InkWell(
              onTap: onToggleMute,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.40),
                ),
                child: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CircleProgressPainter(
                  progress: progress,
                  trackColor: Colors.white.withValues(alpha: 0.12),
                  progressColor: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTogglePlay,
      child: SizedBox(
        width: side,
        height: side,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (dark ? Colors.white : scheme.onSurface).withValues(
                alpha: dark ? 0.14 : 0.10,
              ),
              width: 2,
            ),
          ),
          child: ClipOval(child: inner),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  _CircleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1;
    const sw = 2.0;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    final prog = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    final sweep = 6.283185307179586 * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5707963267948966,
      sweep,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
