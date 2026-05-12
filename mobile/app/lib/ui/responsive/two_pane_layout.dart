import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Master-detail layout: на широких экранах рендерит обе панели,
/// на узких — одну (master или detail) в зависимости от [showDetail].
///
/// Используется для чат-листа + переписки, settings + раздел и т.п.
class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.master,
    required this.detail,
    required this.showDetail,
    this.masterWidth = 320,
    this.minDetailWidth = 480,
    this.divider,
    this.emptyDetail,
  });

  /// Левая панель (master) — список, навигация. Всегда видна на широких.
  final Widget master;

  /// Правая панель (detail) — выбранный элемент.
  final Widget detail;

  /// На узких экранах — какую из панелей рендерить.
  /// `true` — detail; `false` — master.
  final bool showDetail;

  /// Ширина master-панели в expanded/large.
  final double masterWidth;

  /// Минимальная ширина detail-панели. Если экран уже — fallback на single-pane.
  final double minDetailWidth;

  /// Разделитель между панелями.
  final Widget? divider;

  /// Что показывать в detail когда ничего не выбрано (только в two-pane).
  /// Если null — показывается `detail` как есть.
  final Widget? emptyDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = LayoutSize.fromWidth(constraints.maxWidth);
        final canFitTwoPane =
            size.isAtLeastExpanded &&
            constraints.maxWidth >= masterWidth + minDetailWidth;

        if (!canFitTwoPane) {
          return showDetail ? detail : master;
        }

        final detailPane = (emptyDetail != null && !showDetail)
            ? emptyDetail!
            : detail;

        return Row(
          children: <Widget>[
            SizedBox(
              width: masterWidth,
              child: master,
            ),
            divider ??
                const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: detailPane),
          ],
        );
      },
    );
  }
}
