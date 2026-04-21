import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';

import '../data/chat_media_layout_tokens.dart';
import 'chat_vlc_network_media.dart';

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
      _controller?.dispose();
      _controller = null;
      _thumbReady = false;
      _failed = false;
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
    final uri = Uri.tryParse(widget.attachment.url);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
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
      await c.pause();
      await c.seekTo(Duration.zero);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _thumbReady = true;
      });
    } catch (_) {
      await c?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = widget.attachment.width;
    final h = widget.attachment.height;
    final safeAr = (w != null && h != null && w > 0 && h > 0) ? w / h : 16 / 9;
    final url = widget.attachment.url;
    final normState = _normState;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        ChatMediaLayoutTokens.mediaCardRadius,
      ),
      child: AspectRatio(
        aspectRatio: safeAr,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (normState != ChatMediaNormUiState.none)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: normState != ChatMediaNormUiState.none
                    ? null
                    : () {
                        final gallery = widget.onOpenInGallery;
                        if (gallery != null) {
                          gallery();
                          return;
                        }
                        unawaited(
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _ChatAvPlayerVideoScreen(url: url),
                            ),
                          ),
                        );
                      },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.20),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      final uri = Uri.tryParse(widget.url);
      if (uri == null || uri.scheme.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      c = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
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
