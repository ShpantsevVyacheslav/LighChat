import 'package:flutter/painting.dart';

/// Брендовая палитра LighChat. Используется в фичах, прямо
/// связанных с визуальной идентичностью бренда (welcome-анимация, hero-экраны),
/// и не подменяет seed-цвет пользовательской темы.
const Color kBrandNavy = Color(0xFF1E3A5F);
const Color kBrandNavyDark = Color(0xFF0E2138);
/// Совпадает с `--coral` в превью и с тоном лампы/полосы перекрашенного
/// `assets/lighchat_mark.png` (после processing'а — alpha поднята, цвет
/// сведён к этому hex). Используется и в SVG-сцене welcome-анимации, и в
/// wordmark "Chat".
const Color kBrandCoral = Color(0xFFF4A12C);
const Color kBrandCoralDeep = Color(0xFFD38614);
