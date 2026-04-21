import 'package:flutter/material.dart';

import 'chat_cached_network_image.dart';

/// Фото в полноэкранной галерее: pinch-zoom, двойной тап, без панорамы при масштабе 1×.
class ChatMediaViewerPhotoPage extends StatelessWidget {
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

  static const double _doubleTapScale = 2.75;
  static const double _tapStripeFraction = 0.22;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final stripe = w * _tapStripeFraction;
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTapDown: (d) {
                final s = transformationController.value.getMaxScaleOnAxis();
                if (s > 1.05) {
                  transformationController.value = Matrix4.identity();
                } else {
                  final focal = d.localPosition;
                  final t1 = Matrix4.translationValues(focal.dx, focal.dy, 0);
                  final sc = Matrix4.diagonal3Values(
                    _doubleTapScale,
                    _doubleTapScale,
                    1,
                  );
                  final t2 =
                      Matrix4.translationValues(-focal.dx, -focal.dy, 0);
                  transformationController.value = t1 * sc * t2;
                }
              },
              child: AnimatedBuilder(
                animation: transformationController,
                builder: (context, _) {
                  final zoomed =
                      transformationController.value.getMaxScaleOnAxis() > 1.05;
                  return InteractiveViewer(
                    transformationController: transformationController,
                    minScale: 1,
                    maxScale: 5,
                    panEnabled: zoomed,
                    scaleEnabled: true,
                    clipBehavior: Clip.none,
                    boundaryMargin: EdgeInsets.zero,
                    constrained: false,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ChatCachedNetworkImage(
                        url: url,
                        fit: BoxFit.contain,
                        showProgressIndicator: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showEdgeNavigation && canGoPrev)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onGoPrev,
                ),
              ),
            if (showEdgeNavigation && canGoNext)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onGoNext,
                ),
              ),
          ],
        );
      },
    );
  }
}
