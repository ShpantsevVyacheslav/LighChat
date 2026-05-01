import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_attachment_mosaic_layout.dart';
import '../data/chat_media_gallery.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/e2ee_decryption_orchestrator.dart'
    show e2eeMediaDecryptErrorMime;
import '../data/secret_chat_media_open_service.dart';
import '../data/video_circle_utils.dart';
import 'chat_cached_network_image.dart';
import 'message_video_attachment.dart';
import 'message_video_circle_player.dart';
import 'message_voice_attachment.dart';

/// Голосовые с веба: `audio/*` и файлы `audio_*.{webm,mp4,...}` (не путать с видео .webm).
bool _isVoiceAttachment(ChatAttachment a) {
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('audio/')) return true;
  final n = a.name.toLowerCase();
  if (n.startsWith('audio_')) return true;
  return false;
}

bool _isVideoAttachment(ChatAttachment a) {
  if (_isVoiceAttachment(a)) return false;
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('video/')) return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v') ||
      path.endsWith('.3gp');
}

bool _isImageAttachment(ChatAttachment a) {
  if (SecretChatMediaOpenService.isLockedSecretAttachment(a)) return true;
  if (_isVideoAttachment(a)) return false;
  if (_isE2eeMediaDecryptErrorAttachment(a)) return false;
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('image/')) return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic');
}

bool _isE2eeMediaDecryptErrorAttachment(ChatAttachment a) {
  return (a.type ?? '').toLowerCase() == e2eeMediaDecryptErrorMime;
}

bool _isStickerAttachment(ChatAttachment a) {
  final name = a.name.toLowerCase();
  return name.startsWith('sticker_') || name.contains('/sticker_');
}

bool _isGifInlineAttachment(ChatAttachment a) {
  return a.name.toLowerCase().startsWith('gif_');
}

double _attachmentsColumnWidth({
  required double available,
  required double gridMaxWidth,
  required List<ChatAttachment> images,
}) {
  final base = clampMediaWidth(available: available, maxWidth: gridMaxWidth);
  if (images.length != 1) return base;
  final a = images.first;
  if (!_isImageAttachment(a) || _isStickerAttachment(a)) return base;
  final w = a.width;
  final h = a.height;
  if (w == null || h == null || w <= 0 || h <= 0 || w < h * 1.02) {
    return base;
  }
  return clampMediaWidth(
    available: available,
    maxWidth:
        gridMaxWidth * ChatMediaLayoutTokens.horizontalAttachmentDisplayScale,
  );
}

class MessageAttachments extends StatefulWidget {
  const MessageAttachments({
    super.key,
    required this.attachments,
    this.alignRight = false,
    this.conversationId,
    this.messageId,
    this.messageCreatedAt,
    this.isMine,
    this.deliveryStatus,
    this.readAt,
    this.showTimestamps = true,
    this.voiceTranscript,
    this.videoCirclePlayingSlotId,
    this.onOpenGridGallery,
    this.mediaNorm,
    this.onRetryMediaNorm,
  });

  final List<ChatAttachment> attachments;
  final bool alignRight;
  final String? conversationId;
  final String? messageId;
  final DateTime? messageCreatedAt;
  final bool? isMine;
  final String? deliveryStatus;
  final DateTime? readAt;
  final bool showTimestamps;
  final String? voiceTranscript;
  final ValueNotifier<String?>? videoCirclePlayingSlotId;

  /// Тап по фото/видео из сетки галереи — полноэкранный просмотр (паритет веба).
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryMediaNorm;

  @override
  State<MessageAttachments> createState() => _MessageAttachmentsState();
}

class _MessageAttachmentsState extends State<MessageAttachments> {
  ValueNotifier<String?>? _ownedCircleSlot;

  @override
  void initState() {
    super.initState();
    final hasCircle = widget.attachments.any((a) => isVideoCircleAttachment(a));
    if (hasCircle && widget.videoCirclePlayingSlotId == null) {
      _ownedCircleSlot = ValueNotifier<String?>(null);
    }
  }

  @override
  void dispose() {
    _ownedCircleSlot?.dispose();
    super.dispose();
  }

  ValueNotifier<String?> get _circleSlot =>
      widget.videoCirclePlayingSlotId ?? _ownedCircleSlot!;

  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    if (attachments.isEmpty) return const SizedBox.shrink();

    final alignRight = widget.alignRight;

