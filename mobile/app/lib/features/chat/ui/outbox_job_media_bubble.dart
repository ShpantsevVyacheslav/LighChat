import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/chat_attachment_mosaic_layout.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/chat_outbox_attachment_notifier.dart';
import 'message_html_text.dart';
import 'outgoing_pending_media_album.dart'
    show isOutgoingAlbumLocalImage, isOutgoingAlbumLocalVideo;
import 'video_first_frame.dart';

/// Локальное превью исходящего сообщения с вложениями, пока работает
/// `ChatOutboxAttachmentNotifier`. Рендерит мозаику из `stagedAbsolutePaths`
/// с прогресс-оверлеем поверх каждого тайла и опциональной подписью под медиа.
/// Заменяет fallback-пузырь со словом «Вложение» на привычное Telegram-подобное
/// превью; работает для любых типов файлов (картинки/видео/документы).
class OutboxJobMediaBubble extends ConsumerStatefulWidget {
  const OutboxJobMediaBubble({
    super.key,
    required this.jobId,
    required this.isMine,
    this.outgoingBubbleColor,
  });

  final String jobId;
  final bool isMine;
  final Color? outgoingBubbleColor;

  @override
  ConsumerState<OutboxJobMediaBubble> createState() =>
      _OutboxJobMediaBubbleState();
}

class _OutboxJobMediaBubbleState extends ConsumerState<OutboxJobMediaBubble> {
  static const double _gap = 2;
  static const int _maxCells = 9;

  late List<double> _aspects;
  List<String>? _aspectsForPaths;

  @override
  void initState() {
    super.initState();
    _aspects = const <double>[];
    unawaited(_primeAspects());
  }

