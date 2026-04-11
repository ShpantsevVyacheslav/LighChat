import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';

/// Inline video attachment (web parity: preview + tap to play/pause).
class MessageVideoAttachment extends StatefulWidget {
  const MessageVideoAttachment({super.key, required this.attachment});

  final ChatAttachment attachment;

  @override
  State<MessageVideoAttachment> createState() => _MessageVideoAttachmentState();
}

class _MessageVideoAttachmentState extends State<MessageVideoAttachment> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.attachment.url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.setLooping(false);
      c.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _controller = c);
    } catch (_) {
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

    if (_failed) {
      return _errorBox(scheme, Icons.videocam_off_rounded);
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }

    final ar = c.value.aspectRatio;
    final safeAr = (ar > 0 && ar.isFinite) ? ar : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: safeAr,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: VideoPlayer(c)),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (c.value.isPlaying) {
                    c.pause();
                  } else {
                    c.play();
                  }
                },
                child: AnimatedOpacity(
                  opacity: c.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(ColorScheme scheme, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 140,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          child: Center(
            child: Icon(icon, size: 40, color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }
}
