import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/video_url_first_frame_cache.dart';

/// Статичный первый кадр сетевого видео из локального кэша (ffmpeg).
class VideoCachedThumbImage extends StatefulWidget {
  const VideoCachedThumbImage({
    super.key,
    required this.videoUrl,
    this.conversationId,
    this.messageId,
    this.attachmentName,
    this.fit = BoxFit.cover,
  });

  final String videoUrl;
  final String? conversationId;
  final String? messageId;
  final String? attachmentName;
  final BoxFit fit;

  @override
  State<VideoCachedThumbImage> createState() => _VideoCachedThumbImageState();
}

class _VideoCachedThumbImageState extends State<VideoCachedThumbImage> {
  File? _file;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant VideoCachedThumbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final f = await VideoUrlFirstFrameCache.instance.getOrCreate(
      widget.videoUrl,
      conversationId: widget.conversationId,
      messageId: widget.messageId,
      attachmentName: widget.attachmentName,
    );
    if (!mounted) return;
    setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    final f = _file;
    if (f == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.20),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            color: Color(0xCCFFFFFF),
            size: 26,
          ),
        ),
      );
    }
    return Image.file(
      f,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.30)),
      ),
    );
  }
}
