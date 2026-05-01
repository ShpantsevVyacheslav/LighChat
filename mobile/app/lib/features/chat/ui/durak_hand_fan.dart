import 'dart:math';

import 'package:flutter/foundation.dart';
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
    required this.onDragStarted,
    required this.onDragAcceptedByTable,
    required this.onDragRejected,
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
  final void Function(Map<String, dynamic> card, String id)? onDragStarted;

  /// Kept for API compatibility with the table screen.
  final void Function(Map<String, dynamic> card) onDragAcceptedByTable;
  final void Function(Map<String, dynamic> card) onDragRejected;

  static final Set<String> _loggedLayoutIssues = <String>{};

  void _logLayoutIssue(String key, String message) {
    if (!kDebugMode) return;
    if (_loggedLayoutIssues.contains(key)) return;
    _loggedLayoutIssues.add(key);
    debugPrint('[DurakHandFan][$key] $message');
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox(height: 116);

    return LayoutBuilder(
      builder: (context, c) {
        final mediaWidth = MediaQuery.sizeOf(context).width;
        final w = c.maxWidth.isFinite && c.maxWidth > 0
            ? c.maxWidth
            : max(1.0, mediaWidth - 16);
        if (!c.maxWidth.isFinite || c.maxWidth <= 0) {
          _logLayoutIssue(
            'invalid_constraints',
            'maxWidth=${c.maxWidth}, mediaWidth=$mediaWidth, cards=${cards.length}',
          );
        }
        final n = cards.length;
        final baseW = 68.0;
        final cardW = min(baseW, max(46.0, w / max(4.7, n * 0.68)));
        final cardH = cardW * (96.0 / 68.0);
        final overlap = n <= 1
            ? 0.0
            : min(
                cardW * 0.62,
                max(cardW * 0.28, (n * cardW - w) / max(1, n - 1)),
              );
        final step = cardW - overlap;
        final fanW = cardW + (n - 1) * step;
        final startX = max(0.0, (w - fanW) / 2);
        if (!cardW.isFinite ||
            !cardH.isFinite ||
            !step.isFinite ||
            !startX.isFinite) {
          _logLayoutIssue(
            'non_finite_geometry',
            'w=$w cardW=$cardW cardH=$cardH step=$step startX=$startX cards=$n',
          );
          return const SizedBox(height: 116);
        }
        if (step <= 0) {
          _logLayoutIssue(
            'non_positive_step',
            'step=$step cardW=$cardW overlap=$overlap cards=$n width=$w',
          );
        }

        return SizedBox(
          width: w,
          height: cardH + 24,
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
                    selected:
                        selectedId != null && selectedId == cardId(cards[i], i),
                    onTap: () => onTap(cards[i], cardId(cards[i], i)),
                    onDragStarted: onDragStarted,
                    onDragAcceptedByTable: () =>
                        onDragAcceptedByTable(cards[i]),
                    onDragRejected: () => onDragRejected(cards[i]),
                    cardWidth: cardW,
                    cardHeight: cardH,
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
    required this.onDragStarted,
    required this.onDragAcceptedByTable,
    required this.onDragRejected,
    required this.cardWidth,
    required this.cardHeight,
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
  final void Function(Map<String, dynamic> card, String id)? onDragStarted;
  final VoidCallback onDragAcceptedByTable;
  final VoidCallback onDragRejected;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    Widget buildCard({required bool withFlightKey}) {
      return Container(
        key: withFlightKey ? keyForFlight : null,
        child: DurakCardWidget(
          rankLabel: rank,
          suitLabel: suit,
          isRed: isRed,
          faceUp: true,
          selected: selected,
          disabled: !enabled,
          highlight: highlight,
          width: cardWidth,
          height: cardHeight,
          onTap: onTap,
        ),
      );
    }

    final childCard = buildCard(withFlightKey: true);
    if (!enabled) return childCard;

    return Draggable<Map<String, dynamic>>(
      data: card,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: childDragAnchorStrategy,
      rootOverlay: true,
      onDragStarted: () => onDragStarted?.call(card, id),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.96, child: buildCard(withFlightKey: false)),
      ),
      childWhenDragging: Opacity(opacity: 0.24, child: childCard),
      onDragEnd: (details) {
        if (details.wasAccepted) {
          onDragAcceptedByTable();
        } else {
          onDragRejected();
        }
      },
      child: childCard,
    );
  }
}
