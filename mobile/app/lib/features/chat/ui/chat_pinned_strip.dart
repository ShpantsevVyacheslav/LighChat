import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'chat_cached_network_image.dart';
import 'video_cached_thumb_image.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final effectiveMediaType = _effectivePinnedMediaType(pin);
    final mediaTypeLabel = _mediaTypeLabel(effectiveMediaType, l10n);
    final contentLabel = mediaTypeLabel ?? pin.text;
    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalPins > 1 ? l10n.pinned_count(totalPins) : l10n.pinned_single,
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
                tooltip: l10n.pinned_unpin_tooltip,
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

String? _mediaTypeLabel(String? mediaType, AppLocalizations l10n) {
  switch ((mediaType ?? '').trim().toLowerCase()) {
    case 'image':
      return l10n.pinned_type_image;
    case 'video':
      return l10n.pinned_type_video;
    case 'video-circle':
      return l10n.pinned_type_video_circle;
    case 'audio':
      return l10n.pinned_type_voice;
    case 'poll':
      return l10n.pinned_type_poll;
    case 'link':
      return l10n.pinned_type_link;
    case 'location':
      return l10n.pinned_type_location;
    case 'sticker':
      return l10n.pinned_type_sticker;
    case 'file':
      return l10n.pinned_type_file;
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

class _PinnedVideoThumb extends StatelessWidget {
  const _PinnedVideoThumb({required this.url, required this.mediaType});

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
            VideoCachedThumbImage(videoUrl: url, fit: BoxFit.cover),
            Align(
              alignment: Alignment.center,
              child: Icon(
                mediaType == 'video-circle'
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
