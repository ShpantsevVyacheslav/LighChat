import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/data/energy_saving_preference.dart';
import '../data/chat_attachment_mosaic_layout.dart';
import '../data/chat_media_gallery.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/local_cache_entry_registry.dart';
import '../data/e2ee_decryption_orchestrator.dart'
    show e2eeMediaDecryptErrorMime;
import '../data/secret_chat_media_open_service.dart';
import '../data/video_circle_utils.dart';
import 'chat_cached_network_image.dart';
import 'chat_document_open.dart';
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

/// Анимированный эмодзи из GIPHY (`sticker_emoji_giphy_*`) — отдельный
/// визуальный класс: рендерится **без пузыря** (как обычный стикер), но
/// размером сравнимым с unicode-эмодзи (~76px).
///
/// Важно: `sticker_giphy_*` (без `_emoji_`) — это GIPHY-стикер из библиотеки,
/// он рендерится в обычном sticker-размере 200px и НЕ должен сюда попадать.
bool _isAnimatedEmojiAttachment(ChatAttachment a) {
  final name = a.name.toLowerCase();
  return name.startsWith('sticker_emoji_giphy_');
}

bool _isGifInlineAttachment(ChatAttachment a) {
  return a.name.toLowerCase().startsWith('gif_');
}

bool _isGifAttachment(ChatAttachment a) {
  final t = (a.type ?? '').toLowerCase();
  if (t == 'image/gif') return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.gif');
}

