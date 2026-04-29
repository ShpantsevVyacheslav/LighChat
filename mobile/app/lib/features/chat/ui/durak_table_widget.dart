import 'dart:async';

import 'package:flutter/material.dart';

import 'durak_card_widget.dart';

class DurakTableWidget extends StatelessWidget {
  const DurakTableWidget({
    super.key,
    required this.pairKeyForFlight,
    required this.nextAttackSlotKey,
    required this.attacks,
    required this.defenses,
    required this.selectedAttackIndex,
    required this.onSelectAttackIndex,
    required this.canAcceptAttack,
    required this.onAttackDropped,
    required this.canAcceptTransfer,
    required this.onTransferDropped,
    required this.canAcceptDefense,
    required this.onDefenseDropped,
    required this.rankLabel,
    required this.suitLabel,
    required this.isRedSuit,
  });

  final GlobalKey Function(int attackIndex, {required bool defense})
  pairKeyForFlight;
  final GlobalKey nextAttackSlotKey;
  final List attacks;
  final List defenses;
  final int selectedAttackIndex;
  final ValueChanged<int> onSelectAttackIndex;

  final bool Function(Map<String, dynamic> card) canAcceptAttack;
  final Future<void> Function(Map<String, dynamic> card) onAttackDropped;
  final bool Function(Map<String, dynamic> card) canAcceptTransfer;
  final Future<void> Function(Map<String, dynamic> card) onTransferDropped;
  final bool Function(Map<String, dynamic> card, int attackIndex)
  canAcceptDefense;
  final Future<void> Function(int attackIndex, Map<String, dynamic> card)
  onDefenseDropped;

  final String Function(Map<String, dynamic>) rankLabel;
  final String Function(Map<String, dynamic>) suitLabel;
  final bool Function(String) isRedSuit;

