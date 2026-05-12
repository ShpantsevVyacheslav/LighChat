import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_media_zoom_math.dart';

/// Юнит-тесты на чистые функции зума/клампа из media viewer-а.
///
/// Виджет тестировать целиком сложно (cached_network_image тянет sqflite
/// плагин, которому нужен mock в test binding и который вешает pump на 10мин);
/// поэтому проверяем поведение через чистые математические функции,
/// которые виджет вызывает на каждое изменение матрицы.
///
/// Базовый сценарий: viewport 400×800, image 400×400 (квадрат) →
/// при BoxFit.contain content = Rect(0, 200, 400, 400) — letterbox-поля
/// сверху и снизу высотой 200px.
void main() {
  group('contentRectFor', () {
    test('null imageSize → весь viewport', () {
      final r = contentRectFor(
        imageSize: null,
        viewport: const Size(400, 800),
      );
      expect(r, const Rect.fromLTWH(0, 0, 400, 800));
    });

    test('квадратное фото в портретный viewport — letterbox по высоте', () {
      final r = contentRectFor(
        imageSize: const Size(1000, 1000),
        viewport: const Size(400, 800),
      );
      expect(r, const Rect.fromLTWH(0, 200, 400, 400));
    });

    test('landscape фото в портретный viewport — letterbox по высоте', () {
      final r = contentRectFor(
        imageSize: const Size(2000, 1000),
        viewport: const Size(400, 800),
      );
      // contain → 400×200, letterbox 300px сверху и снизу.
      expect(r, const Rect.fromLTWH(0, 300, 400, 200));
    });
  });

  group('rubberBand', () {
    test('нулевой offset → нулевое сопротивление', () {
      expect(rubberBand(0, 400), 0);
    });

    test('всегда меньше входного offset (затухание)', () {
      for (final x in [10.0, 50.0, 100.0, 200.0, 400.0]) {
        final r = rubberBand(x, 400);
        expect(r, lessThan(x), reason: 'overshoot $x → rubber $r');
        expect(r, greaterThan(0));
      }
    });

    test('сохраняет знак', () {
      expect(rubberBand(50, 400), greaterThan(0));
      expect(rubberBand(-50, 400), lessThan(0));
    });

    test('никогда не превышает dim (асимптота)', () {
      expect(rubberBand(10000, 400), lessThan(400));
      expect(rubberBand(double.maxFinite, 400), lessThanOrEqualTo(400));
    });
  });

  group('allowedRange', () {
    test('контент шире viewport → диапазон [v-shown, 0]', () {
      final r = allowedRange(800, 400);
      expect(r.min, -400);
      expect(r.max, 0);
    });

    test('контент уже viewport → фиксированная позиция в центре', () {
      final r = allowedRange(200, 400);
      expect(r.min, 100);
      expect(r.max, 100);
    });
  });

  group('computeClampedTranslation', () {
    // Сценарий: квадратное фото в портретный viewport.
    final viewport = const Size(400, 800);
    final imageSize = const Size(1000, 1000);
    final content = contentRectFor(
      imageSize: imageSize,
      viewport: viewport,
    );

    test('identity матрица → identity translation (контент центрирован)', () {
      final t = computeClampedTranslation(
        matrix: Matrix4.identity(),
        content: content,
        viewport: viewport,
        rubber: false,
      );
      expect(t.tx, closeTo(0, 0.001));
      expect(t.ty, closeTo(0, 0.001));
    });

    test('scale=2 без translation → identity translation (тоже центрирован)',
        () {
      final m = Matrix4.identity()..scaleByDouble(2, 2, 1, 1);
      final t = computeClampedTranslation(
        matrix: m,
        content: content,
        viewport: viewport,
        rubber: false,
      );
      // Hard clamp при scale=2: shownLeft = 0*2 = 0, shownW = 400*2 = 800.
      // Допустимый диапазон [400-800, 0] = [-400, 0]. shownLeft=0 в диапазоне.
      // shownTop = 200*2 = 400, shownH = 400*2 = 800. Диапазон [0, 0].
      // shownTop=400 за диапазоном → должен сделать shownTop=0 →
      // newTy = 0 - content.top*scale = -400.
      expect(t.tx, closeTo(0, 0.001));
      expect(t.ty, closeTo(-400, 0.001));
    });

    test('hard clamp: попытка утащить вправо → край картинки приклеен', () {
      // scale=2, контент уехал на 200px вправо (за границу).
      final m = Matrix4.identity()
        ..scaleByDouble(2, 2, 1, 1)
        ..setTranslationRaw(200, 0, 0);
      final t = computeClampedTranslation(
        matrix: m,
        content: content,
        viewport: viewport,
        rubber: false,
      );
      // Hard clamp должен вернуть tx так, чтобы shownLeft = 0 (max).
      expect(t.tx, closeTo(0, 0.001));
    });

    test('rubber band: overshoot затухает, но не доходит до нуля', () {
      // scale=2, shownLeft=200 (overshoot 200 за max=0).
      final m = Matrix4.identity()
        ..scaleByDouble(2, 2, 1, 1)
        ..setTranslationRaw(200, 0, 0);
      final tHard = computeClampedTranslation(
        matrix: m,
        content: content,
        viewport: viewport,
        rubber: false,
      );
      final tRubber = computeClampedTranslation(
        matrix: m,
        content: content,
        viewport: viewport,
        rubber: true,
      );
      // Hard clamp = 0 (приклеено к границе).
      expect(tHard.tx, closeTo(0, 0.001));
      // Rubber band > hard (контент частично «уехал» в overshoot).
      expect(tRubber.tx, greaterThan(tHard.tx));
      // Но < исходного 200 (затухание).
      expect(tRubber.tx, lessThan(200));
    });

    test('scale=1: всегда центрирует, даже если translation был задан', () {
      // BUG-regression: при scale=1 не должно быть видно letterbox-сдвига.
      final m = Matrix4.identity()..setTranslationRaw(100, 100, 0);
      final t = computeClampedTranslation(
        matrix: m,
        content: content,
        viewport: viewport,
        rubber: false,
      );
      expect(t.tx, closeTo(0, 0.001));
      expect(t.ty, closeTo(0, 0.001));
    });
  });
}
