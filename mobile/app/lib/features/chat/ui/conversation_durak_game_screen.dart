import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';

class ConversationDurakGameScreen extends StatefulWidget {
  const ConversationDurakGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ConversationDurakGameScreen> createState() =>
      _ConversationDurakGameScreenState();
}

class _ConversationDurakGameScreenState extends State<ConversationDurakGameScreen> {
  Map<String, dynamic>? _selectedCard;
  int _selectedAttackIndex = 0;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _cardLabel(Map<String, dynamic> c) {
    final r = c['r'];
    final s = c['s'];
    if (r == 'JOKER') return 'JOKER';
    final rr = (r ?? '').toString();
    final suit = (s ?? '').toString();
    final rank = {
      '11': 'J',
      '12': 'Q',
      '13': 'K',
      '14': 'A',
    }[rr] ??
        rr;
    final suitSym = {
      'S': '♠',
      'H': '♥',
      'D': '♦',
      'C': '♣',
    }[suit] ??
        suit;
    return '$rank$suitSym';
  }

  bool _isRedSuit(String suit) => suit == 'H' || suit == 'D';

  String _suitOf(Map<String, dynamic> c) => (c['s'] ?? '').toString();

  Map<String, dynamic> _cardPayload(Map<String, dynamic> card) {
    return <String, dynamic>{
      'r': card['r'],
      's': card['s'],
    };
  }

  bool _isJoker(Map<String, dynamic> c) => c['r'] == 'JOKER';

  int _rankValue(Map<String, dynamic> c) {
    final r = c['r'];
    if (r is int) return r;
    final parsed = int.tryParse((r ?? '').toString());
    return parsed ?? 0;
  }

  bool _beats({
    required Map<String, dynamic> attack,
    required Map<String, dynamic> defense,
    required String trumpSuit,
  }) {
    if (_isJoker(defense)) return true;
    if (_isJoker(attack)) return false;
    final asuit = (attack['s'] ?? '').toString();
    final dsuit = (defense['s'] ?? '').toString();
    if (asuit.isEmpty || dsuit.isEmpty) return false;
    if (asuit == dsuit) return _rankValue(defense) > _rankValue(attack);
    if (dsuit == trumpSuit && asuit != trumpSuit) return true;
    return false;
  }

  Set<String> _tableRanks(List attacks, List defenses) {
    final s = <String>{};
    for (final a in attacks) {
      if (a is Map) s.add((a['r'] ?? '').toString());
    }
    for (final d in defenses) {
      if (d is Map) s.add((d['r'] ?? '').toString());
    }
    return s;
  }

  bool _isDefenseSlotOpen({
    required List attacks,
    required List defenses,
    required int attackIndex,
  }) {
    if (attackIndex < 0 || attackIndex >= attacks.length) return false;
    if (attackIndex < defenses.length) return defenses[attackIndex] == null;
    return true;
  }