  @override
  Widget build(BuildContext context) {
    final pairs = <_Pair>[];
    for (var i = 0; i < attacks.length; i++) {
      final aRaw = attacks[i];
      if (aRaw is! Map) continue;
      final attack = Map<String, dynamic>.from(aRaw);
      final defense = (i < defenses.length && defenses[i] is Map)
          ? Map<String, dynamic>.from(defenses[i] as Map)
          : null;
      pairs.add(_Pair(index: i, attack: attack, defense: defense));
    }

    if (pairs.isEmpty) {
      return DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (d) =>
            canAcceptAttack(d.data) || canAcceptTransfer(d.data),
        onAcceptWithDetails: (d) {
          final card = d.data;
          if (canAcceptTransfer(card)) {
            unawaited(onTransferDropped(card));
          } else {
            unawaited(onAttackDropped(card));
          }
        },
        builder: (context, candidate, rejected) {
          final active = candidate.isNotEmpty;
          return Container(
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color(0xFF6EE7B7).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.16),
                width: active ? 2 : 1,
              ),
              color: Colors.white.withValues(alpha: active ? 0.08 : 0.03),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: 34,
                color: Colors.white.withValues(alpha: active ? 0.78 : 0.45),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // 130 is previous fixed width; keep it close but adaptive.
        final itemW = w >= 430 ? 150.0 : 138.0;
        final spacing = w >= 430 ? 12.0 : 10.0;
        final cols = w <= 320 ? 2 : (w <= 520 ? 3 : 4);

        final totalW = cols * itemW + (cols - 1) * spacing;
        final maxW = totalW > w ? w : totalW;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final p in pairs)
                  _DurakTablePair(
                    width: itemW,
                    index: p.index,
                    attack: p.attack,
                    defense: p.defense,
                    selected: p.index == selectedAttackIndex,
                    onSelect: () => onSelectAttackIndex(p.index),
                    canAcceptDefense: canAcceptDefense,
                    onDefenseDropped: onDefenseDropped,
                    rankLabel: rankLabel,
                    suitLabel: suitLabel,
                    isRedSuit: isRedSuit,
                    attackKeyForFlight: pairKeyForFlight(
                      p.index,
                      defense: false,
                    ),
                    defenseKeyForFlight: pairKeyForFlight(
                      p.index,
                      defense: true,
                    ),
                  ),
                _NextAttackSlot(
                  keyForFlight: nextAttackSlotKey,
                  width: itemW,
                  canAcceptAttack: canAcceptAttack,
                  onAttackDropped: onAttackDropped,
                  canAcceptTransfer: canAcceptTransfer,
                  onTransferDropped: onTransferDropped,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NextAttackSlot extends StatelessWidget {
  const _NextAttackSlot({
    required this.keyForFlight,
    required this.width,
    required this.canAcceptAttack,
    required this.onAttackDropped,
    required this.canAcceptTransfer,
    required this.onTransferDropped,
  });

  final GlobalKey keyForFlight;
  final double width;
  final bool Function(Map<String, dynamic> card) canAcceptAttack;
  final Future<void> Function(Map<String, dynamic> card) onAttackDropped;
  final bool Function(Map<String, dynamic> card) canAcceptTransfer;
  final Future<void> Function(Map<String, dynamic> card) onTransferDropped;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Center(
        child: DragTarget<Map<String, dynamic>>(
          onWillAcceptWithDetails: (d) =>
              canAcceptAttack(d.data) || canAcceptTransfer(d.data),
          onAcceptWithDetails: (d) {
            final card = d.data;
            if (canAcceptTransfer(card)) {
              unawaited(onTransferDropped(card));
            } else {
              unawaited(onAttackDropped(card));
            }
          },
          builder: (context, candidate, rejected) {
            final active = candidate.isNotEmpty;
            return Container(
              key: keyForFlight,
              width: 68,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: active
                      ? const Color(0xFF6EE7B7).withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.20),
                  width: active ? 2 : 1,
                ),
                color: Colors.white.withValues(alpha: active ? 0.08 : 0.02),
              ),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white.withValues(alpha: active ? 0.78 : 0.45),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Pair {
  const _Pair({
    required this.index,
    required this.attack,
    required this.defense,
  });

  final int index;
  final Map<String, dynamic> attack;
  final Map<String, dynamic>? defense;
}

class _DurakTablePair extends StatelessWidget {
  const _DurakTablePair({
    required this.width,
    required this.index,
    required this.attack,
    required this.defense,
    required this.selected,
    required this.onSelect,
    required this.canAcceptDefense,
    required this.onDefenseDropped,
    required this.rankLabel,
    required this.suitLabel,
    required this.isRedSuit,
    required this.attackKeyForFlight,
    required this.defenseKeyForFlight,
  });

  final double width;
  final int index;
  final Map<String, dynamic> attack;
  final Map<String, dynamic>? defense;
  final bool selected;
  final VoidCallback onSelect;

  final bool Function(Map<String, dynamic> card, int attackIndex)
  canAcceptDefense;
  final Future<void> Function(int attackIndex, Map<String, dynamic> card)
  onDefenseDropped;

  final String Function(Map<String, dynamic>) rankLabel;
  final String Function(Map<String, dynamic>) suitLabel;
  final bool Function(String) isRedSuit;
  final GlobalKey attackKeyForFlight;
  final GlobalKey defenseKeyForFlight;

  @override
  Widget build(BuildContext context) {
    final ring = selected
        ? const Color(0xFF2E86FF).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.10);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Material(
        key: ValueKey<String>(
          'p:$index:a:${rankLabel(attack)}${suitLabel(attack)}:d:${defense == null ? '—' : '${rankLabel(defense!)}${suitLabel(defense!)}'}',
        ),
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSelect,
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ring, width: selected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 126,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform.rotate(
                          angle: -0.06,
                          child: Container(
                            key: attackKeyForFlight,
                            child: DurakCardWidget(
                              rankLabel: rankLabel(attack),
                              suitLabel: suitLabel(attack),
                              isRed: isRedSuit((attack['s'] ?? '').toString()),
                              faceUp: true,
                              disabled: true,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        top: 26,
                        child: DragTarget<Map<String, dynamic>>(
                          onWillAcceptWithDetails: (d) =>
                              canAcceptDefense(d.data, index),
                          onAcceptWithDetails: (d) =>
                              unawaited(onDefenseDropped(index, d.data)),
                          builder: (context, candidate, rejected) {
                            if (defense == null) {
                              final active = candidate.isNotEmpty;
                              return Container(
                                key: defenseKeyForFlight,
                                width: 68,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (active
                                                ? const Color(0xFF6EE7B7)
                                                : Colors.white.withValues(
                                                    alpha: 0.14,
                                                  ))
                                            .withValues(alpha: 0.9),
                                  ),
                                  color: Colors.white.withValues(
                                    alpha: active ? 0.07 : 0.02,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '—',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Transform.rotate(
                              angle: 0.05,
                              child: Container(
                                key: defenseKeyForFlight,
                                child: DurakCardWidget(
                                  rankLabel: rankLabel(defense!),
                                  suitLabel: suitLabel(defense!),
                                  isRed: isRedSuit(
                                    (defense!['s'] ?? '').toString(),
                                  ),
                                  faceUp: true,
                                  disabled: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 50,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