    final images = <ChatAttachment>[];
    final videoLike = <({ChatAttachment attachment, int index})>[];
    final voices = <({ChatAttachment attachment, int index})>[];
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      if (_isVoiceAttachment(a)) {
        voices.add((attachment: a, index: i));
      } else if (_isVideoAttachment(a)) {
        videoLike.add((attachment: a, index: i));
      } else if (_isImageAttachment(a)) {
        images.add(a);
      }
    }
    final files = attachments
        .where(
          (a) =>
              !_isImageAttachment(a) &&
              !_isVideoAttachment(a) &&
              !_isVoiceAttachment(a),
        )
        .toList(growable: false);
    final allGifGrid =
        images.isNotEmpty &&
        images.every((a) {
          final t = (a.type ?? '').toLowerCase();
          if (t == 'image/gif') return true;
          final path = a.url.split('?').first.toLowerCase();
          return path.endsWith('.gif');
        });
    final baseGridMax = allGifGrid
        ? ChatMediaLayoutTokens.gifAlbumGridMaxWidth
        : ChatMediaLayoutTokens.mediaGridMaxWidth;
    final gridMaxWidth = images.length > 1
        ? baseGridMax * ChatMediaLayoutTokens.mediaGridMosaicDisplayScale
        : baseGridMax;

    return LayoutBuilder(
      builder: (context, constraints) {
        final onlyOneVideo =
            videoLike.length == 1 && images.isEmpty && voices.isEmpty;
        final v0 = onlyOneVideo ? videoLike.first.attachment : null;
        final vw = v0?.width;
        final vh = v0?.height;
        final isLandscape =
            vw != null && vh != null && vw > 0 && vh > 0 && vw >= vh * 1.02;
        final videoScale = onlyOneVideo && isLandscape ? 1.125 : 1.5;
        final width = _attachmentsColumnWidth(
          available: constraints.maxWidth,
          // Видео в ленте хотим крупнее: поднимаем "cap" колонки, но только
          // когда показываем именно видео (без сетки картинок).
          gridMaxWidth: (videoLike.isNotEmpty && images.isEmpty)
              ? (gridMaxWidth * videoScale)
              : gridMaxWidth,
          images: images,
        );
        return Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (images.isNotEmpty)
                  RepaintBoundary(
                    child: _ImageGrid(
                      images: images,
                      maxWidth: width,
                      alignRight: alignRight,
                      onOpenGridGallery: widget.onOpenGridGallery,
                      conversationId: widget.conversationId,
                      messageId: widget.messageId,
                    ),
                  ),
                if (voices.isNotEmpty) ...[
                  if (images.isNotEmpty)
                    const SizedBox(
                      height: ChatMediaLayoutTokens.mediaToMediaGap,
                    ),
                  ...voices.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: ChatMediaLayoutTokens.mediaToMediaGap,
                      ),
                      child: MessageVoiceAttachment(
                        attachment: v.attachment,
                        attachmentIndex: v.index,
                        alignRight: alignRight,
                        conversationId: widget.conversationId,
                        messageId: widget.messageId,
                        transcript: widget.voiceTranscript,
                        mediaNorm: widget.mediaNorm,
                        onRetryNorm: widget.onRetryMediaNorm,
                      ),
                    ),
                  ),
                ],
                if (videoLike.isNotEmpty)
                  RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: (images.isNotEmpty || voices.isNotEmpty)
                            ? ChatMediaLayoutTokens.mediaToMediaGap
                            : 0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var vi = 0; vi < videoLike.length; vi++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: vi < videoLike.length - 1
                                    ? ChatMediaLayoutTokens.mediaToMediaGap
                                    : 0,
                              ),
                              child: _videoOrCircle(
                                videoLike[vi].attachment,
                                videoIndex: vi,
                                attachmentIndex: videoLike[vi].index,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (files.isNotEmpty) ...[
                  const SizedBox(height: ChatMediaLayoutTokens.mediaToMediaGap),
                  ...files.map(
                    (f) => _isE2eeMediaDecryptErrorAttachment(f)
                        ? _E2eeMediaDecryptErrorRow(att: f)
                        : _FileRow(att: f),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _videoOrCircle(
    ChatAttachment v, {
    required int videoIndex,
    required int attachmentIndex,
  }) {
    if (isVideoCircleAttachment(v)) {
      final mid = widget.messageId ?? '_local';
      final slot = '${mid}_vc_$videoIndex';
      return MessageVideoCirclePlayer(
        attachment: v,
        attachmentIndex: attachmentIndex,
        playbackSlotId: slot,
        isMine: widget.isMine ?? widget.alignRight,
        createdAt: widget.messageCreatedAt ?? DateTime.now(),
        deliveryStatus: widget.deliveryStatus,
        readAt: widget.readAt,
        showTimestamps: widget.showTimestamps,
        playingSlotId: _circleSlot,
        mediaNorm: widget.mediaNorm,
        onRetryNorm: widget.onRetryMediaNorm,
      );
    }
    return MessageVideoAttachment(
      attachment: v,
      attachmentIndex: attachmentIndex,
      onOpenInGallery: widget.onOpenGridGallery == null
          ? null
          : () => widget.onOpenGridGallery!(v),
      mediaNorm: widget.mediaNorm,
      onRetryNorm: widget.onRetryMediaNorm,
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.maxWidth,
    required this.alignRight,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
  });

  final List<ChatAttachment> images;
  final double maxWidth;
  final bool alignRight;
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final String? conversationId;
  final String? messageId;

  static const double _gap = 2;
  static const int _maxCells = 9;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ChatMediaLayoutTokens.mediaCardRadius);
    final total = images.length;
    final displayCount = total > _maxCells ? _maxCells : total;
    final slice = images.take(displayCount).toList(growable: false);
    final extraBeyond = total > displayCount ? total - displayCount : 0;
    final lastIdx = displayCount - 1;

    if (slice.length == 1) {
      return _SingleVisualAttachment(
        attachment: slice.first,
        maxWidth: maxWidth,
        borderRadius: radius,
        onOpenGridGallery: onOpenGridGallery,
        conversationId: conversationId,
        messageId: messageId,
      );
    }

    Widget tile(int sliceIndex) {
      final a = slice[sliceIndex];
      final showPlus = extraBeyond > 0 && sliceIndex == lastIdx;
      Widget inner = Stack(
        fit: StackFit.expand,
        children: [
          SecretChatMediaOpenService.isLockedSecretAttachment(a)
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                )
              : ChatCachedNetworkImage(url: a.url, fit: BoxFit.cover),
          if (showPlus)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Text(
                '+$extraBeyond',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      );
      if (onOpenGridGallery != null && isChatGridGalleryAttachment(a)) {
        inner = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpenGridGallery!(a),
          child: inner,
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: inner,
      );
    }

    Widget alignRow(Widget row) {
      return Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: row,
      );
    }

    Widget twoImageRow() {
      final r0 = mosaicAttachmentAspectRatio(slice[0]);
      final r1 = mosaicAttachmentAspectRatio(slice[1]);
      final s = mosaicTwoImageSizes(
        maxWidth: maxWidth,
        r0: r0,
        r1: r1,
        gap: _gap,
      );
      return SizedBox(
        height: s.height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: s.w0, height: s.height, child: tile(0)),
            SizedBox(width: _gap),
            SizedBox(width: s.w1, height: s.height, child: tile(1)),
          ],
        ),
      );
    }

    Widget equalRow(List<int> indices) {
      final ratios = indices
          .map((i) => mosaicAttachmentAspectRatio(slice[i]))
          .toList();
      final h = mosaicEqualCellRowHeight(
        rowMaxWidth: maxWidth,
        cellCount: indices.length,
        aspectRatios: ratios,
        gap: _gap,
      );
      return SizedBox(
        height: h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < indices.length; j++) ...[
              if (j > 0) SizedBox(width: _gap),
              Expanded(child: tile(indices[j])),
            ],
          ],
        ),
      );
    }

    Widget oneFullWidth(int index) {
      final r = mosaicAttachmentAspectRatio(slice[index]);
      final h = mosaicFullWidthRowHeight(maxWidth: maxWidth, aspectRatio: r);
      return SizedBox(width: maxWidth, height: h, child: tile(index));
    }

    final List<Widget> colChildren;
    if (slice.length == 2) {
      colChildren = [alignRow(twoImageRow())];
    } else if (slice.length == 3) {
      colChildren = [
        oneFullWidth(0),
        SizedBox(height: _gap),
        equalRow(const [1, 2]),
      ];
    } else {
      final rows = mosaicRowIndices(displayCount);
      colChildren = [];
      for (var ri = 0; ri < rows.length; ri++) {
        if (ri > 0) colChildren.add(SizedBox(height: _gap));
        colChildren.add(equalRow(rows[ri]));
      }
    }

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: colChildren,
        ),
      ),
    );
  }
}

