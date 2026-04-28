import 'dart:math';

import 'package:flutter/material.dart';

import 'durak_card_widget.dart';

class DurakHandFan extends StatelessWidget {
  const DurakHandFan({
    super.key,
    required this.cards,
    required this.cardId,
    required this.keyForCardId,
    required this.rankLabel,
    required this.suitLabel,
    required this.isRedSuit,
    required this.enabled,
    required this.highlight,
    required this.selectedId,
    required this.onTap,
    required this.onDragAcceptedByTable,
  });

  final List<Map<String, dynamic>> cards;
  final String Function(Map<String, dynamic> card, int index) cardId;
  final GlobalKey Function(String id) keyForCardId;
  final String Function(Map<String, dynamic>) rankLabel;
  final String Function(Map<String, dynamic>) suitLabel;
  final bool Function(String) isRedSuit;

  final bool Function(Map<String, dynamic>) enabled;
  final bool Function(Map<String, dynamic>) highlight;
  final String? selectedId;
  final void Function(Map<String, dynamic> card, String id) onTap;

  /// Called after successful drag end (table accepted). We use it to trigger fly animation.
  final void Function(Map<String, dynamic> card) onDragAcceptedByTable;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox(height: 96);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cardW = 56.0;
        final cardH = 80.0;
        final n = cards.length;
        final overlap = n <= 1 ? 0.0 : min(32.0, max(14.0, (n * cardW - w) / max(1, n - 1)));
        final step = cardW - overlap;
        final fanW = cardW + (n - 1) * step;
        final startX = max(0.0, (w - fanW) / 2);

        return SizedBox(
          height: cardH + 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < n; i++)
                Positioned(
                  left: startX + i * step,
                  top: 6 + (i % 2 == 0 ? 0 : 2),
                  child: _HandFanCard(
                    key: ValueKey<String>('hc:${cardId(cards[i], i)}'),
                    card: cards[i],
                    id: cardId(cards[i], i),
                    keyForFlight: keyForCardId(cardId(cards[i], i)),
                    isRed: isRedSuit((cards[i]['s'] ?? '').toString()),
                    rank: rankLabel(cards[i]),
                    suit: suitLabel(cards[i]),
                    enabled: enabled(cards[i]),
                    highlight: highlight(cards[i]),
                    selected: selectedId != null && selectedId == cardId(cards[i], i),
                    onTap: () => onTap(cards[i], cardId(cards[i], i)),
                    onDragAcceptedByTable: () => onDragAcceptedByTable(cards[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HandFanCard extends StatelessWidget {
  const _HandFanCard({
    super.key,
    required this.card,
    required this.id,
    required this.keyForFlight,
    required this.rank,
    required this.suit,
    required this.isRed,
    required this.enabled,
    required this.highlight,
    required this.selected,
    required this.onTap,
    required this.onDragAcceptedByTable,
  });

  final Map<String, dynamic> card;
  final String id;
  final GlobalKey keyForFlight;
  final String rank;
  final String suit;
  final bool isRed;
  final bool enabled;
  final bool highlight;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDragAcceptedByTable;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      key: keyForFlight,
      child: DurakCardWidget(
      rankLabel: rank,
      suitLabel: suit,
      isRed: isRed,
      faceUp: true,
      selected: selected,
      disabled: !enabled,
      highlight: highlight,
      onTap: onTap,
      ),
    );

    if (!enabled) return base;

    return Draggable<Map<String, dynamic>>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.96, child: base),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: base),
      child: base,
      onDragEnd: (d) {
        if (d.wasAccepted) onDragAcceptedByTable();
      },
    );
  }
}