double _attachmentsColumnWidth({
  required double available,
  required double gridMaxWidth,
  required List<ChatAttachment> images,
}) {
  final base = clampMediaWidth(available: available, maxWidth: gridMaxWidth);
  if (images.length != 1) return base;
  final a = images.first;
  // Анимированный эмодзи: шринк-врап по реальному 76px размеру, чтобы
  // внешний `Row(mainAxisAlignment: end/start)` прижал его к краю экрана.
  if (_isAnimatedEmojiAttachment(a)) {
    return clampMediaWidth(available: available, maxWidth: 76);
  }
  // Обычный стикер: шринк-врап по 200px (тот же визуальный размер из
  // `_SingleVisualAttachment`), чтобы стикер прижимался к краю экрана,
  // а не висел внутри 208px-колонки.
  if (_isStickerAttachment(a)) {
    return clampMediaWidth(available: available, maxWidth: 200);
  }
  // Одиночный inline-GIF (`gif_*`): такой же шринк-врап по 280px (см.
  // `_SingleVisualAttachment` ветку GIF) — чтобы GIF прижимался к краю.
  if (_isGifInlineAttachment(a)) {
    return clampMediaWidth(available: available, maxWidth: 280);
  }
  if (!_isImageAttachment(a)) return base;
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

/// Реальная ширина колонки `MessageAttachments` для заданных вложений
/// и доступной ширины. Совпадает с `LayoutBuilder`-расчётом внутри `build`.
double computeMessageAttachmentsColumnWidth({
  required List<ChatAttachment> attachments,
  required double available,
}) {
  if (attachments.isEmpty) return 0;
  final images = <ChatAttachment>[];
  final videoLike = <ChatAttachment>[];
  final voices = <ChatAttachment>[];
  for (final a in attachments) {
    if (_isVoiceAttachment(a)) {
      voices.add(a);
    } else if (_isVideoAttachment(a)) {
      videoLike.add(a);
    } else if (_isImageAttachment(a)) {
      images.add(a);
    }
  }
  final allGifGrid =
      images.isNotEmpty &&
      images.every(_isGifAttachment);
  final baseGridMax = allGifGrid
      ? ChatMediaLayoutTokens.gifAlbumGridMaxWidth
      : ChatMediaLayoutTokens.mediaGridMaxWidth;
  final gridMaxWidth = images.length > 1
      ? baseGridMax * ChatMediaLayoutTokens.mediaGridMosaicDisplayScale
      : baseGridMax;
  final onlyOneVideo =
      videoLike.length == 1 && images.isEmpty && voices.isEmpty;
  final v0 = onlyOneVideo ? videoLike.first : null;
  final vw = v0?.width;
  final vh = v0?.height;
  final isLandscape =
      vw != null && vh != null && vw > 0 && vh > 0 && vw >= vh * 1.02;
  final videoScale = onlyOneVideo && isLandscape ? 1.125 : 1.5;
  return _attachmentsColumnWidth(
    available: available,
    gridMaxWidth: (videoLike.isNotEmpty && images.isEmpty)
        ? (gridMaxWidth * videoScale)
        : gridMaxWidth,
    images: images,
  );
}

class MessageAttachments extends ConsumerStatefulWidget {
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
    this.onOpenFileAttachment,
    this.mediaNorm,
    this.onRetryMediaNorm,
    this.clipSelf = true,
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
  final void Function(ChatAttachment attachment)? onOpenFileAttachment;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryMediaNorm;

  final bool clipSelf;

  @override
  ConsumerState<MessageAttachments> createState() => _MessageAttachmentsState();
}

class _MessageAttachmentsState extends ConsumerState<MessageAttachments> {
  ValueNotifier<String?>? _ownedCircleSlot;

  @override
  void initState() {
    super.initState();
    final hasCircle = widget.attachments.any((a) => isVideoCircleAttachment(a));
    if (hasCircle && widget.videoCirclePlayingSlotId == null) {
      _ownedCircleSlot = ValueNotifier<String?>(null);
    }
    _registerAttachmentsForStorageMapping();
  }

  @override
  void didUpdateWidget(covariant MessageAttachments oldWidget) {
    super.didUpdateWidget(oldWidget);
    final attachmentsChanged =
        oldWidget.attachments.length != widget.attachments.length ||
        oldWidget.conversationId != widget.conversationId ||
        oldWidget.messageId != widget.messageId;
    if (attachmentsChanged) {
      _registerAttachmentsForStorageMapping();
    }
  }

  /// Проактивно записываем `urlHash → conversationId/messageId` в
  /// [LocalCacheEntryRegistry] для каждого вложения. Тогда даже если файл
  /// будет закэширован через дефолтный `cached_network_image` или скачан
  /// без явного проброса контекста — экран «Хранилище» сможет сопоставить
  /// его с конкретным чатом.
  void _registerAttachmentsForStorageMapping() {
    final cid = widget.conversationId?.trim();
    if (cid == null || cid.isEmpty) return;
    final mid = widget.messageId;
    for (final a in widget.attachments) {
      final url = a.url.trim();
      if (url.isEmpty) continue;
      // Best-effort, не ждём результата.
      LocalCacheEntryRegistry.registerAttachmentContext(
        url: url,
        conversationId: cid,
        messageId: mid,
        attachmentName: a.name,
      );
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
    final energy = ref.watch(energySavingProvider);
    final allowGifAutoplay = energy.effectiveAutoplayGif;
    final allowAnimatedStickers = energy.effectiveAnimatedStickers;
    final allowAnimatedEmoji = energy.effectiveAnimatedEmoji;

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
        images.every(_isGifAttachment);
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
        final inner = SizedBox(
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
                    allowGifAutoplay: allowGifAutoplay,
                    allowAnimatedStickers: allowAnimatedStickers,
                    allowAnimatedEmoji: allowAnimatedEmoji,
                    onOpenGridGallery: widget.onOpenGridGallery,
                    conversationId: widget.conversationId,
                    messageId: widget.messageId,
                    clipSelf: widget.clipSelf,
                  ),
                ),
              if (voices.isNotEmpty) ...[
                if (images.isNotEmpty)
                  const SizedBox(height: ChatMediaLayoutTokens.mediaToMediaGap),
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
                      : _FileRow(
                          att: f,
                          onTap: widget.onOpenFileAttachment == null
                              ? null
                              : () => widget.onOpenFileAttachment!(f),
                        ),
                ),
              ],
            ],
          ),
        );
        if (!widget.clipSelf) return inner;
        return Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: inner,
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
        conversationId: widget.conversationId,
        messageId: widget.messageId,
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
      conversationId: widget.conversationId,
      messageId: widget.messageId,
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.maxWidth,
    required this.alignRight,
    required this.allowGifAutoplay,
    required this.allowAnimatedStickers,
    required this.allowAnimatedEmoji,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
    this.clipSelf = true,
  });

  final List<ChatAttachment> images;
  final double maxWidth;
  final bool alignRight;
  final bool allowGifAutoplay;
  final bool allowAnimatedStickers;
  final bool allowAnimatedEmoji;
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final String? conversationId;
  final String? messageId;
  final bool clipSelf;

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
        borderRadius: clipSelf ? radius : BorderRadius.zero,
        allowGifAutoplay: allowGifAutoplay,
        allowAnimatedStickers: allowAnimatedStickers,
        allowAnimatedEmoji: allowAnimatedEmoji,
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
              : TickerMode(
                  enabled: _tickerEnabledForAttachment(a),
                  child: ChatCachedNetworkImage(url: a.url, fit: BoxFit.cover),
                ),
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

    final content = SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: colChildren,
      ),
    );

    if (!clipSelf) return content;

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  bool _tickerEnabledForAttachment(ChatAttachment a) {
    if (_isAnimatedEmojiAttachment(a)) return allowAnimatedEmoji;
    if (_isStickerAttachment(a)) return allowAnimatedStickers;
    if (_isGifAttachment(a) || _isGifInlineAttachment(a)) {
      return allowGifAutoplay;
    }
    return true;
  }
}

/// Одно фото / стикер / GIF: реальное соотношение сторон, без принудительного квадрата сетки.
class _SingleVisualAttachment extends StatelessWidget {
  const _SingleVisualAttachment({
    required this.attachment,
    required this.maxWidth,
    required this.borderRadius,
    required this.allowGifAutoplay,
    required this.allowAnimatedStickers,
    required this.allowAnimatedEmoji,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
  });

