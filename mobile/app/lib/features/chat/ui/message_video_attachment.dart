import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../data/chat_media_layout_tokens.dart';
import '../data/video_attachment_diagnostics.dart';
import 'chat_gallery_video_local_cache.dart';
import 'chat_vlc_network_media.dart';
import 'video_cached_thumb_image.dart';

/// Inline video: первый кадр через `video_player`, полноэкран — как раньше.
class MessageVideoAttachment extends StatefulWidget {
  const MessageVideoAttachment({
    super.key,
    required this.attachment,
    required this.attachmentIndex,
    this.mediaNorm,
    this.onRetryNorm,
    this.onOpenInGallery,
  });

  final ChatAttachment attachment;
  final int attachmentIndex;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryNorm;

  /// Если задан, тап открывает общую галерею чата вместо отдельного экрана плеера.
  final VoidCallback? onOpenInGallery;

  @override
  State<MessageVideoAttachment> createState() => _MessageVideoAttachmentState();
}

class _MessageVideoAttachmentState extends State<MessageVideoAttachment> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _thumbReady = false;
  bool _muted = true;
  bool _controlsVisible = false;
  bool _autoplayPausedByUser = false;
  Timer? _hideControlsTimer;
  double _visibleFraction = 0;

  static const double _kAutoPlayVisible = 0.55;
  static const double _kAutoPauseVisible = 0.18;

  @override
  void initState() {
    super.initState();
    if (_normState == ChatMediaNormUiState.none) {
      unawaited(_loadThumb());
    }
  }

  @override
  void didUpdateWidget(covariant MessageVideoAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urlChanged = oldWidget.attachment.url != widget.attachment.url;
    final normChanged =
        oldWidget.mediaNorm != widget.mediaNorm ||
        oldWidget.attachmentIndex != widget.attachmentIndex;
    if (urlChanged) {
      _hideControlsTimer?.cancel();
      _controller?.dispose();
      _controller = null;
      _thumbReady = false;
      _failed = false;
      _controlsVisible = false;
      _autoplayPausedByUser = false;
    }
    if ((urlChanged || normChanged) &&
        _normState == ChatMediaNormUiState.none &&
        !_thumbReady &&
        !_failed) {
      unawaited(_loadThumb());
    }
  }

  ChatMediaNormUiState get _normState => chatMediaNormUiStateForAttachment(
    attachment: widget.attachment,
    attachmentIndex: widget.attachmentIndex,
    mediaNorm: widget.mediaNorm,
  );

  Future<void> _loadThumb() async {
    final sourceUrl = widget.attachment.url.trim();
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      // E2EE v2: расшифрованные вложения — локальный `file://` путь.
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
      await c.pause();
      // Ensure a preview frame is available.
      await c.seekTo(const Duration(milliseconds: 1));
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _thumbReady = true;
      });
      _maybeAutoPlay();
    } catch (_) {
      await c?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  void _flashControls() {
    _hideControlsTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideControlsTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _visibleFraction = info.visibleFraction;
    _maybeAutoPlay();
  }

  void _maybeAutoPlay() {
    final c = _controller;
    if (c == null || !_thumbReady || _failed) return;
    if (!mounted) return;
    if (_autoplayPausedByUser) return;
    if (_visibleFraction >= _kAutoPlayVisible) {
      if (!c.value.isPlaying) {
        unawaited(c.play());
      }
    } else if (_visibleFraction <= _kAutoPauseVisible) {
      if (c.value.isPlaying) {
        unawaited(c.pause());
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !_thumbReady || _failed) return;
    _flashControls();
    if (c.value.isPlaying) {
      await c.pause();
      if (mounted && !_autoplayPausedByUser) {
        setState(() => _autoplayPausedByUser = true);
      }
    } else {
      await c.setVolume(_muted ? 0 : 1);
      await c.play();
      if (mounted && _autoplayPausedByUser) {
        setState(() => _autoplayPausedByUser = false);
      }
    }
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null || !_thumbReady || _failed) return;
    _flashControls();
    final next = !_muted;
    setState(() => _muted = next);
    await c.setVolume(next ? 0 : 1);
  }

  Future<void> _openFullscreen(BuildContext context, String url) async {
    final gallery = widget.onOpenInGallery;
    if (gallery != null) {
      gallery();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ChatAvPlayerVideoScreen(url: url),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = widget.attachment.width;
    final h = widget.attachment.height;
    final c = _controller;
    // Стабильная высота ячейки: ширина/высота берём ТОЛЬКО из метаданных вложения.
    // arFromController сюда не подмешиваем — он становится известен лишь после
    // `c.initialize()` и при отсутствии w/h в метаданных давал «скачок»
    // 16:9 → реальное соотношение в момент инициализации. Когда в ленте подряд
    // несколько видео, эти скачки накладывались и блокировали скролл.
    // Контент внутри подгоняется через FittedBox(BoxFit.cover) — портретные
    // видео без метаданных будут center-cropped, но лента остаётся стабильной.
    final safeAr = (w != null && h != null && w > 0 && h > 0)
        ? w / h
        : 16 / 9;
    if (kLogVideoAttachmentDiagnostics) {
      VideoAttachmentAspectMonitor.observe(
        url: widget.attachment.url,
        ar: safeAr,
        hasMetadata: w != null && h != null && w > 0 && h > 0,
        controllerInitialized: c != null && c.value.isInitialized,
      );
    }
    final url = widget.attachment.url;
    final normState = _normState;

    return VisibilityDetector(
      key: ValueKey<String>('vid-vis-${widget.attachmentIndex}-$url'),
      onVisibilityChanged: _onVisibilityChanged,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ChatMediaLayoutTokens.mediaCardRadius,
        ),
        child: AspectRatio(
          aspectRatio: safeAr,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (normState == ChatMediaNormUiState.none &&
                  url.trim().isNotEmpty)
                VideoCachedThumbImage(videoUrl: url, fit: BoxFit.cover),
              if (normState != ChatMediaNormUiState.none)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: ChatMediaNormStatusWidget(
                        state: normState,
                        mediaKindLabel: 'видео',
                        onRetry: widget.onRetryNorm,
                        compact: true,
                      ),
                    ),
                  ),
                )
              else if (_thumbReady &&
                  _controller != null &&
                  !_failed &&
                  _controller!.value.size.width > 0 &&
                  _controller!.value.size.height > 0)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: IgnorePointer(
                      // iOS platform video view can swallow vertical drags and
                      // break list scrolling while the video is playing.
                      ignoring: true,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  child: Center(
                    child: _failed
                        ? Icon(
                            Icons.videocam_rounded,
                            size: 36,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          )
                        : const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  ),
                ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: normState != ChatMediaNormUiState.none
                      ? null
                      : () => unawaited(_togglePlayPause()),
                  onLongPress: normState != ChatMediaNormUiState.none
                      ? null
                      : () => unawaited(_openFullscreen(context, url)),
                  child: _InlineVideoControls(
                    controller: _controller,
                    thumbReady: _thumbReady,
                    failed: _failed,
                    controlsVisible: _controlsVisible,
                    muted: _muted,
                    onToggleMute: () => unawaited(_toggleMute()),
                    onOpenFullscreen: () =>
                        unawaited(_openFullscreen(context, url)),
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

/// Вынесенный слой управляющих элементов инлайн-плеера. Перерисовывается
/// через `ValueListenableBuilder` на `VideoPlayerController`, поэтому тики
/// плеера не затрагивают родительский [MessageVideoAttachment] и его
/// [VisibilityDetector] — иначе они вызывали lay out-штормы в ленте чата и
/// «дрожание»/блокировку скролла во время воспроизведения.
class _InlineVideoControls extends StatelessWidget {
  const _InlineVideoControls({
    required this.controller,
    required this.thumbReady,
    required this.failed,
    required this.controlsVisible,
    required this.muted,
    required this.onToggleMute,
    required this.onOpenFullscreen,
  });

  final VideoPlayerController? controller;
  final bool thumbReady;
  final bool failed;
  final bool controlsVisible;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenFullscreen;

  static String _fmtDur(Duration d) {
    var s = d.inSeconds;
    if (s < 0) s = 0;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return _buildStack(
        context: context,
        isPlaying: false,
        remaining: Duration.zero,
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        final d = value.duration;
        final remaining = d > Duration.zero
            ? (d - value.position).isNegative
                  ? Duration.zero
                  : (d - value.position)
            : Duration.zero;
        return _buildStack(
          context: context,
          isPlaying: value.isPlaying,
          remaining: remaining,
        );
      },
    );
  }

  Widget _buildStack({
    required BuildContext context,
    required bool isPlaying,
    required Duration remaining,
  }) {
    final showOverlay = !isPlaying;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showOverlay)
          ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
        Center(
          child: AnimatedOpacity(
            opacity: (controlsVisible || !isPlaying) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 160),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.38),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 34,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
        if (thumbReady && !failed && isPlaying)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                _fmtDur(remaining),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        if (thumbReady && !failed && isPlaying)
          Positioned(
            right: 10,
            top: 10,
            child: _RoundIconButton(
              icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              onTap: onToggleMute,
            ),
          ),
        if (thumbReady && !failed)
          Positioned(
            right: 10,
            bottom: 10,
            child: AnimatedOpacity(
              opacity: controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 160),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundIconButton(
                    icon: Icons.fullscreen_rounded,
                    onTap: onOpenFullscreen,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.40),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }
}

class _ChatAvPlayerVideoScreen extends StatefulWidget {
  const _ChatAvPlayerVideoScreen({required this.url});

  final String url;

  @override
  State<_ChatAvPlayerVideoScreen> createState() =>
      _ChatAvPlayerVideoScreenState();
}

class _ChatAvPlayerVideoScreenState extends State<_ChatAvPlayerVideoScreen> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  void _onControllerTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    if (c.value.hasError) {
      setState(() => _failed = true);
    }
  }

  Future<void> _init() async {
    VideoPlayerController? c;
    try {
      final sourceUrl = widget.url.trim();
      final uri = Uri.tryParse(sourceUrl);
      if (uri == null || uri.scheme.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }

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
      c.addListener(_onControllerTick);
      await c.initialize();
      if (!mounted) {
        c.removeListener(_onControllerTick);
        await c.dispose();
        return;
      }
      if (c.value.hasError) {
        c.removeListener(_onControllerTick);
        await c.dispose();
        setState(() => _failed = true);
        return;
      }
      await c.setLooping(false);
      await c.play();
      if (!mounted) {
        c.removeListener(_onControllerTick);
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (_) {
      if (c != null) {
        c.removeListener(_onControllerTick);
        await c.dispose();
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerTick);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Видео'),
      ),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Не удалось воспроизвести видео. Проверьте ссылку и сеть.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            : (c == null || !c.value.isInitialized)
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: c.value.aspectRatio > 0
                    ? c.value.aspectRatio
                    : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(c),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (c.value.isPlaying) {
                            c.pause();
                          } else {
                            c.play();
                          }
                          setState(() {});
                        },
                        child: AnimatedOpacity(
                          opacity: c.value.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
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
