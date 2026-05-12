import 'package:flutter/painting.dart';

/// Брендовая палитра LighChat. Используется в фичах, прямо
/// связанных с визуальной идентичностью бренда (welcome-анимация, hero-экраны),
/// и не подменяет seed-цвет пользовательской темы.
const Color kBrandNavy = Color(0xFF1E3A5F);
const Color kBrandNavyDark = Color(0xFF0E2138);

/// Тёплый оранж — цвет маяка на фирменном логотипе и слова «Chat»
/// в словесном знаке. Единственный источник правды для акцентного цвета
/// бренда; web использует тот же hex в `tailwind.config.ts` (`brand.orange`).
const Color kBrandOrange = Color(0xFFF4A12C);