  Future<void> _primeAspects() async {
    final job = _currentJob();
    if (job == null) return;
    final paths = job.stagedAbsolutePaths;
    final next = List<double>.filled(paths.length, 1.0);
    for (var i = 0; i < paths.length; i++) {
      final p = paths[i];
      final f = XFile(p);
      if (!isOutgoingAlbumLocalImage(f) && !isOutgoingAlbumLocalVideo(f)) {
        continue;
      }
      try {
        final bytes = await File(p).readAsBytes();
        final asp = await _decodeAspect(bytes);
        if (asp != null) next[i] = asp;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _aspects = next;
      _aspectsForPaths = List<String>.from(paths);
    });
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

  OutboxAttachmentJob? _currentJob() {
    final jobs = ref.read(chatOutboxAttachmentNotifierProvider);
    for (final j in jobs) {
      if (j.id == widget.jobId) return j;
    }
    return null;
  }

  double _ar(int i) {
    if (i >= _aspects.length) return 1.0;
    return _aspects[i].clamp(0.28, 3.5);
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(
      chatOutboxAttachmentNotifierProvider.select((jobs) {
        for (final j in jobs) {
          if (j.id == widget.jobId) return j;
        }
        return null;
      }),
    );
    if (job == null) return const SizedBox.shrink();

    // Список staged может в теории прийти позднее аспектов (job state переезжает
    // между фазами без изменения путей, но защитимся на случай мутации).
    if (_aspectsForPaths == null ||
        !_pathsListEqual(_aspectsForPaths!, job.stagedAbsolutePaths)) {
      if (_aspects.length != job.stagedAbsolutePaths.length) {
        _aspects = List<double>.filled(job.stagedAbsolutePaths.length, 1.0);
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = widget.outgoingBubbleColor ??
        scheme.primary.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.28,
        );
    final paths = job.stagedAbsolutePaths;
    final total = paths.length;
    if (total == 0) return const SizedBox.shrink();
    final baseGrid = ChatMediaLayoutTokens.mediaGridMaxWidth;
    final maxW = total > 1
        ? baseGrid * ChatMediaLayoutTokens.mediaGridMosaicDisplayScale
        : baseGrid;
    final displayCount = total > _maxCells ? _maxCells : total;
    final slice = paths.take(displayCount).toList(growable: false);
    final extraBeyond = total > _maxCells ? total - _maxCells : 0;
    final lastIdx = displayCount - 1;
    final captionPlain = messageHtmlToPlainText(job.captionHtml).trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
              widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
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
                  job: job,
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
        if (captionPlain.isNotEmpty) ...[
          const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
          Container(
            constraints: BoxConstraints(maxWidth: maxW),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: bubbleColor,
              border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
            ),
            child: _captionBody(
              caption: job.captionHtml,
              fallbackText: captionPlain,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _captionBody({
    required String caption,
    required String fallbackText,
    required Color color,
  }) {
    final base = TextStyle(
      color: color,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    if (!caption.contains('<')) {
      return Text(fallbackText, style: base);
    }
    return RichText(
      text: TextSpan(
        style: base,
        children: messageHtmlToStyledSpans(caption, base: base),
      ),
    );
  }

  Widget _buildMosaic({
    required BuildContext context,
    required OutboxAttachmentJob job,
    required List<String> slice,
    required int displayCount,
    required int extraBeyond,
    required int lastIdx,
    required double maxWidth,
  }) {
    if (displayCount == 1) {
      return _singleTile(job, slice[0], 0, maxWidth);
    }

    Widget tile(int idx) {
      final showPlus = extraBeyond > 0 && idx == lastIdx;
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _tileContent(slice[idx], BoxFit.cover),
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
            _progressOverlay(job, idx),
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
      return SizedBox(width: maxWidth, height: h, child: tile(index));
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

  Widget _singleTile(
    OutboxAttachmentJob job,
    String path,
    int index,
    double maxWidth,
  ) {
    final f = XFile(path);
    final isImage = isOutgoingAlbumLocalImage(f);
    final isVideo = !isImage && isOutgoingAlbumLocalVideo(f);
    if (!isImage && !isVideo) {
      return _documentCard(job, path, index, maxWidth);
    }
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
      borderRadius: BorderRadius.circular(
        ChatMediaLayoutTokens.mediaCardRadius,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(
        width: boxW,
        height: boxH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _tileContent(path, isLandscape ? BoxFit.cover : BoxFit.contain),
            _progressOverlay(job, index),
          ],
        ),
      ),
    );
  }

  Widget _tileContent(String path, BoxFit fit) {
    final f = XFile(path);
    final isImage = isOutgoingAlbumLocalImage(f);
    final isVideo = !isImage && isOutgoingAlbumLocalVideo(f);
    if (isVideo) {
      return VideoFirstFrame(
        file: File(path),
        fit: fit,
        placeholder: ColoredBox(color: Colors.grey.shade900),
      );
    }
    if (isImage) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, _, _) => ColoredBox(color: Colors.grey.shade900),
      );
    }
    // Документы/аудио в mosaic-режиме — без миниатюры, иконкой по центру.
    return _DocumentTilePlaceholder(path: path);
  }

  Widget _documentCard(
    OutboxAttachmentJob job,
    String path,
    int index,
    double maxWidth,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: 64),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(
            ChatMediaLayoutTokens.mediaCardRadius,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file_rounded,
                    size: 36,
                    color: Colors.white70,
                  ),
                  _progressRing(job, index, size: 44),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _displayName(path),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(String path) {
    final basename = path.split('/').last;
    // Staged-файлы в очереди обычно префиксируются `${i}_` (см. _stageFilesForJob),
    // отрежем индекс, чтобы имя в пузыре выглядело как оригинальное.
    final m = RegExp(r'^\d+_').firstMatch(basename);
    if (m != null) return basename.substring(m.end);
    return basename;
  }

  Widget _progressOverlay(OutboxAttachmentJob job, int index) {
    final failed = job.phase == OutboxAttachmentPhase.failed;
    final progress =
        index < job.uploadProgress.length ? job.uploadProgress[index] : 0.0;
    final done = !failed && progress >= 0.999;
    if (done) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
          Center(
            child: failed
                ? const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 32,
                  )
                : InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _cancelJobInFlight(job),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress > 0.001 && progress < 1.0
                                  ? progress
                                  : null,
                              strokeWidth: 2.5,
                              color: Colors.white,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                            ),
                            const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _cancelJobInFlight(OutboxAttachmentJob job) {
    // Активный аплоад → отменяем (Firebase UploadTask.cancel внутри нотифайера).
    // Failed → бабл по тапу не отменяем — там UI ретрая/dismiss отрабатывает
    // в _ChatMessageBubble через outbox-меню.
    ref
        .read(chatOutboxAttachmentNotifierProvider.notifier)
        .requestCancelInFlight(job.id);
  }

  Widget _progressRing(
    OutboxAttachmentJob job,
    int index, {
    required double size,
  }) {
    final failed = job.phase == OutboxAttachmentPhase.failed;
    final progress =
        index < job.uploadProgress.length ? job.uploadProgress[index] : 0.0;
    final done = !failed && progress >= 0.999;
    if (done) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: failed
          ? const Icon(Icons.error_rounded, color: Colors.redAccent)
          : CircularProgressIndicator(
              value: progress > 0.001 && progress < 1.0 ? progress : null,
              strokeWidth: 2.5,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
            ),
    );
  }

  bool _pathsListEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _DocumentTilePlaceholder extends StatelessWidget {
  const _DocumentTilePlaceholder({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      alignment: Alignment.center,
      child: const Icon(
        Icons.insert_drive_file_rounded,
        color: Colors.white70,
        size: 32,
      ),
    );
  }
}
