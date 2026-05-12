import 'package:flutter/widgets.dart';

/// Размерные ступени для адаптивного UI. Подобраны под Material 3 spec:
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
enum LayoutSize {
  /// Узкий — телефон в портрете (<600dp).
  compact,

  /// Средний — телефон-ландшафт или маленький планшет (600–839dp).
  medium,

  /// Широкий — планшет в ландшафте, маленькое окно ноутбука (840–1199dp).
  expanded,

  /// Большой — десктоп / широкое окно (≥1200dp).
  large;

  bool get isCompact => this == LayoutSize.compact;
  bool get isAtLeastMedium =>
      this == LayoutSize.medium || isAtLeastExpanded;
  bool get isAtLeastExpanded =>
      this == LayoutSize.expanded || this == LayoutSize.large;
  bool get isLarge => this == LayoutSize.large;

  static LayoutSize fromWidth(double width) {
    if (width < 600) return LayoutSize.compact;
    if (width < 840) return LayoutSize.medium;
    if (width < 1200) return LayoutSize.expanded;
    return LayoutSize.large;
  }
}

extension LayoutSizeContext on BuildContext {
  LayoutSize get layoutSize =>
      LayoutSize.fromWidth(MediaQuery.sizeOf(this).width);
  bool get isCompactLayout => layoutSize.isCompact;
  bool get isWideLayout => layoutSize.isAtLeastExpanded;
}