/// Одно фото / стикер / GIF: реальное соотношение сторон, без принудительного квадрата сетки.
class _SingleVisualAttachment extends StatelessWidget {
  const _SingleVisualAttachment({
    required this.attachment,
    required this.maxWidth,
    required this.borderRadius,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
  });

  final ChatAttachment attachment;
  final double maxWidth;
  final BorderRadius borderRadius;
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final String? conversationId;
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    if (_isStickerAttachment(a)) {
      final maxSide = (200.0).clamp(96.0, maxWidth);
      final w = a.width;
      final h = a.height;
      double boxW, boxH;
      if (w != null && h != null && w > 0 && h > 0) {
        final aspect = w / h;
        if (aspect >= 1) {
          boxW = maxSide;
          boxH = maxSide / aspect;
        } else {
          boxH = maxSide;
          boxW = maxSide * aspect;
        }
      } else {
        boxW = maxSide;
        boxH = maxSide;
      }
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: SizedBox(
          width: boxW,
          height: boxH,
          child: ChatCachedNetworkImage(
            url: a.url,
            fit: BoxFit.contain,
            conversationId: conversationId,
            messageId: messageId,
            attachmentName: a.name,
          ),
        ),
      );
    }

    if (_isGifInlineAttachment(a)) {
      final capW = maxWidth < 280 ? maxWidth : 280.0;
      return _AspectImageBox(
        attachment: a,
        maxWidth: capW,
        maxHeight: 320,
        minHeight: 96,
        borderRadius: borderRadius,
        onOpenGridGallery: onOpenGridGallery,
        conversationId: conversationId,
        messageId: messageId,
      );
    }

    return _AspectImageBox(
      attachment: a,
      maxWidth: maxWidth,
      maxHeight: 440,
      minHeight: 72,
      borderRadius: borderRadius,
      onOpenGridGallery: onOpenGridGallery,
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}

