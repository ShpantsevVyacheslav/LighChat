import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_image_cache_manager.dart';
import 'chat_cached_network_image.dart';

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
  });

  final String url;
  final TransformationController transformationController;

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
    with TickerProviderStateMixin {
  static const double _doubleTapScale = 2.75;
  static const double _tapStripeFraction = 0.22;
  static const double _zoomedThreshold = 1.01;

  /// iOS-style rubber-band коэффициент: чем меньше — тем «жёстче» резина.
  static const double _rubberBandCoeff = 0.55;

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

  /// iOS-стиль: чем дальше тащим за границу, тем сильнее сопротивление,
  /// но никогда не доходит до полного значения. `dim` — характерный размер
  /// для нормализации (ширина или высота экрана).
  double _rubberBand(double offset, double dim) {
    if (offset == 0 || dim <= 0) return 0;
    final sign = offset.isNegative ? -1.0 : 1.0;
    final x = offset.abs();
    return sign * dim * (1 - 1 / (_rubberBandCoeff * x / dim + 1));
  }

  /// Идеальное (в-границах) положение `shownLeft` для данной ширины контента.
  /// Возвращает (min, max) допустимого диапазона.
  ({double min, double max}) _rangeFor(double shownDim, double viewportDim) {
    if (shownDim > viewportDim) {
      // Контент больше viewport — допустимый диапазон: shown[Left] от
      // viewport - shown до 0 (край контента не отрывается от края экрана).
      return (min: viewportDim - shownDim, max: 0);
    }
    final center = (viewportDim - shownDim) / 2;
    return (min: center, max: center);
  }

  /// Считает новое положение translation по правилам:
  /// - если `rubber` = false: жёсткий кламп к границе/центру;
  /// - если `rubber` = true: за границей применяется rubber-band затухание.
  ({double tx, double ty}) _computeTarget({required bool rubber}) {
    final v = _viewport;
    final content = _contentRect();
    final m = widget.transformationController.value;
    final scale = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final tx = t.x;
    final ty = t.y;

    if (v.isEmpty || content.isEmpty) return (tx: tx, ty: ty);

    final shownLeft = content.left * scale + tx;
    final shownTop = content.top * scale + ty;
    final shownW = content.width * scale;
    final shownH = content.height * scale;

    final rx = _rangeFor(shownW, v.width);
    final ry = _rangeFor(shownH, v.height);

    double newShownLeft = shownLeft.clamp(rx.min, rx.max);
    double newShownTop = shownTop.clamp(ry.min, ry.max);

    if (rubber) {
      // Восстанавливаем overshoot (если был) и применяем затухание.
      if (shownLeft > rx.max) {
        newShownLeft = rx.max + _rubberBand(shownLeft - rx.max, v.width);
      } else if (shownLeft < rx.min) {
        newShownLeft = rx.min - _rubberBand(rx.min - shownLeft, v.width);
      }
      if (shownTop > ry.max) {
        newShownTop = ry.max + _rubberBand(shownTop - ry.max, v.height);
      } else if (shownTop < ry.min) {
        newShownTop = ry.min - _rubberBand(ry.min - shownTop, v.height);
      }
    }

    return (
      tx: newShownLeft - content.left * scale,
      ty: newShownTop - content.top * scale,
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

  void _onInteractionStart(ScaleStartDetails _) {
    _interacting = true;
    // Останавливаем spring-back, если он был в процессе.
    if (_springAnim.isAnimating) {
      _springAnim.stop();
      _disposeSpringListener();
    }
  }

  void _onInteractionEnd(ScaleEndDetails _) {
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
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _disposeSpringListener();
    }
  }

  void _animateZoomTo(Matrix4 target) {
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
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _disposeZoomListener();
      _enforceConstraints();
    }
  }

  void _handleDoubleTap(TapDownDetails d) {
    final currentScale = widget.transformationController.value
        .getMaxScaleOnAxis();
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