  Future<void> _sendMove({
    required String actionType,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await GamesCallables().makeDurakMove(
        gameId: widget.gameId,
        clientMoveId: DateTime.now().microsecondsSinceEpoch.toString(),
        actionType: actionType,
        payload: payload,
      );
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final gameRef =
        FirebaseFirestore.instance.collection('games').doc(widget.gameId);
    final handRef = me == null
        ? null
        : gameRef.collection('privateHands').doc(me);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conversation_games_durak)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: gameRef.snapshots(),
        builder: (context, gameSnap) {
          if (!gameSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (gameSnap.hasError) {
            return Center(
              child: Text(
                l10n.conversation_game_lobby_error(
                  (gameSnap.error ?? 'unknown').toString(),
                ),
              ),
            );
          }
          final game = gameSnap.data!;
          if (!game.exists) {
            return Center(child: Text(l10n.conversation_game_lobby_not_found));
          }

          final g = game.data() ?? const <String, dynamic>{};
          final status = (g['status'] ?? '').toString();
          final publicView =
              g['publicView'] is Map ? g['publicView'] as Map : null;
          final settings = g['settings'] is Map ? g['settings'] as Map : null;
          final mode = (settings == null ? 'podkidnoy' : (settings['mode'] ?? 'podkidnoy')).toString();
          final attackerUid =
              (publicView == null ? '' : (publicView['attackerUid'] ?? ''))
                  .toString();
          final defenderUid =
              (publicView == null ? '' : (publicView['defenderUid'] ?? ''))
                  .toString();
          final myRole = me == null
              ? ''
              : (me == attackerUid
                  ? l10n.conversation_durak_role_attacker
                  : (me == defenderUid
                      ? l10n.conversation_durak_role_defender
                      : l10n.conversation_durak_role_thrower));

          final tableRaw = publicView == null ? null : publicView['table'];
          final table = tableRaw is Map ? Map<Object?, Object?>.from(tableRaw) : null;
          final attacksRaw = table == null ? null : table['attacks'];
          final defensesRaw = table == null ? null : table['defenses'];
          final attacks = attacksRaw is List ? attacksRaw : const [];
          final defenses = defensesRaw is List ? defensesRaw : const [];
          final maxAttackIndex = attacks.isEmpty ? 0 : attacks.length - 1;
          if (_selectedAttackIndex > maxAttackIndex) {
            _selectedAttackIndex = maxAttackIndex;
          }

          final trumpSuit = (publicView == null ? '' : (publicView['trumpSuit'] ?? '')).toString();
          final handCountsRaw = publicView == null ? null : publicView['handCounts'];
          final handCounts = handCountsRaw is Map ? handCountsRaw : null;
          final defenderHandCount = handCounts != null
              ? int.tryParse((handCounts[defenderUid] ?? '').toString()) ?? 0
              : 0;

          final hasSelected = _selectedCard != null;
          final selectedRank = hasSelected ? (_selectedCard!['r'] ?? '').toString() : '';
          final selectedIsJoker = hasSelected && _isJoker(_selectedCard!);
          final ranksOnTable = _tableRanks(attacks, defenses);
          final tableHasAttacks = attacks.isNotEmpty;
          final allDefended = tableHasAttacks &&
              defenses.length == attacks.length &&
              defenses.every((d) => d is Map);
          final defenseSlotOpen = _isDefenseSlotOpen(
            attacks: attacks,
            defenses: defenses,
            attackIndex: _selectedAttackIndex,
          );
          final canThrowIn =
              attacks.length < 6 && attacks.length < (defenderHandCount <= 0 ? 99 : defenderHandCount);

          bool cardCanAttack(Map<String, dynamic> card) {
            final rank = (card['r'] ?? '').toString();
            final isJoker = _isJoker(card);
            if (status != 'active' || me == null) return false;
            if (tableHasAttacks) {
              return canThrowIn &&
                  me != defenderUid &&
                  (isJoker || ranksOnTable.contains(rank));
            }
            return me == attackerUid;
          }

          bool cardCanDefend(Map<String, dynamic> card) {
            if (status != 'active' || me == null) return false;
            if (me != defenderUid) return false;
            if (!tableHasAttacks) return false;
            if (!defenseSlotOpen) return false;
            if (_selectedAttackIndex < 0 || _selectedAttackIndex >= attacks.length) return false;
            if (trumpSuit.isEmpty) return false;
            final attackRaw = attacks[_selectedAttackIndex];
            if (attackRaw is! Map) return false;
            final attack = Map<String, dynamic>.from(attackRaw);
            return _beats(attack: attack, defense: card, trumpSuit: trumpSuit);
          }

          bool cardCanTransfer(Map<String, dynamic> card) {
            final rank = (card['r'] ?? '').toString();
            final isJoker = _isJoker(card);
            if (status != 'active' || me == null) return false;
            if (me != defenderUid) return false;
            if (mode != 'perevodnoy') return false;
            if (!tableHasAttacks) return false;
            if (!canThrowIn) return false;
            return isJoker || ranksOnTable.contains(rank);
          }

          final canAttack = status == 'active' &&
              me != null &&
              hasSelected &&
              cardCanAttack(_selectedCard!);

          final canDefend = status == 'active' &&
              me != null &&
              hasSelected &&
              cardCanDefend(_selectedCard!);

          final canTake = status == 'active' &&
              me != null &&
              me == defenderUid &&
              tableHasAttacks;

          final canBeat = status == 'active' &&
              me != null &&
              me == attackerUid &&
              allDefended;

          final canTransfer = status == 'active' &&
              me != null &&
              hasSelected &&
              cardCanTransfer(_selectedCard!);

          final available = <String>[
            if (canAttack) l10n.conversation_durak_action_attack,
            if (canDefend) l10n.conversation_durak_action_defend,
            if (canTake) l10n.conversation_durak_action_take,
            if (canBeat) l10n.conversation_durak_action_beat,
            if (canTransfer) l10n.conversation_durak_action_transfer,
          ];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.conversation_game_lobby_status(status)} · $myRole',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  children: [
                    Text(
                      l10n.conversation_durak_table_title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < attacks.length; i++)
                      _TableRow(
                        attack: attacks[i] is Map
                            ? Map<String, dynamic>.from(attacks[i] as Map)
                            : const <String, dynamic>{},
                        defense: i < defenses.length && defenses[i] is Map
                            ? Map<String, dynamic>.from(defenses[i] as Map)
                            : null,
                        selected: i == _selectedAttackIndex,
                        attackIndex: i,
                        onSelect: () => setState(() => _selectedAttackIndex = i),
                        cardLabel: _cardLabel,
                      ),
                    const SizedBox(height: 16),
                    if (available.isNotEmpty) ...[
                      Text(
                        '${l10n.common_choose}: ${available.join(' · ')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: canAttack
                              ? () => unawaited(
                                    _sendMove(
                                      actionType: 'attack',
                                      payload: <String, dynamic>{
                                        'card': _cardPayload(_selectedCard!),
                                      },
                                    ),
                                  )
                              : null,
                          child: Text(l10n.conversation_durak_action_attack),
                        ),
                        FilledButton(
                          onPressed: canDefend
                              ? () => unawaited(
                                    _sendMove(
                                      actionType: 'defend',
                                      payload: <String, dynamic>{
                                        'attackIndex': _selectedAttackIndex,
                                        'card': _cardPayload(_selectedCard!),
                                      },
                                    ),
                                  )
                              : null,
                          child: Text(l10n.conversation_durak_action_defend),
                        ),
                        OutlinedButton(
                          onPressed: canTake
                              ? () => unawaited(
                                    _sendMove(actionType: 'take'),
                                  )
                              : null,
                          child: Text(l10n.conversation_durak_action_take),
                        ),
                        OutlinedButton(
                          onPressed: canBeat
                              ? () => unawaited(
                                    _sendMove(actionType: 'finishTurn'),
                                  )
                              : null,
                          child: Text(l10n.conversation_durak_action_beat),
                        ),
                        OutlinedButton(
                          onPressed: canTransfer
                              ? () => unawaited(
                                    _sendMove(
                                      actionType: 'transfer',
                                      payload: <String, dynamic>{
                                        'card': _cardPayload(_selectedCard!),
                                      },
                                    ),
                                  )
                              : null,
                          child: Text(l10n.conversation_durak_action_transfer),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (handRef == null)
                const SizedBox.shrink()
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: handRef.snapshots(),
                    builder: (context, handSnap) {
                      final d = handSnap.data?.data() ?? const <String, dynamic>{};
                      final cardsRaw = d['cards'];
                      final cards = cardsRaw is List ? cardsRaw : const [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.conversation_durak_hand_title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final c0 in cards)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _CardChip(
                                      label: c0 is Map
                                          ? _cardLabel(
                                              Map<String, dynamic>.from(c0 as Map),
                                            )
                                          : '?',
                                      selected: _selectedCard != null &&
                                          c0 is Map &&
                                          _cardLabel(
                                                Map<String, dynamic>.from(c0 as Map),
                                              ) ==
                                              _cardLabel(_selectedCard!),
                                      enabled: c0 is Map &&
                                          (() {
                                            final card = Map<String, dynamic>.from(c0 as Map);
                                            return cardCanAttack(card) ||
                                                cardCanDefend(card) ||
                                                cardCanTransfer(card);
                                          })(),
                                      isRed: c0 is Map &&
                                          _isRedSuit(
                                            _suitOf(
                                              Map<String, dynamic>.from(c0 as Map),
                                            ),
                                          ),
                                      onTap: c0 is Map
                                          ? () {
                                              final card = Map<String, dynamic>.from(c0 as Map);
                                              final enabled = cardCanAttack(card) ||
                                                  cardCanDefend(card) ||
                                                  cardCanTransfer(card);
                                              if (!enabled) return;
                                              setState(() => _selectedCard = card);
                                            }
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.attack,
    required this.defense,
    required this.selected,
    required this.attackIndex,
    required this.onSelect,
    required this.cardLabel,
  });

  final Map<String, dynamic> attack;
  final Map<String, dynamic>? defense;
  final bool selected;
  final int attackIndex;
  final VoidCallback onSelect;
  final String Function(Map<String, dynamic>) cardLabel;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.06);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Text('#${attackIndex + 1}'),
              const SizedBox(width: 10),
              Expanded(child: Text(cardLabel(attack))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(defense == null ? '—' : cardLabel(defense!)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.isRed,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool isRed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgBase = selected
        ? const Color(0xFF2E86FF).withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.08);
    final bg = enabled ? bgBase : bgBase.withValues(alpha: 0.05);
    final borderBase = selected
        ? const Color(0xFF2E86FF).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.18);
    final border = enabled ? borderBase : borderBase.withValues(alpha: 0.10);
    final fgBase = isRed ? const Color(0xFFFF6B6B) : const Color(0xFFF2F4FA);
    final fg = enabled ? fgBase.withValues(alpha: 0.95) : fgBase.withValues(alpha: 0.40);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: fg),
          ),
        ),
      ),
    );
  }
}

