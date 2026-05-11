import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_image_cache_manager.dart';
import 'chat_cached_network_image.dart';

/// Фото в полноэкранной галерее: pinch-zoom, двойной тап.
///
/// `InteractiveViewer` по умолчанию клампит панорамирование по размеру child-а
/// (экрану). Поскольку реальное изображение из-за `BoxFit.contain` занимает
/// только часть child-а, без дополнительного клампа можно утащить «letterbox-
/// поля» к краю экрана и увидеть пустоту. Поэтому отключаем встроенный кламп
/// (`boundaryMargin: infinity`) и считаем границы по реально отрисованному
/// прямоугольнику изображения — край картинки всегда прилеплен к краю экрана
/// при scale > 1, а при scale = 1 содержимое строго отцентровано.
class ChatMediaViewerPhotoPage extends StatefulWidget {
  const ChatMediaViewerPhotoPage({
    super.key,
    required this.url,
    required this.transformationController,
    this.showEdgeNavigation = true,
    this.canGoPrev = false,
    this.canGoNext = false,
    this.onGoPrev,
    this.onGoNext,
  });

  final String url;
  final TransformationController transformationController;

  /// Левый/правый тап для листания — только без зума.
  final bool showEdgeNavigation;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback? onGoPrev;
  final VoidCallback? onGoNext;

  @override
  State<ChatMediaViewerPhotoPage> createState() =>
      _ChatMediaViewerPhotoPageState();
}

