import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'durak_card_flight_layer.dart';
import 'durak_felt_background.dart';
import 'durak_hand_fan.dart';
import 'durak_player_names.dart';
import 'durak_player_profiles.dart';
import 'durak_players_strip.dart';
import 'durak_primary_actions_bar.dart';
import 'durak_table_fly_fx.dart';
import 'durak_table_widget.dart';

class ConversationDurakGameScreen extends StatefulWidget {
  const ConversationDurakGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ConversationDurakGameScreen> createState() =>
      _ConversationDurakGameScreenState();
}

class _ConversationDurakGameScreenState
    extends State<ConversationDurakGameScreen> {
  Map<String, dynamic>? _selectedCard;
  String? _selectedCardId;
  int _selectedAttackIndex = 0;
  String _lastFoulAtShown = '';
  int _prevDefenderHandCount = 0;
  int _prevDiscardCount = 0;
  int _prevTableCards = 0;
  int _prevFxRevision = -1;
  int _tableFxNonce = 0;
  String _tableFxText = '';
  String _flyFxKind = '';
  int _flyFxCount = 0;

  final _deckKey = GlobalKey();
  final _handKey = GlobalKey();
  final _nextAttackSlotKey = GlobalKey();
  final _tableAttackKeys = <int, GlobalKey>{};
  final _tableDefenseKeys = <int, GlobalKey>{};
  final _handCardKeys = <String, GlobalKey>{};
  int _prevMyHandCount = 0;

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
    final rank = {'11': 'J', '12': 'Q', '13': 'K', '14': 'A'}[rr] ?? rr;
    final suitSym = {'S': '♠', 'H': '♥', 'D': '♦', 'C': '♣'}[suit] ?? suit;
    return '$rank$suitSym';
  }

  String _rankLabel(Map<String, dynamic> c) {
    final r = c['r'];
    if (r == 'JOKER') return 'J';
    final rr = (r ?? '').toString();
    return {'11': 'J', '12': 'Q', '13': 'K', '14': 'A'}[rr] ?? rr;
  }

  String _suitLabel(Map<String, dynamic> c) {
    final suit = (c['s'] ?? '').toString();
    return {'S': '♠', 'H': '♥', 'D': '♦', 'C': '♣'}[suit] ?? suit;
  }

  bool _isRedSuit(String suit) => suit == 'H' || suit == 'D';

  String _suitOf(Map<String, dynamic> c) => (c['s'] ?? '').toString();

  Map<String, dynamic> _cardPayload(Map<String, dynamic> card) {
    return <String, dynamic>{'r': card['r'], 's': card['s']};
  }

  String _cardId(Map<String, dynamic> card, int index) {
    // Stable enough for UI/animation even with duplicate jokers.
    return '${_cardLabel(card)}#$index';
  }

  GlobalKey _handKeyFor(String id) =>
      _handCardKeys.putIfAbsent(id, () => GlobalKey());

  GlobalKey _pairKeyForFlight(int attackIndex, {required bool defense}) {
    if (defense) {
      return _tableDefenseKeys.putIfAbsent(attackIndex, () => GlobalKey());
    }
    return _tableAttackKeys.putIfAbsent(attackIndex, () => GlobalKey());
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

  String? _currentThrowerUid({
    required List<String> seats,
    required String attackerUid,
    required String defenderUid,
    required Set<String> throwerUids,
    required Set<String> passedUids,
    required Map? handCounts,
  }) {
    if (seats.isEmpty) return null;
    final attackerIdx = seats.indexOf(attackerUid);
    final base = attackerIdx < 0
        ? seats
        : [...seats.sublist(attackerIdx), ...seats.sublist(0, attackerIdx)];
    for (final uid in base) {
      if (uid == defenderUid) continue;
      if (!throwerUids.contains(uid)) continue;
      if (passedUids.contains(uid)) continue;
      final hc = handCounts == null ? null : handCounts[uid];
      final n = int.tryParse((hc ?? '').toString()) ?? 0;
      if (n <= 0) continue;
      return uid;
    }
    return null;
  }

  Future<void> _tryAttack(Map<String, dynamic> card) async {
    await _sendMove(
      actionType: 'attack',
      payload: <String, dynamic>{'card': _cardPayload(card)},
    );
  }

  Future<void> _tryTransfer(Map<String, dynamic> card) async {
    await _sendMove(
      actionType: 'transfer',
      payload: <String, dynamic>{'card': _cardPayload(card)},
    );
  }

  Future<void> _tryDefend({
    required int attackIndex,
    required Map<String, dynamic> card,
  }) async {
    await _sendMove(
      actionType: 'defend',
      payload: <String, dynamic>{
        'attackIndex': attackIndex,
        'card': _cardPayload(card),
      },
    );
  }

  void _flySelectedTo(GlobalKey to, {required String trumpSuit}) {
    final id = _selectedCardId;
    final card = _selectedCard;
    if (id == null || card == null) return;
    final flight = DurakCardFlightLayer.of(context);
    if (flight == null) return;
    final from = _handKeyFor(id);
    flight.flyCard(
      from: from,
      to: to,
      rankLabel: _rankLabel(card),
      suitLabel: _suitLabel(card),
      isRed: _isRedSuit(_suitOf(card)),
    );
  }

  Future<void> _callFoul() async {
    await _sendMove(actionType: 'foul');
  }

  Future<void> _resolveBeat() async {
    await _sendMove(actionType: 'resolve');
  }

  Future<void> _surrender() async {
    await _sendMove(actionType: 'surrender');
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
    final gameRef = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId);
    final handRef = me == null
        ? null
        : gameRef.collection('privateHands').doc(me);

    return Scaffold(
      body: DurakFeltBackground(
        child: DurakCardFlightLayer(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                return Center(
                  child: Text(l10n.conversation_game_lobby_not_found),
                );
              }

              final g = game.data() ?? const <String, dynamic>{};
              final status = (g['status'] ?? '').toString();
              final publicView = g['publicView'] is Map
                  ? g['publicView'] as Map
                  : null;
              final settings = g['settings'] is Map
                  ? g['settings'] as Map
                  : null;
              final mode =
                  (settings == null
                          ? 'podkidnoy'
                          : (settings['mode'] ?? 'podkidnoy'))
                      .toString();
              final attackerUid =
                  (publicView == null ? '' : (publicView['attackerUid'] ?? ''))
                      .toString();
              final defenderUid =
                  (publicView == null ? '' : (publicView['defenderUid'] ?? ''))
                      .toString();

              Map<String, dynamic>? serverState;
              final serverStateRaw = g['serverState'];
              if (serverStateRaw is Map) {
                serverState = Map<String, dynamic>.from(serverStateRaw);
              }
              final defenderTaking =
                  serverState != null && serverState['taking'] == true;

              final tableRaw = publicView == null ? null : publicView['table'];
              final table = tableRaw is Map
                  ? Map<Object?, Object?>.from(tableRaw)
                  : null;
              final attacksRaw = table == null ? null : table['attacks'];
              final defensesRaw = table == null ? null : table['defenses'];
              final attacks = attacksRaw is List ? attacksRaw : const [];
              final defenses = defensesRaw is List ? defensesRaw : const [];
              final maxAttackIndex = attacks.isEmpty ? 0 : attacks.length - 1;
              if (_selectedAttackIndex > maxAttackIndex) {
                _selectedAttackIndex = maxAttackIndex;
              }

              final trumpSuit =
                  (publicView == null ? '' : (publicView['trumpSuit'] ?? ''))
                      .toString();
              final discardCount =
                  (publicView == null ? 0 : (publicView['discardCount'] ?? 0))
                      is int
                  ? (publicView!['discardCount'] as int)
                  : int.tryParse(
                          (publicView == null
                                  ? '0'
                                  : (publicView['discardCount'] ?? '0'))
                              .toString(),
                        ) ??
                        0;
              final handCountsRaw = publicView == null
                  ? null
                  : publicView['handCounts'];
              final handCounts = handCountsRaw is Map ? handCountsRaw : null;
              final defenderHandCount = handCounts != null
                  ? int.tryParse((handCounts[defenderUid] ?? '').toString()) ??
                        0
                  : 0;
              final phase =
                  (publicView == null ? '' : (publicView['phase'] ?? ''))
                      .toString();
              final passedRaw = publicView == null
                  ? null
                  : publicView['passedUids'];
              final passedUids = passedRaw is List
                  ? passedRaw.map((e) => e.toString()).toSet()
                  : <String>{};
              final throwersRaw = publicView == null
                  ? null
                  : publicView['throwerUids'];
              final throwerUids = throwersRaw is List
                  ? throwersRaw.map((e) => e.toString()).toSet()
                  : <String>{};
              final shulerRaw = publicView == null
                  ? null
                  : publicView['shuler'];
              final shuler = shulerRaw is Map
                  ? Map<String, dynamic>.from(shulerRaw)
                  : null;
              final shulerEnabled = shuler != null && shuler['enabled'] == true;
              final lastCheatUid = shuler == null
                  ? ''
                  : (shuler['lastCheatUid'] ?? '').toString();
              final foulRaw = shuler == null ? null : shuler['foulEvent'];
              final foulEvent = foulRaw is Map
                  ? Map<String, dynamic>.from(foulRaw)
                  : null;
              final foulAt = foulEvent == null
                  ? ''
                  : (foulEvent['at'] ?? '').toString();
              final foulMissedRaw = foulEvent == null
                  ? null
                  : foulEvent['missedUids'];
              final foulMissed = foulMissedRaw is List
                  ? foulMissedRaw.map((e) => e.toString()).toList()
                  : const <String>[];
              final pendingRaw = shuler == null
                  ? null
                  : shuler['pendingResolution'];
              final pendingResolution = pendingRaw is Map
                  ? Map<String, dynamic>.from(pendingRaw)
                  : null;
              final hasPendingResolution = pendingResolution != null;

              final seatsRaw = publicView == null ? null : publicView['seats'];
              final seats = seatsRaw is List
                  ? seatsRaw.map((e) => e.toString()).toList()
                  : const <String>[];
              final fallbackThrowerUid = _currentThrowerUid(
                seats: seats,
                attackerUid: attackerUid,
                defenderUid: defenderUid,
                throwerUids: throwerUids,
                passedUids: passedUids,
                handCounts: handCounts,
              );
              final hasServerThrowerUid =
                  publicView != null &&
                  publicView.containsKey('currentThrowerUid');
              final serverThrowerUid = hasServerThrowerUid
                  ? (publicView['currentThrowerUid'] ?? '').toString()
                  : '';
              final activeThrowerUid = hasServerThrowerUid
                  ? (serverThrowerUid.isEmpty ? null : serverThrowerUid)
                  : fallbackThrowerUid;

              final hasSelected = _selectedCard != null;
              final ranksOnTable = _tableRanks(attacks, defenses);
              final tableHasAttacks = attacks.isNotEmpty;
              final allDefended =
                  tableHasAttacks &&
                  defenses.length == attacks.length &&
                  defenses.every((d) => d is Map);
              bool defenseSlotOpenAt(int attackIndex) => _isDefenseSlotOpen(
                attacks: attacks,
                defenses: defenses,
                attackIndex: attackIndex,
              );
              final roundLimitRaw = publicView == null
                  ? null
                  : publicView['roundDefenderHandLimit'];
              final roundDefenderHandLimit = roundLimitRaw is int
                  ? roundLimitRaw
                  : int.tryParse((roundLimitRaw ?? '').toString());
              final canThrowIn =
                  attacks.length < 6 &&
                  attacks.length <
                      (roundDefenderHandLimit ??
                          (defenderHandCount <= 0 ? 99 : defenderHandCount));

              bool cardCanAttack(Map<String, dynamic> card) {
                final rank = (card['r'] ?? '').toString();
                final isJoker = _isJoker(card);
                if (status != 'active' || me == null) return false;
                if (tableHasAttacks) {
                  // UX matches server: throw-ins are turn-based.
                  final isMyTurn =
                      activeThrowerUid != null && me == activeThrowerUid;
                  return isMyTurn &&
                      canThrowIn &&
                      me != defenderUid &&
                      (isJoker || ranksOnTable.contains(rank));
                }
                return me == attackerUid;
              }

              bool cardCanDefendAt(Map<String, dynamic> card, int attackIndex) {
                if (status != 'active' || me == null) return false;
                if (me != defenderUid) return false;
                if (!tableHasAttacks) return false;
                if (!defenseSlotOpenAt(attackIndex)) return false;
                if (attackIndex < 0 || attackIndex >= attacks.length) {
                  return false;
                }
                if (trumpSuit.isEmpty) return false;
                final attackRaw = attacks[attackIndex];
                if (attackRaw is! Map) return false;
                final attack = Map<String, dynamic>.from(attackRaw);
                return _beats(
                  attack: attack,
                  defense: card,
                  trumpSuit: trumpSuit,
                );
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

              final canPass =
                  status == 'active' &&
                  me != null &&
                  me != defenderUid &&
                  tableHasAttacks &&
                  !passedUids.contains(me) &&
                  (activeThrowerUid != null && me == activeThrowerUid);

              final canAttack =
                  status == 'active' &&
                  me != null &&
                  hasSelected &&
                  cardCanAttack(_selectedCard!);

              final canDefend =
                  status == 'active' &&
                  me != null &&
                  hasSelected &&
                  cardCanDefendAt(_selectedCard!, _selectedAttackIndex);

              final canTake =
                  status == 'active' &&
                  me != null &&
                  me == defenderUid &&
                  tableHasAttacks;

              final canFinishTurnRaw = publicView == null
                  ? null
                  : publicView['canFinishTurn'];
              final canFinishTurn = canFinishTurnRaw is bool
                  ? canFinishTurnRaw
                  : allDefended && activeThrowerUid == null;

              final canBeat =
                  status == 'active' &&
                  me != null &&
                  me == attackerUid &&
                  canFinishTurn;

              final canTransfer =
                  status == 'active' &&
                  me != null &&
                  hasSelected &&
                  cardCanTransfer(_selectedCard!);

              final canFoul =
                  status == 'active' &&
                  shulerEnabled &&
                  me != null &&
                  lastCheatUid.isNotEmpty &&
                  me != lastCheatUid &&
                  hasPendingResolution;

              final canResolve =
                  status == 'active' &&
                  shulerEnabled &&
                  me != null &&
                  me == attackerUid &&
                  hasPendingResolution;

              final primaryCandidates =
                  <({String id, String label, VoidCallback onTap})>[];
              if (canBeat) {
                primaryCandidates.add((
                  id: 'beat',
                  label: l10n.conversation_durak_action_beat,
                  onTap: () => unawaited(_sendMove(actionType: 'finishTurn')),
                ));
              }
              if (canTake) {
                primaryCandidates.add((
                  id: 'take',
                  label: l10n.conversation_durak_action_take,
                  onTap: () => unawaited(_sendMove(actionType: 'take')),
                ));
              }
              if (canPass) {
                primaryCandidates.add((
                  id: 'pass',
                  label: l10n.conversation_durak_action_pass,
                  onTap: () => unawaited(_sendMove(actionType: 'pass')),
                ));
              }
              if (canResolve) {
                primaryCandidates.add((
                  id: 'resolve',
                  label: l10n.conversation_durak_action_resolve,
                  onTap: () => unawaited(_resolveBeat()),
                ));
              }
              final primaryActions = primaryCandidates
                  .take(2)
                  .map((e) => (label: e.label, onTap: e.onTap))
                  .toList();
              final primaryIds = primaryCandidates
                  .take(2)
                  .map((e) => e.id)
                  .toSet();

              final overflowActions = <({String label, VoidCallback onTap})>[];
              if (canAttack && hasSelected) {
                overflowActions.add((
                  label: l10n.conversation_durak_action_attack,
                  onTap: () => unawaited(() async {
                    _flySelectedTo(_nextAttackSlotKey, trumpSuit: trumpSuit);
                    await _sendMove(
                      actionType: 'attack',
                      payload: <String, dynamic>{
                        'card': _cardPayload(_selectedCard!),
                      },
                    );
                  }()),
                ));
              }
              if (canDefend && hasSelected) {
                overflowActions.add((
                  label: l10n.conversation_durak_action_defend,
                  onTap: () => unawaited(() async {
                    _flySelectedTo(
                      _pairKeyForFlight(_selectedAttackIndex, defense: true),
                      trumpSuit: trumpSuit,
                    );
                    await _sendMove(
                      actionType: 'defend',
                      payload: <String, dynamic>{
                        'attackIndex': _selectedAttackIndex,
                        'card': _cardPayload(_selectedCard!),
                      },
                    );
                  }()),
                ));
              }
              if (canTransfer && hasSelected) {
                overflowActions.add((
                  label: l10n.conversation_durak_action_transfer,
                  onTap: () => unawaited(() async {
                    _flySelectedTo(_nextAttackSlotKey, trumpSuit: trumpSuit);
                    await _sendMove(
                      actionType: 'transfer',
                      payload: <String, dynamic>{
                        'card': _cardPayload(_selectedCard!),
                      },
                    );
                  }()),
                ));
              }
              if (canFoul) {
                overflowActions.add((
                  label: l10n.conversation_durak_action_foul,
                  onTap: () => unawaited(_callFoul()),
                ));
              }
              if (canResolve && !primaryIds.contains('resolve')) {
                overflowActions.add((
                  label: l10n.conversation_durak_action_resolve,
                  onTap: () => unawaited(_resolveBeat()),
                ));
              }

              final resultRaw = publicView == null
                  ? null
                  : publicView['result'];
              final result = resultRaw is Map
                  ? Map<String, dynamic>.from(resultRaw)
                  : null;
              final isFinished =
                  status == 'finished' || phase == 'finished' || result != null;
              final rev =
                  (publicView == null ? -1 : (publicView['revision'] ?? -1))
                      is int
                  ? (publicView!['revision'] as int)
                  : int.tryParse(
                          (publicView == null
                                  ? '-1'
                                  : (publicView['revision'] ?? '-1'))
                              .toString(),
                        ) ??
                        -1;

              // AAA-ish FX: detect table clear and fly cards to discard/hand.
              scheduleMicrotask(() {
                if (!mounted) return;
                if (rev >= 0 && rev == _prevFxRevision) return;
                final clearedNow = attacks.isEmpty && defenses.isEmpty;
                final defendedNow = defenses.whereType<Map>().length;
                final tableCardsNow = attacks.length + defendedNow;
                // Use defender hand delta as a hint for "take".
                final took =
                    clearedNow &&
                    defenderHandCount > _prevDefenderHandCount &&
                    _prevDefenderHandCount > 0;
                final beat =
                    clearedNow &&
                    discardCount > _prevDiscardCount &&
                    _prevTableCards > 0;

                if (took || beat) {
                  setState(() {
                    _tableFxNonce++;
                    _tableFxText = took ? 'Взял' : 'Бито';
                    _flyFxKind = took ? 'take' : 'beat';
                    _flyFxCount = _prevTableCards <= 0 ? 6 : _prevTableCards;
                  });
                }
                _prevDefenderHandCount = defenderHandCount;
                _prevDiscardCount = discardCount;
                _prevTableCards = tableCardsNow;
                _prevFxRevision = rev;
              });

              if (isFinished) {
                final winnersRaw = result == null ? null : result['winners'];
                final winners = winnersRaw is List
                    ? winnersRaw.map((e) => e.toString()).toList()
                    : const <String>[];
                final loserUid = result == null
                    ? ''
                    : (result['loserUid'] ?? '').toString();
                final allUids = <String>{
                  ...winners,
                  loserUid,
                }.where((s) => s.isNotEmpty).toList();
                return DurakPlayerNames(
                  uids: allUids,
                  builder: (context, nameByUid) {
                    final loserName = loserUid.isEmpty
                        ? ''
                        : (nameByUid[loserUid] ?? loserUid);
                    final winnerNames = winners
                        .map((u) => nameByUid[u] ?? u)
                        .toList();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.conversation_durak_game_finished_title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              loserUid.isEmpty
                                  ? l10n.conversation_durak_game_finished_no_loser
                                  : l10n.conversation_durak_game_finished_loser(
                                      loserName,
                                    ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.conversation_durak_game_finished_winners(
                                winnerNames.isEmpty
                                    ? '—'
                                    : winnerNames.join(', '),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.common_close),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return Column(
                children: [
                  if (foulAt.isNotEmpty && foulAt != _lastFoulAtShown)
                    Builder(
                      builder: (context) {
                        scheduleMicrotask(() {
                          if (!mounted) return;
                          setState(() => _lastFoulAtShown = foulAt);
                          _toast(l10n.conversation_durak_foul_toast);
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Назад',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.conversation_games_durak,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Сдаться',
                            onPressed: status == 'active' && me != null
                                ? () => unawaited(_surrender())
                                : null,
                            icon: const Icon(Icons.flag_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                    child: DurakPlayersStrip(
                      l10n: l10n,
                      seats: seats,
                      attackerUid: attackerUid,
                      defenderUid: defenderUid,
                      throwerUids: throwerUids,
                      passedUids: passedUids,
                      activeThrowerUid: activeThrowerUid,
                      handCounts: handCounts,
                      me: me,
                      defenderTaking: defenderTaking,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          top: 6,
                          child: Container(
                            key: _deckKey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              'Колода: ${(publicView == null ? 0 : (publicView['deckCount'] ?? 0)).toString()}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              'Сброс: $discardCount',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (trumpSuit.isNotEmpty)
                          Positioned(
                            top: 6,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Text(
                                  'Козырь: ${{'S': '♠', 'H': '♥', 'D': '♦', 'C': '♣'}[trumpSuit] ?? trumpSuit}',
                                  style: TextStyle(
                                    color:
                                        (trumpSuit == 'H' || trumpSuit == 'D')
                                        ? const Color(
                                            0xFFF87171,
                                          ).withValues(alpha: 0.92)
                                        : Colors.white.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 48, 12, 16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: DurakTableWidget(
                                key: ValueKey<String>(
                                  't:${(publicView == null ? '' : (publicView['revision'] ?? '')).toString()}',
                                ),
                                pairKeyForFlight: _pairKeyForFlight,
                                nextAttackSlotKey: _nextAttackSlotKey,
                                attacks: attacks,
                                defenses: defenses,
                                selectedAttackIndex: _selectedAttackIndex,
                                onSelectAttackIndex: (i) =>
                                    setState(() => _selectedAttackIndex = i),
                                canAcceptDefense: (card, idx) =>
                                    cardCanDefendAt(card, idx),
                                canAcceptAttack: cardCanAttack,
                                onAttackDropped: (card) {
                                  final flight = DurakCardFlightLayer.of(
                                    context,
                                  );
                                  if (flight != null) {
                                    flight.flyCard(
                                      from: _handKey,
                                      to: _nextAttackSlotKey,
                                      rankLabel: _rankLabel(card),
                                      suitLabel: _suitLabel(card),
                                      isRed: _isRedSuit(_suitOf(card)),
                                    );
                                  }
                                  return _tryAttack(card);
                                },
                                canAcceptTransfer: cardCanTransfer,
                                onTransferDropped: (card) {
                                  final flight = DurakCardFlightLayer.of(
                                    context,
                                  );
                                  if (flight != null) {
                                    flight.flyCard(
                                      from: _handKey,
                                      to: _nextAttackSlotKey,
                                      rankLabel: _rankLabel(card),
                                      suitLabel: _suitLabel(card),
                                      isRed: _isRedSuit(_suitOf(card)),
                                    );
                                  }
                                  return _tryTransfer(card);
                                },
                                onDefenseDropped: (idx, card) {
                                  final flight = DurakCardFlightLayer.of(
                                    context,
                                  );
                                  if (flight != null) {
                                    flight.flyCard(
                                      from: _handKey,
                                      to: _pairKeyForFlight(idx, defense: true),
                                      rankLabel: _rankLabel(card),
                                      suitLabel: _suitLabel(card),
                                      isRed: _isRedSuit(_suitOf(card)),
                                    );
                                  }
                                  return _tryDefend(
                                    attackIndex: idx,
                                    card: card,
                                  );
                                },
                                rankLabel: _rankLabel,
                                suitLabel: _suitLabel,
                                isRedSuit: _isRedSuit,
                              ),
                            ),
                          ),
                        ),
                        if (foulAt.isNotEmpty && foulMissed.isNotEmpty)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 8,
                            child: _FoulBanner(missedUids: foulMissed),
                          ),
                        if (_tableFxText.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: _TableFxOverlay(
                                key: ValueKey<int>(_tableFxNonce),
                                text: _tableFxText,
                                onDone: () {
                                  if (!mounted) return;
                                  setState(() => _tableFxText = '');
                                },
                              ),
                            ),
                          ),
                        if (_flyFxKind.isNotEmpty)
                          Positioned.fill(
                            child: DurakTableFlyFx(
                              key: ValueKey<int>(_tableFxNonce),
                              kind: _flyFxKind,
                              cardCount: _flyFxCount,
                              onDone: () {
                                if (!mounted) return;
                                setState(() {
                                  _flyFxKind = '';
                                  _flyFxCount = 0;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasPendingResolution && shulerEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: _PendingResolutionBanner(
                        isAttacker: me == attackerUid,
                      ),
                    ),
                  DurakPrimaryActionsBar(
                    l10n: l10n,
                    primaryActions: primaryActions,
                    overflowActions: overflowActions,
                  ),
                  if (handRef == null)
                    const SizedBox.shrink()
                  else
                    Container(
                      key: _handKey,
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
                          final d =
                              handSnap.data?.data() ??
                              const <String, dynamic>{};
                          final cardsRaw = d['cards'];
                          final cards = cardsRaw is List ? cardsRaw : const [];
                          final flight = DurakCardFlightLayer.of(context);
                          // Deal/draw animation: deck -> hand for new cards (count diff).
                          scheduleMicrotask(() {
                            if (!mounted) return;
                            if (flight == null) return;
                            final now = cards.length;
                            if (_prevMyHandCount == 0) {
                              _prevMyHandCount = now;
                              return;
                            }
                            final delta = now - _prevMyHandCount;
                            if (delta > 0) {
                              flight.flyBacks(
                                from: _deckKey,
                                to: _handKey,
                                count: delta,
                              );
                            }
                            _prevMyHandCount = now;
                          });

                          List<Map<String, dynamic>> maps = cards
                              .whereType<Map>()
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList();
                          // Sort hand: non-trump suits first, then trump, then jokers; within suit by rank.
                          maps.sort((a, b) {
                            final aj = _isJoker(a);
                            final bj = _isJoker(b);
                            if (aj != bj) return aj ? 1 : -1;
                            final as = _suitOf(a);
                            final bs = _suitOf(b);
                            final at = as == trumpSuit;
                            final bt = bs == trumpSuit;
                            if (at != bt) return at ? 1 : -1;
                            final suitCmp = as.compareTo(bs);
                            if (suitCmp != 0) return suitCmp;
                            return _rankValue(a).compareTo(_rankValue(b));
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.conversation_durak_hand_title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: DurakHandFan(
                                    key: ValueKey<int>(maps.length),
                                    cards: maps,
                                    cardId: _cardId,
                                    keyForCardId: _handKeyFor,
                                    rankLabel: _rankLabel,
                                    suitLabel: _suitLabel,
                                    isRedSuit: _isRedSuit,
                                    enabled: (card) =>
                                        cardCanAttack(card) ||
                                        cardCanDefendAt(
                                          card,
                                          _selectedAttackIndex,
                                        ) ||
                                        cardCanTransfer(card),
                                    highlight: (card) =>
                                        cardCanAttack(card) ||
                                        cardCanDefendAt(
                                          card,
                                          _selectedAttackIndex,
                                        ) ||
                                        cardCanTransfer(card),
                                    selectedId: _selectedCardId,
                                    onTap: (card, id) {
                                      final enabled =
                                          cardCanAttack(card) ||
                                          cardCanDefendAt(
                                            card,
                                            _selectedAttackIndex,
                                          ) ||
                                          cardCanTransfer(card);
                                      if (!enabled) return;
                                      final canA = cardCanAttack(card);
                                      final canD = cardCanDefendAt(
                                        card,
                                        _selectedAttackIndex,
                                      );
                                      final canT = cardCanTransfer(card);
                                      final options = <String>[
                                        if (canA) 'attack',
                                        if (canD) 'defend',
                                        if (canT) 'transfer',
                                      ];

                                      // If the action is unambiguous, play immediately.
                                      if (options.length == 1) {
                                        final action = options.first;
                                        if (action == 'attack') {
                                          unawaited(_tryAttack(card));
                                          return;
                                        }
                                        if (action == 'transfer') {
                                          unawaited(_tryTransfer(card));
                                          return;
                                        }
                                        if (action == 'defend') {
                                          unawaited(
                                            _tryDefend(
                                              attackIndex: _selectedAttackIndex,
                                              card: card,
                                            ),
                                          );
                                          return;
                                        }
                                      }

                                      setState(() {
                                        _selectedCard = card;
                                        _selectedCardId = id;
                                      });
                                    },
                                    onDragAcceptedByTable: (_) {},
                                    onDragRejected: (_) =>
                                        _toast('Ход недоступен'),
                                  ),
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
        ),
      ),
    );
  }
}

// _HandCard was replaced by DurakHandFan.

class _FoulBanner extends StatefulWidget {
  const _FoulBanner({required this.missedUids});

  final List<String> missedUids;

  @override
  State<_FoulBanner> createState() => _FoulBannerState();
}

class _FoulBannerState extends State<_FoulBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.70, end: 1.0).animate(_c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFFC107).withValues(alpha: 0.16),
          border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.35),
          ),
        ),
        child: DurakPlayerProfiles(
          uids: widget.missedUids,
          builder: (context, byUid) {
            final chips = widget.missedUids.map((uid) {
              final p = byUid[uid];
              final name = p?.name ?? uid;
              final avatar = (p?.avatarThumb?.trim().isNotEmpty ?? false)
                  ? p!.avatarThumb!.trim()
                  : ((p?.avatar?.trim().isNotEmpty ?? false)
                        ? p!.avatar!.trim()
                        : null);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundImage: avatar == null
                          ? null
                          : NetworkImage(avatar),
                      child: avatar == null
                          ? const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sentiment_very_dissatisfied_rounded,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Шулер! Не заметили:',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingResolutionBanner extends StatelessWidget {
  const _PendingResolutionBanner({required this.isAttacker});

  final bool isAttacker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAttacker
                  ? 'Ожидание фолла… Нажми «Подтвердить Бито», если все согласны.'
                  : 'Ожидание фолла… Теперь можно нажать «Фолл!», если заметил шулерство.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableFxOverlay extends StatefulWidget {
  const _TableFxOverlay({super.key, required this.text, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  State<_TableFxOverlay> createState() => _TableFxOverlayState();
}

class _TableFxOverlayState extends State<_TableFxOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _c.forward();
    Future<void>.delayed(const Duration(milliseconds: 720), widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.06).animate(anim),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
