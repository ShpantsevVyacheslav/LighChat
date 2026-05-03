import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../l10n/app_localizations.dart';
import 'avatar_picker_cropper.dart';

/// Экран настройки аватара: перемещение + зум изображения внутри круглой маски.
///
/// Фон совпадает с auth-экранами: тёмный #04070C + radial gradient orbs.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.imageFile});

  /// Выбранный файл изображения (галерея или камера).
  final File imageFile;

  static Future<AvatarResult?> push(
    BuildContext context, {
    required File imageFile,
  }) async {
    final result = await Navigator.of(context).push<AvatarResult>(
      MaterialPageRoute(
        builder: (_) => AvatarCropScreen(imageFile: imageFile),
      ),
    );
    return result;
  }

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final TransformationController _transformController =
      TransformationController();
  double? _cropScreenSize;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _transformController.value = Matrix4.identity();
    });
  }

  void _save() async {
    if (_cropScreenSize == null) return;

    // Загружаем оригинал.
    final bytes = await widget.imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    final origW = decoded.width.toDouble();
    final origH = decoded.height.toDouble();

    final cropSize = _cropScreenSize!;
    final areaSize = cropSize / 0.8;
    final cropInset = (areaSize - cropSize) / 2;
    final cropRectInViewport = Rect.fromLTWH(
      cropInset,
      cropInset,
      cropSize,
      cropSize,
    );

    // Переводим видимую квадратную область внутри круга из viewport-координат
    // в координаты дочернего виджета InteractiveViewer.
    final topLeftInScene = _transformController.toScene(
      cropRectInViewport.topLeft,
    );
    final bottomRightInScene = _transformController.toScene(
      cropRectInViewport.bottomRight,
    );
    final visibleRectInScene = Rect.fromPoints(
      topLeftInScene,
      bottomRightInScene,
    );

    // Image.file рисуется внутри квадрата `areaSize x areaSize` с BoxFit.cover.
    // Поэтому сначала находим, какой участок оригинала попал в этот квадрат,
    // а затем уже извлекаем подпрямоугольник, реально видимый в круге.
    final fitted = applyBoxFit(
      BoxFit.cover,
      Size(origW, origH),
      Size(areaSize, areaSize),
    );
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Rect.fromLTWH(0, 0, origW, origH),
    );
    final destinationRect = Alignment.center.inscribe(
      fitted.destination,
      Rect.fromLTWH(0, 0, areaSize, areaSize),
    );

    final normalizedLeft =
        ((visibleRectInScene.left - destinationRect.left) / destinationRect.width)
            .clamp(0.0, 1.0);
    final normalizedTop =
        ((visibleRectInScene.top - destinationRect.top) / destinationRect.height)
            .clamp(0.0, 1.0);
    final normalizedRight =
        ((visibleRectInScene.right - destinationRect.left) / destinationRect.width)
            .clamp(0.0, 1.0);
    final normalizedBottom =
        ((visibleRectInScene.bottom - destinationRect.top) / destinationRect.height)
            .clamp(0.0, 1.0);

    final srcRect = Rect.fromLTRB(
      sourceRect.left + sourceRect.width * normalizedLeft,
      sourceRect.top + sourceRect.height * normalizedTop,
      sourceRect.left + sourceRect.width * normalizedRight,
      sourceRect.top + sourceRect.height * normalizedBottom,
    );

    final srcX = srcRect.left.clamp(0.0, origW - 1);
    final srcY = srcRect.top.clamp(0.0, origH - 1);
    final srcSizeW = srcRect.width.clamp(1.0, origW - srcX);
    final srcSizeH = srcRect.height.clamp(1.0, origH - srcY);

    final cropped = img.copyCrop(
      decoded,
      x: srcX.toInt(),
      y: srcY.toInt(),
      width: srcSizeW.toInt(),
      height: srcSizeH.toInt(),
    );

    // Full: 1024x1024 JPEG.
    const fullSize = 1024;
    final full = img.copyResize(
      cropped,
      width: fullSize,
      height: fullSize,
      interpolation: img.Interpolation.average,
    );
    final fullJpeg = Uint8List.fromList(img.encodeJpg(full, quality: 92));

    // Thumb: 512x512 PNG с круговой маской.
    const thumbSize = 512;
    final thumbBase = img.copyResize(
      cropped,
      width: thumbSize,
      height: thumbSize,
      interpolation: img.Interpolation.average,
    );
    final thumbCircle = _circleMask(thumbBase);
    final thumbPng = Uint8List.fromList(img.encodePng(thumbCircle));

    final result = AvatarResult(
      fullJpeg: fullJpeg,
      thumbPng: thumbPng,
      previewBytes: thumbPng,
    );

    if (mounted) Navigator.of(context).pop(result);
  }

  img.Image _circleMask(img.Image square) {
    final out = img.Image(
      width: square.width,
      height: square.height,
      numChannels: 4,
    );
    final cx = (square.width - 1) / 2.0;
    final cy = (square.height - 1) / 2.0;
    final r = square.width / 2.0;

    for (var y = 0; y < square.height; y++) {
      for (var x = 0; x < square.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= (r * r);
        if (!inside) {
          out.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          final p = square.getPixel(x, y);
          out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF04070C),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.avatar_crop_title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Crop area.
            Expanded(
              child: _CropArea(
                imageFile: widget.imageFile,
                transformController: _transformController,
                onCropSizeReady: (size) => setState(() => _cropScreenSize = size),
              ),
            ),

            // Hint text.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              child: Text(
                l10n.avatar_crop_hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

            // Buttons.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _GlassButton(
                      label: l10n.avatar_crop_cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlassButton(
                      label: l10n.avatar_crop_reset,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrimaryButton(
                      label: l10n.avatar_crop_save,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Область кропа: изображение + круглая маска + жесты.
class _CropArea extends StatefulWidget {
  const _CropArea({
    required this.imageFile,
    required this.transformController,
    required this.onCropSizeReady,
  });

  final File imageFile;
  final TransformationController transformController;
  final ValueChanged<double> onCropSizeReady;

  @override
  State<_CropArea> createState() => _CropAreaState();
}

class _CropAreaState extends State<_CropArea> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = math.min(constraints.maxWidth, constraints.maxHeight);
        // Рамка круга чуть меньше области (80%).
        final cropSize = areaSize * 0.8;
        final cropRadius = cropSize / 2;
        final cropCenter = Offset(areaSize / 2, areaSize / 2);

        // Сообщаем размер кропа родителю.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCropSizeReady(cropSize);
        });

        return Container(
          color: const Color(0xFF04070C),
          child: Stack(
            children: [
              // 0. Gradient orbs (на заднем плане).
              Positioned(
                left: -80,
                top: -60,
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF1E5FFF),
                          Color(0xFF1E5FFF),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -60,
                bottom: -80,
                child: Opacity(
                  opacity: 0.25,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF7217FF),
                          Color(0xFF7217FF),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Crop area content.
              Center(
                child: SizedBox(
                  width: areaSize,
                  height: areaSize,
                  child: Stack(
                    children: [
                      // 1. InteractiveViewer — снизу, получает все жесты.
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: widget.transformController,
                          minScale: 0.5,
                          maxScale: 5.0,
                          boundaryMargin: EdgeInsets.all(areaSize),
                          panEnabled: true,
                          scaleEnabled: true,
                          child: Center(
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                              width: areaSize,
                              height: areaSize,
                            ),
                          ),
                        ),
                      ),

                      // 2. Затемнение вне круга (ignorePointer).
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _OutsideCircleOverlayPainter(
                              center: cropCenter,
                              radius: cropRadius,
                            ),
                            size: Size(areaSize, areaSize),
                          ),
                        ),
                      ),

                      // 3. Белая рамка (ignorePointer).
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: cropSize,
                              height: cropSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Рисует затемнение вне круга.
class _OutsideCircleOverlayPainter extends CustomPainter {
  _OutsideCircleOverlayPainter({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем путь: весь прямоугольник минус круг (evenOdd).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      // Внешний прямоугольник.
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      // Вырезаем круг.
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _OutsideCircleOverlayPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.radius != radius;
}

/// Glassmorphism кнопка (как в auth_styles).
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.18 : 0.50),
        ),
        color: Colors.white.withValues(alpha: dark ? 0.06 : 0.30),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: scheme.onSurface,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Primary gradient кнопка (как в auth).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2E86FF),
            Color(0xFF5F90FF),
            Color(0xFF9A18FF),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
