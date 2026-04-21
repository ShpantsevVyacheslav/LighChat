import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';

import 'chat_cached_network_image.dart';

/// First pinned message preview + unpin (web `PinnedMessageBar` lite).
class ChatPinnedStrip extends StatelessWidget {
  const ChatPinnedStrip({
    super.key,
    required this.pin,
    required this.totalPins,
    required this.onUnpin,
    this.onOpenPinned,
  });

  final PinnedMessage pin;
  final int totalPins;
  final VoidCallback onUnpin;

  /// Скролл к закреплённому сообщению в списке (не срабатывает на кнопке «×»).
  final VoidCallback? onOpenPinned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveMediaType = _effectivePinnedMediaType(pin);
    final mediaTypeLabel = _mediaTypeLabel(effectiveMediaType);
    final contentLabel = mediaTypeLabel ?? pin.text;
    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalPins > 1 ? 'Закреплено: $totalPins' : 'Закреплено',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${pin.senderName}: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              TextSpan(
                text: contentLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.84),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.push_pin_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: onOpenPinned != null
                  ? InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onOpenPinned,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            _PinnedMediaThumb(
                              mediaType: effectiveMediaType,
                              mediaPreviewUrl: pin.mediaPreviewUrl,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: preview),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        _PinnedMediaThumb(
                          mediaType: effectiveMediaType,
                          mediaPreviewUrl: pin.mediaPreviewUrl,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: preview),
                      ],
                    ),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                tooltip: 'Открепить',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: onUnpin,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _effectivePinnedMediaType(PinnedMessage pin) {
  final direct = (pin.mediaType ?? '').trim().toLowerCase();
  if (direct.isNotEmpty) return direct;

  final t = pin.text.trim().toLowerCase();
  if (t.isEmpty) return null;
  if (t == 'опрос') return 'poll';
  if (t == 'локация' || t == 'местоположение') return 'location';
  if (t == 'ссылка') return 'link';
  if (t == 'фотография' || t == 'изображение') return 'image';
  if (t == 'видео') return 'video';
  if (t == 'кружок') return 'video-circle';
  if (t == 'голосовое сообщение') return 'audio';
  if (t == 'файл') return 'file';
  return null;
}

String? _mediaTypeLabel(String? mediaType) {
  switch ((mediaType ?? '').trim().toLowerCase()) {
    case 'image':
      return 'Изображение';
    case 'video':
      return 'Видео';
    case 'video-circle':
      return 'Видеокружок';
    case 'audio':
      return 'Голосовое сообщение';
    case 'poll':
      return 'Опрос';
    case 'link':
      return 'Ссылка';
    case 'location':
      return 'Локация';
    case 'sticker':
      return 'Стикер';
    case 'file':
      return 'Файл';
    default:
      return null;
  }
}

class _PinnedMediaThumb extends StatelessWidget {
  const _PinnedMediaThumb({
    required this.mediaType,
    required this.mediaPreviewUrl,
  });

  final String? mediaType;
  final String? mediaPreviewUrl;

  @override
  Widget build(BuildContext context) {
    final mt = (mediaType ?? '').trim().toLowerCase();
    final url = (mediaPreviewUrl ?? '').trim();
    final hasUrl = url.isNotEmpty;
    if (!hasUrl) {
      return _PinnedMediaIconBox(icon: _iconForMediaType(mt));
    }
    if (mt == 'video' || mt == 'video-circle') {
      return _PinnedVideoThumb(url: url, mediaType: mt);
    }
    return _PinnedImageThumb(url: url, mediaType: mt);
  }
}

class _PinnedImageThumb extends StatelessWidget {
  const _PinnedImageThumb({required this.url, required this.mediaType});

  final String url;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChatCachedNetworkImage(
              url: url,
              fit: mediaType == 'sticker' ? BoxFit.contain : BoxFit.cover,
            ),
            if (mediaType == 'sticker')
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedVideoThumb extends StatefulWidget {
  const _PinnedVideoThumb({required this.url, required this.mediaType});

  final String url;
  final String mediaType;

  @override
  State<_PinnedVideoThumb> createState() => _PinnedVideoThumbState();
}

class _PinnedVideoThumbState extends State<_PinnedVideoThumb> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(uri);
      await c.initialize();
      await c.pause();
      await c.seekTo(Duration.zero);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = c != null && c.value.size.width > 0 && c.value.size.height > 0;
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
    if (_failed || !_ready || _controller == null) {
      return _PinnedMediaIconBox(
        icon: widget.mediaType == 'video-circle'
            ? Icons.play_circle_outline_rounded
            : Icons.videocam_rounded,
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Icon(
                widget.mediaType == 'video-circle'
                    ? Icons.play_circle_fill_rounded
                    : Icons.play_arrow_rounded,
                size: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedMediaIconBox extends StatelessWidget {
  const _PinnedMediaIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        color: Colors.black.withValues(alpha: 0.20),
      ),
      child: Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.92)),
    );
  }
}

IconData _iconForMediaType(String mediaType) {
  switch (mediaType) {
    case 'video':
      return Icons.videocam_rounded;
    case 'video-circle':
      return Icons.play_circle_outline_rounded;
    case 'poll':
      return Icons.poll_rounded;
    case 'link':
      return Icons.link_rounded;
    case 'location':
      return Icons.location_on_rounded;
    case 'audio':
      return Icons.mic_rounded;
    case 'sticker':
      return Icons.emoji_emotions_rounded;
    case 'file':
      return Icons.insert_drive_file_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.chat_bubble_outline_rounded;
  }
}