class _ChatMediaViewerPhotoPageState extends State<ChatMediaViewerPhotoPage>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.75;
  static const double _tapStripeFraction = 0.22;
  static const double _zoomedThreshold = 1.01;

  Size? _imageSize;
  Size _viewport = Size.zero;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  late final AnimationController _zoomAnim;
  VoidCallback? _zoomTickListener;

  bool _clamping = false;

  @override
  void initState() {
    super.initState();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    widget.transformationController.addListener(_onMatrixChanged);
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant ChatMediaViewerPhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(_onMatrixChanged);
      widget.transformationController.addListener(_onMatrixChanged);
    }
    if (oldWidget.url != widget.url) {
      _imageSize = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    _disposeStream();
    final provider = _providerFor(widget.url);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w <= 0 || h <= 0) return;
        if (_imageSize == null ||
            _imageSize!.width != w ||
            _imageSize!.height != h) {
          setState(() => _imageSize = Size(w, h));
          _clampNow();
        }
      },
      onError: (_, _) {
        // Тихо игнорируем — ChatCachedNetworkImage сам отрисует ошибку.
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  ImageProvider _providerFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'file') {
      return FileImage(File(uri.toFilePath()));
    }
    return CachedNetworkImageProvider(
      url,
      cacheManager: ChatImageCacheManager(),
    );
  }

  void _disposeStream() {
    final s = _stream;
    final l = _listener;
    if (s != null && l != null) s.removeListener(l);
    _stream = null;
    _listener = null;
  }

  void _disposeAnimListener() {
    final l = _zoomTickListener;
    if (l != null) {
      _zoomAnim.removeListener(l);
      _zoomTickListener = null;
    }
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onMatrixChanged);
    _disposeStream();
    _disposeAnimListener();
    _zoomAnim.dispose();
    super.dispose();
  }

  /// Прямоугольник реального изображения внутри screen-sized child-а (scale=1).
  Rect _contentRect() {
    final v = _viewport;
    if (v.isEmpty) return Rect.zero;
    final src = _imageSize;
    if (src == null || src.isEmpty) return Offset.zero & v;
    final fit = applyBoxFit(BoxFit.contain, src, v);
    final dst = fit.destination;
    return Rect.fromLTWH(
      (v.width - dst.width) / 2,
      (v.height - dst.height) / 2,
      dst.width,
      dst.height,
    );
  }

  void _onMatrixChanged() {
    if (_clamping) return;
    _clampNow();
  }

  void _clampNow() {
    final v = _viewport;
    final content = _contentRect();
    if (v.isEmpty || content.isEmpty) return;
    final m = widget.transformationController.value;
    final scale = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final tx = t.x;
    final ty = t.y;

    final shownLeft = content.left * scale + tx;
    final shownTop = content.top * scale + ty;
    final shownW = content.width * scale;
    final shownH = content.height * scale;

    double newTx = tx;
    double newTy = ty;

    if (shownW <= v.width) {
      // Контент уже экрана по горизонтали — центрируем.
      newTx = (v.width - shownW) / 2 - content.left * scale;
    } else {
      // Контент шире экрана — край картинки не должен отрываться от края экрана.
      if (shownLeft > 0) {
        newTx = -content.left * scale;
      } else if (shownLeft + shownW < v.width) {
        newTx = v.width - shownW - content.left * scale;
      }
    }

    if (shownH <= v.height) {
      newTy = (v.height - shownH) / 2 - content.top * scale;
    } else {
      if (shownTop > 0) {
        newTy = -content.top * scale;
      } else if (shownTop + shownH < v.height) {
        newTy = v.height - shownH - content.top * scale;
      }
    }

    if ((newTx - tx).abs() < 0.001 && (newTy - ty).abs() < 0.001) return;

    final clamped = m.clone()..setTranslationRaw(newTx, newTy, t.z);
    _clamping = true;
    widget.transformationController.value = clamped;
    _clamping = false;
  }

  void _animateTo(Matrix4 target) {
    _disposeAnimListener();
    final begin = widget.transformationController.value;
    final anim = Matrix4Tween(begin: begin, end: target).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    void l() {
      // Во время анимации не даём клампу гнаться за каждым кадром.
      _clamping = true;
      widget.transformationController.value = anim.value;
      _clamping = false;
    }
    _zoomTickListener = l;
    _zoomAnim
      ..removeStatusListener(_onAnimStatus)
      ..addStatusListener(_onAnimStatus);
    _zoomAnim.addListener(l);
    _zoomAnim
      ..value = 0
      ..forward();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _disposeAnimListener();
      // На случай, если конечная позиция вышла за пределы.
      _clampNow();
    }
  }

  void _handleDoubleTap(TapDownDetails d) {
    final currentScale =
        widget.transformationController.value.getMaxScaleOnAxis();
    if (currentScale > _zoomedThreshold) {
      _animateTo(Matrix4.identity());
      return;
    }
    final focal = d.localPosition;
    final target = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1.0, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final v = Size(constraints.maxWidth, constraints.maxHeight);
        if (v != _viewport) {
          _viewport = v;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _clampNow();
          });
        }
        final stripe = v.width * _tapStripeFraction;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTapDown: _handleDoubleTap,
              onDoubleTap: () {},
              child: AnimatedBuilder(
                animation: widget.transformationController,
                builder: (context, _) {
                  final zoomed = widget.transformationController.value
                          .getMaxScaleOnAxis() >
                      _zoomedThreshold;
                  return InteractiveViewer(
                    transformationController: widget.transformationController,
                    minScale: 1,
                    maxScale: 5,
                    panEnabled: zoomed,
                    scaleEnabled: true,
                    clipBehavior: Clip.hardEdge,
                    // Кламп делаем сами — у IV он по размеру child-а (экрана),
                    // что включает letterbox-поля и приводит к зуму в пустоту.
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox(
                      width: v.width,
                      height: v.height,
                      child: ChatCachedNetworkImage(
                        url: widget.url,
                        fit: BoxFit.contain,
                        showProgressIndicator: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showEdgeNavigation && widget.canGoPrev)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onGoPrev,
                ),
              ),
            if (widget.showEdgeNavigation && widget.canGoNext)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onGoNext,
                ),
              ),
          ],
        );
      },
    );
  }
}
