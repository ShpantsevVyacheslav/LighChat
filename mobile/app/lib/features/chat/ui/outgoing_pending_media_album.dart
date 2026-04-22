import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_attachment_mosaic_layout.dart';
import '../data/chat_attachment_upload.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/e2ee_attachment_send_helper.dart';
import '../data/e2ee_runtime.dart';
import 'message_html_text.dart';
import 'message_reply_preview.dart';
import 'video_first_frame.dart';

/// E2EE v2 Phase 9: контекст шифрования для альбома. Если задан — widget
/// шифрует каждое вложение через `prepareE2eeAttachmentsForSend` и кладёт
/// envelope'ы в `e2ee.attachments[]`. Если `null` — plaintext-путь как раньше.
class OutgoingAlbumE2eeContext {
  const OutgoingAlbumE2eeContext({
    required this.runtime,
    required this.epoch,
    required this.messageId,
  });

  final MobileE2eeRuntime runtime;
  final int epoch;
  final String messageId;
}

/// Совпадает с эвристикой превью в `ComposerPendingAttachmentsStrip`.
Widget _captionBody({
  required String caption,
  required Color color,
}) {
  final base = TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  if (!caption.contains('<')) {
    return Text(caption, style: base);
  }
  return RichText(
    text: TextSpan(
      style: base,
      children: messageHtmlToStyledSpans(caption, base: base),
    ),
  );
}

bool isOutgoingAlbumLocalImage(XFile f) {
  final m = (f.mimeType ?? '').toLowerCase();
  if (m.startsWith('image/')) return true;
  final p = f.path.toLowerCase();
  return p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.png') ||
      p.endsWith('.gif') ||
      p.endsWith('.webp') ||
      p.endsWith('.heic');
}

bool _isOutgoingAlbumLocalVideo(XFile f) {
  final m = (f.mimeType ?? '').toLowerCase();
  if (m.startsWith('video/')) return true;
  final p = f.path.toLowerCase();
  return p.endsWith('.mp4') ||
      p.endsWith('.mov') ||
      p.endsWith('.webm') ||
      p.endsWith('.m4v') ||
      p.endsWith('.3gp');
}

/// Исходящий альбом в ленте во время загрузки (паритет Telegram: превью + круговой прогресс).
class OutgoingPendingMediaAlbum extends StatefulWidget {
  const OutgoingPendingMediaAlbum({
    super.key,
    required this.files,
    required this.captionText,
    this.replyTo,
    required this.conversationId,
    required this.senderId,
    required this.repo,
    required this.isMine,
    this.outgoingBubbleColor,
    required this.onFinished,
    required this.onFailed,
    this.e2eeContext,
  });

  final List<XFile> files;
  final String captionText;
  final ReplyContext? replyTo;
  final String conversationId;
  final String senderId;
  final ChatRepository repo;
  final bool isMine;
  final Color? outgoingBubbleColor;
  final VoidCallback onFinished;
  final void Function(Object error) onFailed;
  final OutgoingAlbumE2eeContext? e2eeContext;

  @override
  State<OutgoingPendingMediaAlbum> createState() =>
      _OutgoingPendingMediaAlbumState();
}

class _OutgoingPendingMediaAlbumState extends State<OutgoingPendingMediaAlbum> {
  static const double _gap = 2;
  static const int _maxCells = 9;

  late List<double> _aspects;
  late List<double> _progress;
  late List<bool> _skipped;
  late List<UploadTask?> _tasks;
  bool _pipelineStarted = false;

  @override
  void initState() {
    super.initState();
    final n = widget.files.length;
    _aspects = List<double>.filled(n, 1.0);
    _progress = List<double>.filled(n, 0.0);
    _skipped = List<bool>.filled(n, false);
    _tasks = List<UploadTask?>.filled(n, null);
    unawaited(_primeAspectsAndUpload());
  }

