import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_logger.dart';
import '../data/chat_image_cache_manager.dart';
import 'chat_cached_network_image.dart';
import 'chat_media_zoom_math.dart' as zoom_math;

/// Фото в полноэкранной галерее: pinch-zoom, двойной тап.
///
/// Особенности:
/// - Кламп считаем по реально отрисованному прямоугольнику изображения,
///   а не по размеру child-а `InteractiveViewer`-а (экрана). Иначе при зуме
///   letterbox-поля можно утащить к краю и увидеть пустоту.
/// - Пока палец на экране — за границей применяется rubber-band затухание
///   (iOS-style). На `onInteractionEnd` запускается spring-back к границе.
/// - Двойной тап ловится во внешнем `GestureDetector`, который не пересобирается
///   при изменении матрицы. Это критично: иначе `DoubleTapGestureRecognizer`
///   теряет состояние между тапами при ребилдах от listener-а контроллера.
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
    this.onSingleTap,
  });

  final String url;
  final TransformationController transformationController;

  final bool showEdgeNavigation;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback? onGoPrev;
  final VoidCallback? onGoNext;

  /// Одиночный тап по фото — для скрытия/показа верхней/нижней панели.
  /// Disambiguation с double-tap (zoom) делается через `onTapUp` после
  /// небольшой задержки double-tap detector-а.
  final VoidCallback? onSingleTap;

  @override
  State<ChatMediaViewerPhotoPage> createState() =>
      _ChatMediaViewerPhotoPageState();
}

