import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders a local video as a still preview frame (first frame),
/// for thumbnails / pre-send previews.
class VideoFirstFrame extends StatefulWidget {
  const VideoFirstFrame({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final File file;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  State<VideoFirstFrame> createState() => _VideoFirstFrameState();
}

class _VideoFirstFrameState extends State<VideoFirstFrame> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void didUpdateWidget(covariant VideoFirstFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      unawaited(_disposeController());
      _ready = false;
      unawaited(_init());
    }
  }

  Future<void> _disposeController() async {
    final c = _c;
    _c = null;
    if (c == null) return;
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _init() async {
    final c = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    try {
      await c.initialize();
      // Ensure first frame is decoded and displayed.
      await c.seekTo(const Duration(milliseconds: 1));
      await c.pause();
      if (!mounted || !identical(_c, c)) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted || !identical(_c, c)) return;
      setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (!_ready || c == null || !c.value.isInitialized) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final ar = c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 100 * ar,
        height: 100,
        child: VideoPlayer(c),
      ),
    );
  }
}