  Future<void> _primeAspectsAndUpload() async {
    final n = widget.files.length;
    if (n == 0) {
      widget.onFinished();
      return;
    }
    if (mounted) setState(() => _pipelineStarted = true);
    try {
      final storage = FirebaseStorage.instance;
      final attachments = List<ChatAttachment?>.filled(n, null);
      // E2EE v2 Phase 9: параллельный массив envelope'ов для encryptable файлов.
      // Слот остаётся null, если файл ушёл plaintext (стикеры/GIFs/не-E2EE чат).
      final e2eeEnvelopes = List<Map<String, Object?>?>.filled(n, null);
      final e2eeCtx = widget.e2eeContext;
      await Future.wait(
        List.generate(n, (i) async {
          if (_skipped[i]) return;
          try {
            final bytes = await widget.files[i].readAsBytes();
            final asp = await _decodeAspect(bytes);
            if (mounted && asp != null) {
              setState(() => _aspects[i] = asp);
            }
            if (!mounted) return;

            final mime = _effectiveMime(widget.files[i]);
            final shouldEncrypt =
                e2eeCtx != null && isEncryptableMimeV2(mime);

            if (shouldEncrypt) {
              // Прогресс у encryptMediaForSend не трекается гранулярно —
              // отображаем бесконечный-стиль (0 → 1 по факту завершения).
              try {
                final envelope = await e2eeCtx.runtime.encryptMediaForSend(
                  storage: storage,
                  conversationId: widget.conversationId,
                  messageId: e2eeCtx.messageId,
                  epoch: e2eeCtx.epoch,
                  data: bytes,
                  mime: mime,
                );
                if (!mounted) return;
                e2eeEnvelopes[i] = envelope.toWireJson();
                setState(() => _progress[i] = 1.0);
              } on MobileE2eeEncryptException {
                rethrow;
              }
              return;
            }

            final name = widget.files[i].name.isNotEmpty
                ? widget.files[i].name
                : widget.files[i].path.split('/').last;
            final att = await uploadChatAttachmentBytesWithProgress(
              storage: storage,
              conversationId: widget.conversationId,
              bytes: bytes,
              pathUniqueSegment: 'p$i',
              displayName: name,
              mimeType: widget.files[i].mimeType,
              onProgress: (p) {
                if (mounted) setState(() => _progress[i] = p);
              },
              onTaskCreated: (t) {
                if (mounted) _tasks[i] = t;
              },
            );
            if (mounted) attachments[i] = att;
          } catch (e) {
            if (e is FirebaseException &&
                (e.code == 'canceled' || e.code == 'cancelled')) {
              return;
            }
            rethrow;
          }
        }),
      );
      if (!mounted) return;
      final uploaded = <ChatAttachment>[];
      final envelopesOut = <Map<String, Object?>>[];
      for (var i = 0; i < n; i++) {
        if (_skipped[i]) continue;
        if (attachments[i] != null) uploaded.add(attachments[i]!);
        if (e2eeEnvelopes[i] != null) envelopesOut.add(e2eeEnvelopes[i]!);
      }
      if (uploaded.isEmpty && envelopesOut.isEmpty) {
        if (mounted) widget.onFinished();
        return;
      }

      Map<String, Object?>? outgoingEnvelope;
      if (e2eeCtx != null) {
        // Всегда шифруем caption (в т.ч. пустую строку), чтобы iv/ciphertext
        // были непустыми и приёмник распознал `message.e2ee` как v2.
        final textEnvelope = await e2eeCtx.runtime.encryptOutgoing(
          conversationId: widget.conversationId,
          messageId: e2eeCtx.messageId,
          epoch: e2eeCtx.epoch,
          plaintext: widget.captionText,
        );
        outgoingEnvelope = mergeE2eeEnvelopeWithMedia(
          textEnvelope: textEnvelope,
          mediaEnvelopes: envelopesOut,
          epoch: e2eeCtx.epoch,
        );
      }

      await widget.repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        text: outgoingEnvelope != null ? '' : widget.captionText,
        replyTo: widget.replyTo,
        attachments: uploaded,
        e2eeEnvelope: outgoingEnvelope,
        messageIdOverride: e2eeCtx?.messageId,
      );
      if (mounted) widget.onFinished();
    } catch (e) {
      if (mounted) widget.onFailed(e);
    }
  }

  String _effectiveMime(XFile f) {
    final m = (f.mimeType ?? '').trim();
    if (m.isNotEmpty) return m.toLowerCase();
    final p = f.path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    if (p.endsWith('.gif')) return 'image/gif';
    if (p.endsWith('.mp4')) return 'video/mp4';
    if (p.endsWith('.mov') || p.endsWith('.qt')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  Future<double?> _decodeAspect(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      if (w <= 0 || h <= 0) return null;
      return (w / h).clamp(0.28, 3.5);
    } catch (_) {
      return null;
    }
  }

  void _cancelTile(int i) {
    _tasks[i]?.cancel();
    setState(() {
      _skipped[i] = true;
      _progress[i] = 0;
    });
  }

  double _ar(int i) => _aspects[i].clamp(0.28, 3.5);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = widget.outgoingBubbleColor ??
        scheme.primary.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.28,
        );
    final total = widget.files.length;
    if (total == 0) return const SizedBox.shrink();
    final baseGrid = ChatMediaLayoutTokens.mediaGridMaxWidth;
    final maxW = total > 1
        ? baseGrid * ChatMediaLayoutTokens.mediaGridMosaicDisplayScale
        : baseGrid;
    final displayCount = total > _maxCells ? _maxCells : total;
    final slice = widget.files.take(displayCount).toList(growable: false);
    final extraBeyond =
        total > _maxCells ? total - _maxCells : 0;
    final lastIdx = displayCount - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.replyTo != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: ChatMediaLayoutTokens.replyPreviewToBodyGap,
            ),
            child: MessageReplyPreview(
              replyTo: widget.replyTo!,
              isMine: widget.isMine,
              onOpenOriginal: null,
            ),
          ),
        Align(
          alignment: widget.isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ChatMediaLayoutTokens.mediaCardRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: maxW,
                child: _buildMosaic(
                  context: context,
                  slice: slice,
                  displayCount: displayCount,
                  extraBeyond: extraBeyond,
                  lastIdx: lastIdx,
                  maxWidth: maxW,
                ),
              ),
            ),
          ),
        ),
        if (widget.captionText.trim().isNotEmpty) ...[
          const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
          Container(
            constraints: BoxConstraints(maxWidth: maxW),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: bubbleColor,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: _captionBody(
              caption: widget.captionText.trim(),
              color: scheme.onPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMosaic({
    required BuildContext context,
    required List<XFile> slice,
    required int displayCount,
    required int extraBeyond,
    required int lastIdx,
    required double maxWidth,
  }) {
    if (displayCount == 1) {
      return _singleTile(slice[0], 0, maxWidth);
    }

    Widget tile(int idx) {
      final showPlus = extraBeyond > 0 && idx == lastIdx;
      final f = slice[idx];
      final isVideo = _isOutgoingAlbumLocalVideo(f) && !isOutgoingAlbumLocalImage(f);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            isVideo
                ? VideoFirstFrame(
                    file: File(f.path),
                    fit: BoxFit.cover,
                    placeholder: ColoredBox(color: Colors.grey.shade900),
                  )
                : Image.file(
                    File(f.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: Colors.grey.shade900,
                    ),
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
            _progressOverlay(idx),
          ],
        ),
      );
    }

    Widget twoImageRow() {
      final r0 = _ar(0);
      final r1 = _ar(1);
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
      final ratios = indices.map((i) => _ar(i)).toList();
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
      final r = _ar(index);
      final h = mosaicFullWidthRowHeight(maxWidth: maxWidth, aspectRatio: r);
      return SizedBox(
        width: maxWidth,
        height: h,
        child: tile(index),
      );
    }

    final List<Widget> colChildren;
    if (displayCount == 2) {
      colChildren = [twoImageRow()];
    } else if (displayCount == 3) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: colChildren,
    );
  }

  Widget _singleTile(XFile file, int index, double maxWidth) {
    final r = _ar(index);
    final isLandscape = r >= 1.02;
    final capW = isLandscape
        ? maxWidth * ChatMediaLayoutTokens.horizontalAttachmentDisplayScale
        : maxWidth;
    var boxW = capW;
    double boxH = boxW / r;
    const maxH = 440.0;
    const minH = 72.0;
    if (boxH > maxH) {
      boxH = maxH;
      boxW = boxH * r;
    }
    if (boxH < minH) boxH = minH;
    if (boxW > capW) {
      boxW = capW;
      boxH = boxW / r;
      if (boxH > maxH) {
        boxH = maxH;
        boxW = boxH * r;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(ChatMediaLayoutTokens.mediaCardRadius),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(
        width: boxW,
        height: boxH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            (_isOutgoingAlbumLocalVideo(file) && !isOutgoingAlbumLocalImage(file))
                ? VideoFirstFrame(
                    file: File(file.path),
                    fit: isLandscape ? BoxFit.cover : BoxFit.contain,
                    placeholder: ColoredBox(color: Colors.grey.shade900),
                  )
                : Image.file(
                    File(file.path),
                    fit: isLandscape ? BoxFit.cover : BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: Colors.grey.shade900),
                  ),
            _progressOverlay(index),
          ],
        ),
      ),
    );
  }

  Widget _progressOverlay(int index) {
    if (_skipped[index]) {
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: const Icon(Icons.block_rounded, color: Colors.white54, size: 32),
      );
    }
    final p = _progress[index];
    final busy = p < 1.0 || !_pipelineStarted;
    if (!busy) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.42),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: p > 0.001 && p < 1.0 ? p : null,
                          strokeWidth: 2.5,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _cancelTile(index),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
