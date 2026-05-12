import 'package:flutter/widgets.dart' show Matrix4;
import 'package:flutter/painting.dart';

/// Чистые функции для вычисления клампа и rubber-band затухания в полно-
/// экранном просмотрщике медиа. Вынесены отдельно от виджета, чтобы их можно
/// было покрыть юнит-тестами без рендеринга.
///
/// Терминология:
/// - `content` — прямоугольник реально отрисованного изображения (после
///   `BoxFit.contain`) внутри screen-sized child-а `InteractiveViewer`-а, в
///   координатах child-а (scale = 1).
/// - `viewport` — размер экрана / контейнера, в котором живёт `InteractiveViewer`.
/// - `shownLeft/Top` — текущая позиция (в координатах viewport-а) левого/верхнего
///   края `content` после применения матрицы трансформации.

/// Прямоугольник реально отрисованного изображения внутри screen-sized child-а.
/// При неизвестном размере источника возвращает прямоугольник во весь viewport
/// (тогда кламп вырождается в обычный кламп по краям).
Rect contentRectFor({required Size? imageSize, required Size viewport}) {
  if (viewport.isEmpty) return Rect.zero;
  if (imageSize == null || imageSize.isEmpty) return Offset.zero & viewport;
  final fit = applyBoxFit(BoxFit.contain, imageSize, viewport);
  final dst = fit.destination;
  return Rect.fromLTWH(
    (viewport.width - dst.width) / 2,
    (viewport.height - dst.height) / 2,
    dst.width,
    dst.height,
  );
}

/// iOS-стиль rubber band: чем дальше overshoot, тем сильнее сопротивление,
/// но смещение никогда не доходит до полного значения.
///
/// `dim` — характерный размер (обычно ширина/высота viewport-а) для
/// нормализации. `coeff` — коэффициент жёсткости, по умолчанию 0.55 как в iOS.
double rubberBand(double offset, double dim, {double coeff = 0.55}) {
  if (offset == 0 || dim <= 0) return 0;
  final sign = offset.isNegative ? -1.0 : 1.0;
  final x = offset.abs();
  return sign * dim * (1 - 1 / (coeff * x / dim + 1));
}

/// Допустимый диапазон `shownLeft/Top` для данной ширины/высоты контента.
/// Если контент шире/выше viewport-а — диапазон между `viewport-shown` и `0`;
/// иначе — фиксированная позиция «по центру».
({double min, double max}) allowedRange(double shownDim, double viewportDim) {
  if (shownDim > viewportDim) {
    return (min: viewportDim - shownDim, max: 0);
  }
  final center = (viewportDim - shownDim) / 2;
  return (min: center, max: center);
}

/// Считает целевую позицию translation для данной матрицы зума.
///
/// - При `rubber = false` — жёсткий кламп: содержимое всегда в границах,
///   край картинки прилеплен к краю экрана при scale > 1.
/// - При `rubber = true` — overshoot за границей разрешается, но с
///   iOS-style затуханием (для эффекта пружины во время drag-а).
///
/// Возвращает `(tx, ty)` — желаемые компоненты translation матрицы.
({double tx, double ty}) computeClampedTranslation({
  required Matrix4 matrix,
  required Rect content,
  required Size viewport,
  required bool rubber,
}) {
  final scale = matrix.getMaxScaleOnAxis();
  final t = matrix.getTranslation();
  final tx = t.x;
  final ty = t.y;

  if (viewport.isEmpty || content.isEmpty) return (tx: tx, ty: ty);

  final shownLeft = content.left * scale + tx;
  final shownTop = content.top * scale + ty;
  final shownW = content.width * scale;
  final shownH = content.height * scale;

  final rx = allowedRange(shownW, viewport.width);
  final ry = allowedRange(shownH, viewport.height);

  double newShownLeft = shownLeft.clamp(rx.min, rx.max);
  double newShownTop = shownTop.clamp(ry.min, ry.max);

  if (rubber) {
    if (shownLeft > rx.max) {
      newShownLeft = rx.max + rubberBand(shownLeft - rx.max, viewport.width);
    } else if (shownLeft < rx.min) {
      newShownLeft = rx.min - rubberBand(rx.min - shownLeft, viewport.width);
    }
    if (shownTop > ry.max) {
      newShownTop = ry.max + rubberBand(shownTop - ry.max, viewport.height);
    } else if (shownTop < ry.min) {
      newShownTop = ry.min - rubberBand(ry.min - shownTop, viewport.height);
    }
  }

  return (
    tx: newShownLeft - content.left * scale,
    ty: newShownTop - content.top * scale,
  );
}