  final ChatAttachment attachment;
  final double maxWidth;
  final BorderRadius borderRadius;
  final bool allowGifAutoplay;
  final bool allowAnimatedStickers;
  final bool allowAnimatedEmoji;
  final void Function(ChatAttachment attachment)? onOpenGridGallery;
  final String? conversationId;
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    // Анимированный эмодзи: маленький, как unicode-эмодзи (~76px),
    // а не как полноразмерный 200px-стикер. Проверяем ДО `_isStickerAttachment`,
    // т.к. имя начинается с `sticker_emoji_giphy_` и попадёт в общий sticker-ветку.
    if (_isAnimatedEmojiAttachment(a)) {
      const animEmojiSide = 76.0;
      final maxSide = animEmojiSide.clamp(48.0, maxWidth);
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
      // Без ClipRRect — анимированные эмодзи прозрачные, скруглять нечего.
      return SizedBox(
        width: boxW,
        height: boxH,
        child: TickerMode(
          enabled: allowAnimatedEmoji,
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
          child: TickerMode(
            enabled: allowAnimatedStickers,
            child: ChatCachedNetworkImage(
              url: a.url,
              fit: BoxFit.contain,
              conversationId: conversationId,
              messageId: messageId,
              attachmentName: a.name,
            ),
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
        allowAnimation: allowGifAutoplay,
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
      allowAnimation: true,
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
    required this.allowAnimation,
    this.onOpenGridGallery,
    this.conversationId,
    this.messageId,
  });

  final ChatAttachment attachment;
  final double maxWidth;
  final double maxHeight;
  final double minHeight;
  final BorderRadius borderRadius;
  final bool allowAnimation;
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

    final img = TickerMode(
      enabled: allowAnimation,
      child: ChatCachedNetworkImage(
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
      ),
    );
    final maybeLocked = SecretChatMediaOpenService.isLockedSecretAttachment(
      attachment,
    );
    final lockedWidget = DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.28)),
      child: const Center(
        child: Icon(Icons.lock_rounded, color: Colors.white, size: 32),
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
  const _FileRow({required this.att, this.onTap});

  final ChatAttachment att;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isChatDocumentPreviewCandidate(att)) {
      return _DocumentFileRow(att: att, onTap: onTap);
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
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
                if (onTap != null)
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentFileRow extends StatelessWidget {
  const _DocumentFileRow({required this.att, this.onTap});

  final ChatAttachment att;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final docType = _documentTypeLabel(att);
    final sizeLabel = _formatAttachmentSize(att.size);
    final subtitle = sizeLabel == null ? docType : '$docType · $sizeLabel';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
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
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DocumentThumbnail(att: att),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        att.name.isNotEmpty ? att.name : att.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FutureBuilder<String?>(
          future: buildChatDocumentThumbnailPath(
            att,
            logicalWidth: 64,
            logicalHeight: 64,
            devicePixelRatio: dpr,
          ),
          builder: (context, snap) {
            final path = snap.data;
            if (path == null || path.isEmpty) {
              return _DocumentThumbnailFallback(att: att);
            }
            return Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _DocumentThumbnailFallback(att: att),
            );
          },
        ),
      ),
    );
  }
}

class _DocumentThumbnailFallback extends StatelessWidget {
  const _DocumentThumbnailFallback({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = _documentTypeLabel(att);
    final icon = isChatPdfPreviewCandidate(att)
        ? Icons.picture_as_pdf_rounded
        : Icons.description_rounded;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.28),
            scheme.surfaceContainerHighest.withValues(alpha: 0.74),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              icon,
              size: 26,
              color: scheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _documentTypeLabel(ChatAttachment att) {
  final mime = (att.type ?? '').toLowerCase();
  if (mime == 'application/pdf') return 'PDF';
  if (mime.startsWith('text/')) return 'TXT';
  if (mime.contains('wordprocessingml')) {
    return 'DOCX';
  }
  if (mime.contains('msword')) {
    return 'DOC';
  }
  if (mime.contains('spreadsheetml')) {
    return 'XLSX';
  }
  if (mime.contains('ms-excel')) {
    return 'XLS';
  }
  if (mime.contains('presentationml')) {
    return 'PPTX';
  }
  if (mime.contains('powerpoint')) {
    return 'PPT';
  }
  if (mime.contains('rtf')) return 'RTF';

  final uri = Uri.tryParse(att.url.trim());
  final name = att.name.trim().toLowerCase();
  String ext = '';
  if (name.contains('.')) {
    ext = name.split('.').last;
  } else if (uri != null && uri.pathSegments.isNotEmpty) {
    final tail = uri.pathSegments.last.toLowerCase();
    if (tail.contains('.')) ext = tail.split('.').last;
  }
  ext = ext.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (ext.isEmpty) return 'DOC';
  if (ext.length > 4) return ext.substring(0, 4).toUpperCase();
  return ext.toUpperCase();
}

String? _formatAttachmentSize(int? bytes) {
  if (bytes == null || bytes <= 0) return null;
  final kb = bytes / 1024.0;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }
  return '${(kb / 1024.0).toStringAsFixed(1)} MB';
}

class _E2eeMediaDecryptErrorRow extends StatelessWidget {
  const _E2eeMediaDecryptErrorRow({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = att.name.trim().isNotEmpty
        ? att.name.trim()
        : AppLocalizations.of(context)!.chat_attachment_decrypt_error;
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
