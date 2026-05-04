import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../l10n/app_localizations.dart';
import 'chat_gallery_video_local_cache.dart';
import 'chat_vlc_network_media.dart';
import 'video_cached_thumb_image.dart';

const double _kCircleCollapsed = 192;
const double _kMinVisibleRatio = 0.12;

/// Видеокружок в ленте (паритет `VideoCirclePlayer.tsx`).
class MessageVideoCirclePlayer extends StatefulWidget {
  const MessageVideoCirclePlayer({
    super.key,
    required this.attachment,
    required this.playbackSlotId,
    required this.isMine,
    required this.createdAt,
    this.deliveryStatus,
    this.readAt,
    required this.showTimestamps,
    required this.playingSlotId,
    required this.attachmentIndex,
    this.mediaNorm,
    this.onRetryNorm,
  });

  final ChatAttachment attachment;
  final String playbackSlotId;
  final bool isMine;
  final DateTime createdAt;
  final String? deliveryStatus;
  final DateTime? readAt;
  final bool showTimestamps;
  final ValueNotifier<String?> playingSlotId;
  final int attachmentIndex;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryNorm;

  @override
  State<MessageVideoCirclePlayer> createState() =>
      _MessageVideoCirclePlayerState();
}

class _MessageVideoCirclePlayerState extends State<MessageVideoCirclePlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _ready = false;
  bool _isPlaying = false;
  bool _muted = true;
  bool _controlsVisible = false;
  Timer? _hideControlsTimer;
  double _durationSec = 0;
  OverlayEntry? _playOverlay;

  @override
  void initState() {
    super.initState();
    widget.playingSlotId.addListener(_onGlobalPlayingChanged);
    if (_normState == ChatMediaNormUiState.none) {
      unawaited(_initNetwork());
    }
  }

  @override
  void didUpdateWidget(covariant MessageVideoCirclePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urlChanged = oldWidget.attachment.url != widget.attachment.url;
    final normChanged =
        oldWidget.mediaNorm != widget.mediaNorm ||
        oldWidget.attachmentIndex != widget.attachmentIndex;
    if (urlChanged) {
      final c = _controller;
      if (c != null) {
        c.removeListener(_onVideoTick);
        c.dispose();
      }
      _controller = null;
      _ready = false;
      _failed = false;
      _isPlaying = false;
    }
    if ((urlChanged || normChanged) &&
        _normState == ChatMediaNormUiState.none &&
        !_ready &&
        !_failed) {
      unawaited(_initNetwork());
    }
  }

  ChatMediaNormUiState get _normState => chatMediaNormUiStateForAttachment(
    attachment: widget.attachment,
    attachmentIndex: widget.attachmentIndex,
    mediaNorm: widget.mediaNorm,
  );

  void _onGlobalPlayingChanged() {
    final v = widget.playingSlotId.value;
    if (v != widget.playbackSlotId && _controller?.value.isPlaying == true) {
      unawaited(_controller?.pause());
    }
  }

  Future<void> _initNetwork() async {
    final sourceUrl = widget.attachment.url.trim();
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      // E2EE v2: расшифрованные файлы лежат локально как `file://...`.
      // `VideoPlayerController.networkUrl` не умеет открывать их через
      // platform media stack — нужен `VideoPlayerController.file`.
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
      c.addListener(_onVideoTick);
      await c.pause();
      await _bumpPreviewFrame(c);
      if (!mounted) {
        await c.dispose();
        return;
      }
      final d = c.value.duration.inMilliseconds / 1000.0;
      setState(() {
        _controller = c;
        _ready = true;
        if (d.isFinite && d > 0) _durationSec = d;
      });
    } catch (_) {
      await c?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

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

  void _removePlayOverlay() {
    _playOverlay?.remove();
    _playOverlay?.dispose();
    _playOverlay = null;
  }

  void _insertPlayOverlay() {
    if (_playOverlay != null || !mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _playOverlay = OverlayEntry(
      builder: (ctx) => _buildFullscreenPlayOverlay(ctx),
    );
    overlay.insert(_playOverlay!);
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final playing = c.value.isPlaying;
    final dMs = c.value.duration.inMilliseconds;
    if (dMs > 0) {
      final ds = dMs / 1000.0;
      if (ds != _durationSec) _durationSec = ds;
    }

    if (playing != _isPlaying) {
      if (!playing) {
        if (widget.playingSlotId.value == widget.playbackSlotId) {
          widget.playingSlotId.value = null;
        }
        _removePlayOverlay();
      }
      setState(() => _isPlaying = playing);
      if (playing) {
        widget.playingSlotId.value = widget.playbackSlotId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              _controller == null ||
              !_controller!.value.isPlaying) {
            return;
          }
          _insertPlayOverlay();
        });
      }
    } else if (playing) {
      // Не вызывать setState на каждом тике: в ленте при play показывается только
      // заглушка — лишние пересборки строки ломали скролл у соседнего inline-видео.
      _playOverlay?.markNeedsBuild();
    }
  }

  void _flashControls() {
    _hideControlsTimer?.cancel();
    setState(() => _controlsVisible = true);
    _playOverlay?.markNeedsBuild();
    _hideControlsTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        _playOverlay?.markNeedsBuild();
      }
    });
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
    _playOverlay?.markNeedsBuild();
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null) return;
    final next = !_muted;
    setState(() => _muted = next);
    await c.setVolume(next ? 0 : 1);
    _playOverlay?.markNeedsBuild();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final c = _controller;
    if (c == null || !c.value.isPlaying) return;
    if (info.visibleFraction < _kMinVisibleRatio) {
      unawaited(c.pause());
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _removePlayOverlay();
    widget.playingSlotId.removeListener(_onGlobalPlayingChanged);
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(double sec) {
    if (!sec.isFinite || sec <= 0) return '0:00';
    final m = sec ~/ 60;
    final s = (sec % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double _progressForPaint() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return 0;
    final d = c.value.duration.inMilliseconds;
    if (d <= 0) return 0;
    return (c.value.position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  double _playbackDiameter(Size screenSize) {
    final want = _kCircleCollapsed * 2;
    final maxFit = math.min(screenSize.width - 24, screenSize.height - 100);
    return math.min(want, maxFit).clamp(120.0, maxFit);
  }

  Widget _circleVisualLayers(double side, ColorScheme scheme) {
    final c = _controller!;
    final progress = _progressForPaint();
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.22),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: VideoCachedThumbImage(
                videoUrl: widget.attachment.url,
                fit: BoxFit.cover,
              ),
            ),
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: IgnorePointer(
                  // Avoid the platform video view swallowing scroll gestures.
                  ignoring: true,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            if (_ready && (_isPlaying || _controlsVisible))
              CustomPaint(
                painter: _CircleProgressPainter(
                  progress: progress,
                  trackColor: Colors.white.withValues(alpha: 0.15),
                  progressColor: Colors.white.withValues(alpha: 0.6),
                ),
                size: Size.square(side),
              ),
            if (_controlsVisible && _ready)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        _formatDuration(_durationSec),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_isPlaying && _controlsVisible && _ready)
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.22),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: side * 0.28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (_controlsVisible && _ready)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        _flashControls();
                        unawaited(_toggleMute());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Footer meta under the circle is intentionally hidden.
          ],
        ),
      ),
    );
  }

  Widget _circleFooterMeta() {
    return const SizedBox.shrink();
  }

  Widget _wrappedInteractiveCircle(BuildContext context, double side) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => unawaited(_togglePlay()),
      behavior: HitTestBehavior.deferToChild,
      child: SizedBox(
        width: side,
        height: side,
        child: _circleVisualLayers(side, scheme),
      ),
    );
  }

  Widget _inlineCircleBody(Widget circle) {
    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [circle, _circleFooterMeta()],
      ),
    );
  }

  Widget _buildFullscreenPlayOverlay(BuildContext overlayContext) {
    final scheme = Theme.of(overlayContext).colorScheme;
    final side = _playbackDiameter(MediaQuery.sizeOf(overlayContext));
    final c = _controller;
    if (c == null || !_ready) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_controller?.pause()),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
            ),
          ),
          Center(
            child: Listener(
              onPointerDown: (e) {
                if (e.kind == PointerDeviceKind.touch ||
                    e.kind == PointerDeviceKind.mouse ||
                    e.kind == PointerDeviceKind.stylus) {
                  _flashControls();
                }
              },
              child: MouseRegion(
                onEnter: (_) => _flashControls(),
                child: GestureDetector(
                  onTap: () => unawaited(_togglePlay()),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: _circleVisualLayers(side, scheme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collapsedPlaceholder() {
    return SizedBox(
      width: _kCircleCollapsed,
      height: _kCircleCollapsed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded, color: Colors.white38),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normState = _normState;
    if (normState != ChatMediaNormUiState.none) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ChatMediaNormStatusWidget(
          state: normState,
          mediaKindLabel: AppLocalizations.of(context)!.video_circle_media_kind,
          onRetry: widget.onRetryNorm,
        ),
      );
    }
    if (_failed) {
      return SizedBox(
        width: _kCircleCollapsed,
        height: _kCircleCollapsed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: const Center(
            child: Icon(Icons.videocam_off_rounded, color: Colors.white54),
          ),
        ),
      );
    }

    if (_isPlaying && _ready && _controller != null) {
      return VisibilityDetector(
        key: Key('vc-vis-${widget.playbackSlotId}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: _inlineCircleBody(_collapsedPlaceholder()),
      );
    }

    return VisibilityDetector(
      key: Key('vc-vis-${widget.playbackSlotId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _inlineCircleBody(
        _ready && _controller != null
            ? _wrappedInteractiveCircle(context, _kCircleCollapsed)
            : _circleLoadingPlaceholder(),
      ),
    );
  }

  /// Пока `VideoPlayer` инициализируется — круг как у готового кружка (не чёрный квадрат).
  Widget _circleLoadingPlaceholder() {
    return SizedBox(
      width: _kCircleCollapsed,
      height: _kCircleCollapsed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 3,
          ),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoCachedThumbImage(
                videoUrl: widget.attachment.url,
                fit: BoxFit.cover,
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white54,
                    ),
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
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
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