class _ChatMediaViewerPhotoPageState extends State<ChatMediaViewerPhotoPage>
    with TickerProviderStateMixin {
  static const double _doubleTapScale = 2.75;
  static const double _tapStripeFraction = 0.22;
  static const double _zoomedThreshold = 1.01;

  Size? _imageSize;
  Size _viewport = Size.zero;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  // Анимации зума (double-tap) и spring-back-а после rubber band — разделены,
  // чтобы они не отменяли друг друга и не конфликтовали по listener-ам.
  late final AnimationController _zoomAnim;
  VoidCallback? _zoomTickListener;
  late final AnimationController _springAnim;
  VoidCallback? _springTickListener;

  /// Защита от рекурсии: когда мы сами правим матрицу, listener должен
  /// проигнорировать вызов, иначе бесконечный цикл.
  bool _selfDriving = false;

  /// Активный пинч/панорамирование. Во время него вместо жёсткого клампа
  /// применяем rubber band, а в `onInteractionEnd` — spring back.
  bool _interacting = false;

  @override
  void initState() {
    super.initState();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _springAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
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
    final l = ImageStreamListener((info, _) {
      if (!mounted) return;
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (w <= 0 || h <= 0) return;
      if (_imageSize == null ||
          _imageSize!.width != w ||
          _imageSize!.height != h) {
        setState(() => _imageSize = Size(w, h));
        _enforceConstraints();
      }
    }, onError: (_, _) {});
    stream.addListener(l);
    _stream = stream;
    _listener = l;
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

  void _disposeZoomListener() {
    final l = _zoomTickListener;
    if (l != null) {
      _zoomAnim.removeListener(l);
      _zoomTickListener = null;
    }
  }

  void _disposeSpringListener() {
    final l = _springTickListener;
    if (l != null) {
      _springAnim.removeListener(l);
      _springTickListener = null;
    }
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onMatrixChanged);
    _disposeStream();
    _disposeZoomListener();
    _disposeSpringListener();
    _zoomAnim.dispose();
    _springAnim.dispose();
    super.dispose();
  }

  /// Считает новое положение translation для текущей матрицы (делегат в
  /// `zoom_math` чтобы можно было покрыть юнит-тестами без рендеринга).
  ({double tx, double ty}) _computeTarget({required bool rubber}) {
    return zoom_math.computeClampedTranslation(
      matrix: widget.transformationController.value,
      content: zoom_math.contentRectFor(
        imageSize: _imageSize,
        viewport: _viewport,
      ),
      viewport: _viewport,
      rubber: rubber,
    );
  }

  void _applyMatrixTranslation(double newTx, double newTy) {
    final m = widget.transformationController.value;
    final t = m.getTranslation();
    if ((newTx - t.x).abs() < 0.001 && (newTy - t.y).abs() < 0.001) return;
    final updated = m.clone()..setTranslationRaw(newTx, newTy, t.z);
    _selfDriving = true;
    widget.transformationController.value = updated;
    _selfDriving = false;
  }

  void _onMatrixChanged() {
    if (_selfDriving) return;
    // Во время активного жеста применяем мягкое сопротивление, иначе — кламп.
    final t = _computeTarget(rubber: _interacting);
    _applyMatrixTranslation(t.tx, t.ty);
  }

  /// Принудительный (синхронный) кламп — для случаев когда viewport
  /// меняется (повороты, открытие галереи) и матрица может оказаться вне границ.
  void _enforceConstraints() {
    final t = _computeTarget(rubber: false);
    _applyMatrixTranslation(t.tx, t.ty);
  }

  void _onInteractionStart(ScaleStartDetails d) {
    if (kDebugMode) {
      appLogger.d(
        '[photo-viewer] interactionStart pointers=${d.pointerCount}',
      );
    }
    _interacting = true;
    // Останавливаем spring-back, если он был в процессе.
    if (_springAnim.isAnimating) {
      _springAnim.stop();
      _disposeSpringListener();
    }
  }

  void _onInteractionEnd(ScaleEndDetails d) {
    if (kDebugMode) {
      final scale = widget.transformationController.value.getMaxScaleOnAxis();
      appLogger.d(
        '[photo-viewer] interactionEnd scale=$scale v=${d.velocity.pixelsPerSecond}',
      );
    }
    _interacting = false;
    final t = _computeTarget(rubber: false);
    final m = widget.transformationController.value;
    final tr = m.getTranslation();
    if ((t.tx - tr.x).abs() < 0.5 && (t.ty - tr.y).abs() < 0.5) {
      return; // уже в границах
    }
    final target = m.clone()..setTranslationRaw(t.tx, t.ty, tr.z);
    _animateSpring(target);
  }

  void _animateSpring(Matrix4 target) {
    _disposeSpringListener();
    final begin = widget.transformationController.value;
    final anim = Matrix4Tween(
      begin: begin,
      end: target,
    ).animate(CurvedAnimation(parent: _springAnim, curve: Curves.easeOutCubic));
    void l() {
      _selfDriving = true;
      widget.transformationController.value = anim.value;
      _selfDriving = false;
    }

    _springTickListener = l;
    _springAnim
      ..removeStatusListener(_onSpringStatus)
      ..addStatusListener(_onSpringStatus);
    _springAnim.addListener(l);
    _springAnim.forward(from: 0);
  }

  void _onSpringStatus(AnimationStatus status) {
    // Реагируем ТОЛЬКО на completed. Если ловить dismissed, listener
    // удалится при `forward(from: 0)` — value=0 переводит status в
    // dismissed раньше чем анимация делает первый кадр.
    if (status == AnimationStatus.completed) {
      _disposeSpringListener();
    }
  }

  void _animateZoomTo(Matrix4 target) {
    if (kDebugMode) {
      appLogger.d(
        '[photo-viewer] animateZoomTo targetScale=${target.getMaxScaleOnAxis()}',
      );
    }
    _disposeZoomListener();
    if (_springAnim.isAnimating) {
      _springAnim.stop();
      _disposeSpringListener();
    }
    final begin = widget.transformationController.value;
    final anim = Matrix4Tween(
      begin: begin,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    void l() {
      _selfDriving = true;
      widget.transformationController.value = anim.value;
      _selfDriving = false;
    }

    _zoomTickListener = l;
    _zoomAnim
      ..removeStatusListener(_onZoomStatus)
      ..addStatusListener(_onZoomStatus);
    _zoomAnim.addListener(l);
    _zoomAnim.forward(from: 0);
  }

  void _onZoomStatus(AnimationStatus status) {
    if (kDebugMode) {
      appLogger.d('[photo-viewer] zoomAnim status=$status');
    }
    // ТОЛЬКО completed (см. комментарий в _onSpringStatus).
    if (status == AnimationStatus.completed) {
      _disposeZoomListener();
      _enforceConstraints();
    }
  }

  void _handleDoubleTap(TapDownDetails d) {
    final currentScale = widget.transformationController.value
        .getMaxScaleOnAxis();
    if (kDebugMode) {
      appLogger.d(
        '[photo-viewer] doubleTap scale=$currentScale focal=${d.localPosition}',
      );
    }
    if (currentScale > _zoomedThreshold) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    final focal = d.localPosition;
    final target = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1.0, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _animateZoomTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final v = Size(constraints.maxWidth, constraints.maxHeight);
        if (v != _viewport) {
          _viewport = v;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _enforceConstraints();
          });
        }
        final stripe = v.width * _tapStripeFraction;

        // Важно: GestureDetector для double-tap здесь, ВНЕ всяких
        // listener-ов матрицы — иначе при ребилдах от смены matrix
        // double-tap recognizer теряет состояние между тапами.
        // panEnabled тоже фиксирован: его динамическое переключение
        // приводило к пересозданию recognizer-ов внутри IV, что ломало
        // последующие жесты. Вместо отключения pan при scale=1 полагаемся
        // на наш кламп — pan не сможет сдвинуть содержимое.
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTapDown: _handleDoubleTap,
              onTap: widget.onSingleTap,
              child: InteractiveViewer(
                transformationController: widget.transformationController,
                minScale: 1,
                maxScale: 5,
                panEnabled: true,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                onInteractionStart: _onInteractionStart,
                onInteractionEnd: _onInteractionEnd,
                child: SizedBox(
                  width: v.width,
                  height: v.height,
                  child: ChatCachedNetworkImage(
                    url: widget.url,
                    fit: BoxFit.contain,
                    showProgressIndicator: true,
                  ),
                ),
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