class _AspectImageBox extends StatelessWidget {
  const _AspectImageBox({
    required this.attachment,
    required this.maxWidth,
    required this.maxHeight,
    required this.minHeight,
    required this.borderRadius,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
  });

  final ChatAttachment attachment;
  final double maxWidth;
  final double maxHeight;
  final double minHeight;
  final BorderRadius borderRadius;
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final String? conversationId;
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final w = attachment.width;
    final h = attachment.height;
    final hasExplicitSize = w != null && h != null && w > 0 && h > 0;
    final isLandscape = hasExplicitSize && w >= h * 1.02;
    final capW = isLandscape
        ? maxWidth * ChatMediaLayoutTokens.horizontalAttachmentDisplayScale
        : maxWidth;
    var boxW = capW;
    double boxH;
    if (w != null && h != null && w > 0 && h > 0) {
      boxH = boxW * h / w;
      if (boxH > maxHeight) {
        boxH = maxHeight;
        boxW = boxH * w / h;
      }
      if (boxH < minHeight) {
        boxH = minHeight;
      }
      if (boxW > capW) {
        boxW = capW;
        boxH = boxW * h / w;
        if (boxH > maxHeight) {
          boxH = maxHeight;
          boxW = boxH * w / h;
        }
      }
    } else {
      boxH = (boxW * 4 / 3).clamp(minHeight, maxHeight);
    }

    final img = ChatCachedNetworkImage(
      url: attachment.url,
      // Для вложений без width/height (часто E2EE decrypt-path) `contain`
      // даёт "внутренний прямоугольник" с острыми углами. Используем `cover`,
      // чтобы визуально сохранять rounded-card как у обычных медиа.
      fit: hasExplicitSize
          ? (isLandscape ? BoxFit.cover : BoxFit.contain)
          : BoxFit.cover,
      alignment: Alignment.center,
      conversationId: conversationId,
      messageId: messageId,
      attachmentName: attachment.name,
    );
    final maybeLocked = SecretChatMediaOpenService.isLockedSecretAttachment(
      attachment,
    );
    final lockedWidget = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
      ),
      child: const Center(
        child: Icon(
          Icons.lock_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
    final open = onOpenGridGallery;
    final child = maybeLocked ? lockedWidget : img;
    final wrapped = open != null && isChatGridGalleryAttachment(attachment)
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => open(attachment),
            child: child,
          )
        : child;
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(width: boxW, height: boxH, child: wrapped),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.06 : 0.18,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.30,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                att.name.isNotEmpty ? att.name : att.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _E2eeMediaDecryptErrorRow extends StatelessWidget {
  const _E2eeMediaDecryptErrorRow({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = att.name.trim().isNotEmpty
        ? att.name.trim()
        : 'Не удалось расшифровать вложение';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: scheme.errorContainer.withValues(alpha: 0.35),
          border: Border.all(color: scheme.error.withValues(alpha: 0.45)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onErrorContainer.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
