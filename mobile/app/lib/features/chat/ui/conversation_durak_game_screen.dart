import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'durak_card_widget.dart';
import 'conversation_durak_lobby_screen.dart';
import 'durak_felt_background.dart';
import 'durak_hand_fan.dart';
import 'durak_player_names.dart';
import 'durak_player_profiles.dart';
import 'durak_draw_flight.dart';
import 'durak_primary_actions_bar.dart';
import 'durak_table_widget.dart';

class ConversationDurakGameScreen extends StatefulWidget {
  const ConversationDurakGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ConversationDurakGameScreen> createState() =>
      _ConversationDurakGameScreenState();
}

class _PendingDurakMove {
  const _PendingDurakMove({
    required this.clientMoveId,
    required this.actionType,
    required this.card,
    required this.baseRevision,
    this.attackIndex,
  });

  final String clientMoveId;
  final String actionType;
  final Map<String, dynamic> card;
  final int baseRevision;
  final int? attackIndex;
}

class _ConversationDurakGameScreenState
    extends State<ConversationDurakGameScreen> {
  static const bool _durakTraceLayout = kDebugMode;
  Map<String, dynamic>? _selectedCard;
  String? _selectedCardId;
  int _selectedAttackIndex = 0;
  String _lastFoulAtShown = '';
  String _lastCheatPassedUid = '';
  bool _showEmojiBurst = false;
  int _prevDefenderHandCount = 0;
  int _prevDiscardCount = 0;
  int _prevTableCards = 0;
  int _prevFxRevision = -1;
  int _tableFxNonce = 0;
  String _tableFxText = '';
  int _legalRevision = -1;
  int _publicRevision = -1;
  bool _legalCanTake = false;
  bool _legalCanPass = false;
  bool _legalCanFinishTurn = false;
  Set<String> _legalAttackKeys = const <String>{};
  Set<String> _legalTransferKeys = const <String>{};
  Map<int, Set<String>> _legalDefenseTargets = const <int, Set<String>>{};
  late final Timer _turnTimerTicker;
  DateTime _turnTimerNow = DateTime.now();
  _PendingDurakMove? _pendingMove;
  bool _isRematchBusy = false;
  double? _lastHandGlobalY;

  final _deckKey = GlobalKey();
  final _handKey = GlobalKey();
  final _tableOverlayKey = GlobalKey();
  final _nextAttackSlotKey = GlobalKey();
  final _tableAttackKeys = <int, GlobalKey>{};
  final _tableDefenseKeys = <int, GlobalKey>{};
  final _handCardKeys = <String, GlobalKey>{};
  int _prevMyHandCount = 0;
  final List<_DrawFlight> _drawFlights = <_DrawFlight>[];
  int _drawFlightSeq = 0;
  bool _actionInFlight = false;
  FlutterExceptionHandler? _prevFlutterOnError;
  late final FlutterExceptionHandler _durakFlutterOnError;

  @override
  void initState() {
    super.initState();
    _turnTimerTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _turnTimerNow = DateTime.now());
    });
    _prevFlutterOnError = FlutterError.onError;
    _durakFlutterOnError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains(
        'TransformLayer is constructed with an invalid matrix',
      )) {
        debugPrint(
          '[DurakMatrix][${widget.gameId}] invalid matrix; '
          'publicRev=$_publicRevision '
          'legalRev=$_legalRevision '
          'selectedCard=${_selectedCardId ?? "-"} '
          'pendingMove=${_pendingMove?.actionType ?? "-"}',
        );
      }
      _prevFlutterOnError?.call(details);
    };
    FlutterError.onError = _durakFlutterOnError;
  }

  @override
  void dispose() {
    if (FlutterError.onError == _durakFlutterOnError) {
      FlutterError.onError = _prevFlutterOnError;
    }
    _turnTimerTicker.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _traceLayoutJump({
    required int tableCards,
    required int handCards,
    required int deckCount,
    required int discardCount,
  }) {
    if (!_durakTraceLayout) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _handKey.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) return;
      final top = ro.localToGlobal(Offset.zero);
      if (!top.dx.isFinite || !top.dy.isFinite) {
        debugPrint(
          '[DurakLayoutJump][${widget.gameId}] non-finite hand origin: '
          'x=${top.dx} y=${top.dy}',
        );
        return;
      }
      final prev = _lastHandGlobalY;
      _lastHandGlobalY = top.dy;
      if (prev == null) return;
      final delta = (top.dy - prev).abs();
      if (delta < 90) return;
      final screen = MediaQuery.sizeOf(context);
      final safe = MediaQuery.paddingOf(context);
      debugPrint(
        '[DurakLayoutJump][${widget.gameId}] handY jump: '
        'from=${prev.toStringAsFixed(1)} to=${top.dy.toStringAsFixed(1)} '
        'delta=${delta.toStringAsFixed(1)} '
        'screen=${screen.width.toStringAsFixed(1)}x${screen.height.toStringAsFixed(1)} '
        'safeT=${safe.top.toStringAsFixed(1)} safeB=${safe.bottom.toStringAsFixed(1)} '
        'tableCards=$tableCards handCards=$handCards deck=$deckCount discard=$discardCount '
        'pending=${_pendingMove?.actionType ?? '-'}',
      );
    });
  }

  bool _isActiveGameAlreadyExistsError(Object error) {
    final upper = error.toString().toUpperCase();
    return upper.contains("ACTIVE_GAME_ALREADY_EXISTS") ||
        upper.contains("GAME_ALREADY_ACTIVE");
  }

  Future<bool> _openLatestDurakLobby({required String conversationId}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('gameLobbies')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      String? gameId;
      for (final d in snap.docs) {
        final data = d.data();
        final status = (data['status'] ?? '').toString();
        final type = (data['type'] ?? 'durak').toString();
        if (type == 'durak' && (status == 'lobby' || status == 'active')) {
          gameId = d.id;
          break;
        }
      }
      if (!mounted || gameId == null) return false;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDurakLobbyScreen(gameId: gameId!),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRematchPressed({required String conversationId}) async {
    if (_isRematchBusy) return;
    if (!mounted) return;
    setState(() => _isRematchBusy = true);
    try {
      final res = await GamesCallables().createDurakRematch(
        gameId: widget.gameId,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDurakLobbyScreen(gameId: res.gameId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final upper = e.toString().toUpperCase();
      if (conversationId.isNotEmpty &&
          (_isActiveGameAlreadyExistsError(e) ||
              upper.contains('INTERNAL') ||
              upper.contains('REMATCH_FAILED_RETRY'))) {
        final opened = await _openLatestDurakLobby(
          conversationId: conversationId,
        );
        if (opened) return;
      }
      _toast(friendlyGamesCallableError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _isRematchBusy = false);
    }
  }

  void _scheduleDrawFlights(int count) {
    if (count <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final deckCtx = _deckKey.currentContext;
      final handCtx = _handKey.currentContext;
      final overlayCtx = _tableOverlayKey.currentContext;
      final deckBox = deckCtx?.findRenderObject();
      final handBox = handCtx?.findRenderObject();
      final overlayBox = overlayCtx?.findRenderObject();
      if (deckBox is! RenderBox ||
          handBox is! RenderBox ||
          overlayBox is! RenderBox) {
        return;
      }
      if (!deckBox.hasSize || !handBox.hasSize || !overlayBox.hasSize) return;
      final from = deckBox.localToGlobal(Offset.zero) & deckBox.size;
      final to = handBox.localToGlobal(Offset.zero) & handBox.size;
      final overlayTopLeft = overlayBox.localToGlobal(Offset.zero);
      final n = count.clamp(1, 6);
      setState(() {
        for (var i = 0; i < n; i++) {
          _drawFlightSeq++;
          _drawFlights.add(
            _DrawFlight(
              id: _drawFlightSeq,
              from: from,
              to: to,
              overlayTopLeft: overlayTopLeft,
              delay: Duration(milliseconds: i * 100),
            ),
          );
        }
      });
    });
  }

  void _removeDrawFlight(int id) {
    if (!mounted) return;
    setState(() {
      _drawFlights.removeWhere((f) => f.id == id);
    });
  }

  Future<void> _handleNextTournamentGamePressed({
    required String tournamentId,
    Map<String, dynamic>? settings,
  }) async {
    if (_isRematchBusy) return;
    if (!mounted) return;
    setState(() => _isRematchBusy = true);
    try {
      final res = await GamesCallables().createTournamentDurakLobby(
        tournamentId: tournamentId,
        settings: settings ?? const <String, dynamic>{},
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDurakLobbyScreen(gameId: res.gameId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(friendlyGamesCallableError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _isRematchBusy = false);
    }
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
    if (r == 'JOKER') return 'JKR';
    final rr = (r ?? '').toString();
    return {'11': 'J', '12': 'Q', '13': 'K', '14': 'A'}[rr] ?? rr;
  }

  String _suitLabel(Map<String, dynamic> c) {
    if (c['r'] == 'JOKER') return '*';
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

  String _cardKey(Map<String, dynamic> card) {
    if (_isJoker(card)) return 'JOKER';
    return '${(card['s'] ?? '').toString()}:${(card['r'] ?? '').toString()}';
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
      optimisticCard: card,
    );
  }

  Future<void> _tryTransfer(Map<String, dynamic> card) async {
    await _sendMove(
      actionType: 'transfer',
      payload: <String, dynamic>{'card': _cardPayload(card)},
      optimisticCard: card,
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
      optimisticCard: card,
      optimisticAttackIndex: attackIndex,
    );
  }

  Future<void> _callFoul(Map<String, dynamic> card) async {
    await _sendMove(
      actionType: 'foul',
      payload: <String, dynamic>{'card': _cardPayload(card)},
    );
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
    Map<String, dynamic>? optimisticCard,
    int? optimisticAttackIndex,
  }) async {
    if (_actionInFlight) return;
    final clientMoveId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _actionInFlight = true;
      if (optimisticCard != null) {
        _pendingMove = _PendingDurakMove(
          clientMoveId: clientMoveId,
          actionType: actionType,
          card: Map<String, dynamic>.from(optimisticCard),
          attackIndex: optimisticAttackIndex,
          baseRevision: _publicRevision,
        );
        _selectedCard = null;
        _selectedCardId = null;
      }
    });
    try {
      await GamesCallables().makeDurakMove(
        gameId: widget.gameId,
        clientMoveId: clientMoveId,
        actionType: actionType,
        payload: payload,
      );
      if (!mounted) return;
      setState(() {
        _selectedCard = null;
        _selectedCardId = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (optimisticCard != null) {
        setState(() => _pendingMove = null);
      }
      _toast(friendlyGamesCallableError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  bool _sameCard(Map<String, dynamic> a, Map<String, dynamic> b) {
    return _cardKey(a) == _cardKey(b);
  }

  List<Map<String, dynamic>> _hidePendingCardFromHand(
    List<Map<String, dynamic>> cards,
  ) {
    final pending = _pendingMove;
    if (pending == null) return cards;
    if (pending.actionType != 'attack' &&
        pending.actionType != 'transfer' &&
        pending.actionType != 'defend') {
      return cards;
    }
    var removed = false;
    final visible = <Map<String, dynamic>>[];
    for (final card in cards) {
      if (!removed && _sameCard(card, pending.card)) {
        removed = true;
        continue;
      }
      visible.add(card);
    }
    return visible;
  }

  ({List attacks, List defenses}) _optimisticTable({
    required List attacks,
    required List defenses,
  }) {
    final pending = _pendingMove;
    if (pending == null) return (attacks: attacks, defenses: defenses);
    final nextAttacks = List<dynamic>.from(attacks);
    final nextDefenses = List<dynamic>.from(defenses);
    if (pending.actionType == 'attack' || pending.actionType == 'transfer') {
      nextAttacks.add(pending.card);
      nextDefenses.add(null);
    } else if (pending.actionType == 'defend') {
      final idx = pending.attackIndex;
      if (idx != null && idx >= 0 && idx < nextAttacks.length) {
        while (nextDefenses.length <= idx) {
          nextDefenses.add(null);
        }
        nextDefenses[idx] = pending.card;
      }
    }
    return (attacks: nextAttacks, defenses: nextDefenses);
  }

  void _syncLegalMoves(Map<String, dynamic>? legal) {
    if (legal == null) {
      if (_legalRevision < 0) return;
      scheduleMicrotask(() {
        if (!mounted) return;
        setState(() {
          _legalRevision = -1;
          _legalCanTake = false;
          _legalCanPass = false;
          _legalCanFinishTurn = false;
          _legalAttackKeys = const <String>{};
          _legalTransferKeys = const <String>{};
          _legalDefenseTargets = const <int, Set<String>>{};
        });
      });
      return;
    }
    final rev = legal['revision'] is int
        ? legal['revision'] as int
        : int.tryParse((legal['revision'] ?? '').toString()) ?? -1;
    final attackKeys = ((legal['attackCardKeys'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final transferKeys = ((legal['transferCardKeys'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final defenseTargets = <int, Set<String>>{};
    final defenseRaw = legal['defenseTargets'];
    if (defenseRaw is List) {
      for (final item in defenseRaw) {
        if (item is! Map) continue;
        final idx = item['attackIndex'] is int
            ? item['attackIndex'] as int
            : int.tryParse((item['attackIndex'] ?? '').toString());
        final keysRaw = item['cardKeys'];
        if (idx == null || keysRaw is! List) continue;
        defenseTargets[idx] = keysRaw.map((e) => e.toString()).toSet();
      }
    }
    if (rev == _legalRevision &&
        _legalCanTake == (legal['canTake'] == true) &&
        _legalCanPass == (legal['canPass'] == true) &&
        _legalCanFinishTurn == (legal['canFinishTurn'] == true)) {
      return;
    }
    scheduleMicrotask(() {
      if (!mounted) return;
      setState(() {
        _legalRevision = rev;
        _legalCanTake = legal['canTake'] == true;
        _legalCanPass = legal['canPass'] == true;
        _legalCanFinishTurn = legal['canFinishTurn'] == true;
        _legalAttackKeys = attackKeys;
        _legalTransferKeys = transferKeys;
        _legalDefenseTargets = defenseTargets;
      });
    });
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
            final conversationId = (g['conversationId'] ?? '').toString();
            if (status == 'lobby') {
              return ConversationDurakLobbyScreen(gameId: widget.gameId);
            }
            final publicView = g['publicView'] is Map
                ? g['publicView'] as Map
                : null;
            final settings = g['settings'] is Map ? g['settings'] as Map : null;
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
            final trumpCardRaw = publicView == null
                ? null
                : publicView['trumpCard'];
            final trumpCard = trumpCardRaw is Map
                ? Map<String, dynamic>.from(trumpCardRaw)
                : null;
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
            final deckCount =
                (publicView == null ? 0 : (publicView['deckCount'] ?? 0)) is int
                ? (publicView!['deckCount'] as int)
                : int.tryParse(
                        (publicView == null
                                ? '0'
                                : (publicView['deckCount'] ?? '0'))
                            .toString(),
                      ) ??
                      0;
            final handCountsRaw = publicView == null
                ? null
                : publicView['handCounts'];
            final handCounts = handCountsRaw is Map ? handCountsRaw : null;
            final defenderHandCount = handCounts != null
                ? int.tryParse((handCounts[defenderUid] ?? '').toString()) ?? 0
                : 0;
            final phase =
                (publicView == null ? '' : (publicView['phase'] ?? ''))
                    .toString();
            final turnUid =
                (publicView == null ? '' : (publicView['turnUid'] ?? ''))
                    .toString();
            final turnStartedAt = publicView == null
                ? ''
                : (publicView['turnStartedAt'] ?? '').toString();
            final turnDeadlineAt = publicView == null
                ? ''
                : (publicView['turnDeadlineAt'] ?? '').toString();
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
            final shulerRaw = publicView == null ? null : publicView['shuler'];
            final shuler = shulerRaw is Map
                ? Map<String, dynamic>.from(shulerRaw)
                : null;
            final shulerEnabled = shuler != null && shuler['enabled'] == true;
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
            final cheatPassedUid = shuler == null
                ? ''
                : (shuler['cheatPassedUid'] ?? '').toString();

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
              if (_legalRevision >= 0) {
                return _legalAttackKeys.contains(_cardKey(card));
              }
              final rank = (card['r'] ?? '').toString();
              final isJoker = _isJoker(card);
              if (status != 'active' || me == null) return false;
              if (me == defenderUid) return false;
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
              if (_legalRevision >= 0) {
                return _legalDefenseTargets[attackIndex]?.contains(
                      _cardKey(card),
                    ) ??
                    false;
              }
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
              if (_legalRevision >= 0) {
                return _legalTransferKeys.contains(_cardKey(card));
              }
              final rank = (card['r'] ?? '').toString();
              final isJoker = _isJoker(card);
              if (status != 'active' || me == null) return false;
              if (me != defenderUid) return false;
              if (mode != 'perevodnoy') return false;
              if (!tableHasAttacks) return false;
              if (!canThrowIn) return false;
              return isJoker || ranksOnTable.contains(rank);
            }

            final canPassClient = status == 'active' &&
                me != null &&
                me != defenderUid &&
                tableHasAttacks &&
                !passedUids.contains(me) &&
                (activeThrowerUid != null && me == activeThrowerUid);
            final canPass = (_legalRevision >= 0 && _legalCanPass) || canPassClient;

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

            final isTaking = phase == 'throwIn';
            final canTakeClient = status == 'active' &&
                me != null &&
                me == defenderUid &&
                tableHasAttacks &&
                !isTaking;
            final canTake = ((_legalRevision >= 0 && _legalCanTake) || canTakeClient) && !isTaking;

            final canTransfer =
                status == 'active' &&
                me != null &&
                hasSelected &&
                cardCanTransfer(_selectedCard!);

            String myTurnLabel = '';
            if (status == 'active' && me != null) {
              final isMyMove = (attacks.isEmpty &&
                      me == attackerUid &&
                      me != defenderUid) ||
                  (tableHasAttacks &&
                      me == defenderUid &&
                      phase == 'defense') ||
                  (activeThrowerUid != null &&
                      me == activeThrowerUid &&
                      me != defenderUid);
              if (isMyMove) myTurnLabel = AppLocalizations.of(context)!.durak_your_turn;
            }

            final primaryCandidates =
                <({String id, String label, VoidCallback onTap})>[];
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
                onTap: () => unawaited(_tryAttack(_selectedCard!)),
              ));
            }
            if (canDefend && hasSelected) {
              overflowActions.add((
                label: l10n.conversation_durak_action_defend,
                onTap: () => unawaited(
                  _tryDefend(
                    attackIndex: _selectedAttackIndex,
                    card: _selectedCard!,
                  ),
                ),
              ));
            }
            if (canTransfer && hasSelected) {
              overflowActions.add((
                label: l10n.conversation_durak_action_transfer,
                onTap: () => unawaited(_tryTransfer(_selectedCard!)),
              ));
            }

            final resultRaw = publicView == null ? null : publicView['result'];
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
            _publicRevision = rev;
            if (_pendingMove != null && rev > _pendingMove!.baseRevision) {
              scheduleMicrotask(() {
                if (!mounted) return;
                setState(() => _pendingMove = null);
              });
            }
            final optimisticTable = _optimisticTable(
              attacks: attacks,
              defenses: defenses,
            );
            final tableAttacks = optimisticTable.attacks;
            final tableDefenses = optimisticTable.defenses;

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
                  _tableFxText = took ? AppLocalizations.of(context)!.durak_took : AppLocalizations.of(context)!.durak_beaten;
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
              final winnerUid = winners.isNotEmpty ? winners.first : '';
              return DurakPlayerProfiles(
                uids: allUids,
                builder: (context, byUid) {
                  String fallback(String uid) {
                    if (uid.isEmpty) return '—';
                    if (uid.length <= 10) return uid;
                    return '${uid.substring(0, 5)}…${uid.substring(uid.length - 3)}';
                  }

                  final winnerProfile = byUid[winnerUid];
                  final winnerName = winnerProfile?.name ?? fallback(winnerUid);
                  final loserName = loserUid.isEmpty
                      ? ''
                      : (byUid[loserUid]?.name ?? fallback(loserUid));
                  final tournamentId =
                      (g['tournamentId'] ?? '').toString().trim();
                  final isTournamentGame = tournamentId.isNotEmpty;
                  final settingsMap = g['settings'] is Map
                      ? Map<String, dynamic>.from(g['settings'] as Map)
                      : <String, dynamic>{};
                  return _DurakFinishedCard(
                    winnerName: winnerName,
                    winnerAvatarUrl:
                        winnerProfile?.avatarThumb ?? winnerProfile?.avatar,
                    loserLabel: loserUid.isEmpty
                        ? l10n.conversation_durak_game_finished_no_loser
                        : l10n.conversation_durak_game_finished_loser(
                            loserName,
                          ),
                    rematchBusy: _isRematchBusy,
                    isTournamentGame: isTournamentGame,
                    tournamentId: isTournamentGame ? tournamentId : null,
                    onRematch: () => unawaited(
                      _handleRematchPressed(conversationId: conversationId),
                    ),
                    onBackToChat: () => Navigator.of(context).pop(),
                    onNextTournamentGame: isTournamentGame
                        ? () => unawaited(
                              _handleNextTournamentGamePressed(
                                tournamentId: tournamentId,
                                settings: settingsMap,
                              ),
                            )
                        : null,
                  );
                },
              );
            }

            Widget buildHand() {
              if (handRef == null) return const SizedBox.shrink();
              return RepaintBoundary(
                child: Container(
                  key: _handKey,
                  width: double.infinity,
                  height: 110,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  alignment: Alignment.bottomCenter,
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: handRef.snapshots(),
                    builder: (context, handSnap) {
                      final d =
                          handSnap.data?.data() ?? const <String, dynamic>{};
                      final cardsRaw = d['cards'];
                      final cards = cardsRaw is List ? cardsRaw : const [];
                      final legalRaw = d['legalMoves'];
                      final legal = legalRaw is Map
                          ? Map<String, dynamic>.from(legalRaw)
                          : null;
                      _syncLegalMoves(legal);
                      final attackKeys =
                          ((legal?['attackCardKeys'] as List?) ?? const [])
                              .map((e) => e.toString())
                              .toSet();
                      final transferKeys =
                          ((legal?['transferCardKeys'] as List?) ?? const [])
                              .map((e) => e.toString())
                              .toSet();
                      final defenseTargets = <int, Set<String>>{};
                      final defenseRaw = legal?['defenseTargets'];
                      if (defenseRaw is List) {
                        for (final item in defenseRaw) {
                          if (item is! Map) continue;
                          final idx = item['attackIndex'] is int
                              ? item['attackIndex'] as int
                              : int.tryParse(
                                  (item['attackIndex'] ?? '').toString(),
                                );
                          final keysRaw = item['cardKeys'];
                          if (idx == null || keysRaw is! List) continue;
                          defenseTargets[idx] = keysRaw
                              .map((e) => e.toString())
                              .toSet();
                        }
                      }
                      bool serverCanAttack(Map<String, dynamic> card) =>
                          legal == null
                          ? cardCanAttack(card)
                          : attackKeys.contains(_cardKey(card));
                      bool serverCanTransfer(Map<String, dynamic> card) =>
                          legal == null
                          ? cardCanTransfer(card)
                          : transferKeys.contains(_cardKey(card));
                      int? serverDefenseIndexFor(Map<String, dynamic> card) {
                        for (final entry in defenseTargets.entries) {
                          if (entry.value.contains(_cardKey(card))) {
                            return entry.key;
                          }
                        }
                        for (var i = 0; i < attacks.length; i++) {
                          if (cardCanDefendAt(card, i)) return i;
                        }
                        return null;
                      }

                      bool serverCanDefendAny(Map<String, dynamic> card) =>
                          serverDefenseIndexFor(card) != null;

                      scheduleMicrotask(() {
                        if (!mounted) return;
                        final now = cards.length;
                        if (_prevMyHandCount == 0) {
                          _prevMyHandCount = now;
                          return;
                        }
                        if (now > _prevMyHandCount) {
                          _scheduleDrawFlights(now - _prevMyHandCount);
                        }
                        _prevMyHandCount = now;
                      });

                      final maps = cards
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList();
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
                      final visibleMaps = _hidePendingCardFromHand(maps);
                      _traceLayoutJump(
                        tableCards: tableAttacks.length + tableDefenses.length,
                        handCards: visibleMaps.length,
                        deckCount: deckCount,
                        discardCount: discardCount,
                      );

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: DurakHandFan(
                          cards: visibleMaps,
                          cardId: _cardId,
                          keyForCardId: _handKeyFor,
                          rankLabel: _rankLabel,
                          suitLabel: _suitLabel,
                          isRedSuit: _isRedSuit,
                          isTrump: (card) =>
                              !_isJoker(card) &&
                              _suitOf(card) == trumpSuit,
                          enabled: (card) =>
                              _pendingMove == null &&
                              (serverCanAttack(card) ||
                                  serverCanDefendAny(card) ||
                                  serverCanTransfer(card)),
                          highlight: (card) =>
                              _pendingMove == null &&
                              (serverCanAttack(card) ||
                                  serverCanDefendAny(card) ||
                                  serverCanTransfer(card)),
                          selectedId: _selectedCardId,
                          onTap: (card, id) {
                            final canA = serverCanAttack(card);
                            final defenseIndex = serverDefenseIndexFor(card);
                            final canD = defenseIndex != null;
                            final canT = serverCanTransfer(card);
                            if (_pendingMove != null) return;
                            if (!canA && !canD && !canT) return;
                            final options = <String>[
                              if (canA) 'attack',
                              if (canD) 'defend',
                              if (canT) 'transfer',
                            ];
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
                              unawaited(
                                _tryDefend(
                                  attackIndex:
                                      defenseIndex ?? _selectedAttackIndex,
                                  card: card,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _selectedCard = card;
                              _selectedCardId = id;
                            });
                          },
                          onDragStarted: (card, id) {
                            if (!_durakTraceLayout) return;
                            final ctx = _handKeyFor(id).currentContext;
                            final ro = ctx?.findRenderObject();
                            if (ro is RenderBox && ro.hasSize) {
                              final p = ro.localToGlobal(Offset.zero);
                              debugPrint(
                                '[DurakDrag][${widget.gameId}] start '
                                'id=$id card=${_cardLabel(card)} '
                                'x=${p.dx.toStringAsFixed(1)} '
                                'y=${p.dy.toStringAsFixed(1)} '
                                'w=${ro.size.width.toStringAsFixed(1)} '
                                'h=${ro.size.height.toStringAsFixed(1)}',
                              );
                            } else {
                              debugPrint(
                                '[DurakDrag][${widget.gameId}] start id=$id '
                                'card=${_cardLabel(card)} renderBox=none',
                              );
                            }
                          },
                          onDragAcceptedByTable: (_) {},
                          onDragRejected: (_) {},
                        ),
                      );
                    },
                  ),
                ),
              );
            }

            final safe = MediaQuery.paddingOf(context);
            final bottomPanelHeight = 174.0 + safe.bottom;

            return Stack(
              key: _tableOverlayKey,
              fit: StackFit.expand,
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
                if (cheatPassedUid.isNotEmpty &&
                    cheatPassedUid != _lastCheatPassedUid)
                  Builder(
                    builder: (context) {
                      scheduleMicrotask(() {
                        if (!mounted) return;
                        setState(() {
                          _lastCheatPassedUid = cheatPassedUid;
                          _showEmojiBurst = true;
                        });
                        Future<void>.delayed(
                          const Duration(seconds: 3),
                          () {
                            if (!mounted) return;
                            setState(() => _showEmojiBurst = false);
                          },
                        );
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                Positioned.fill(
                  bottom: bottomPanelHeight,
                  child: Stack(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: Row(
                            children: [
                              IconButton.filled(
                                tooltip: AppLocalizations.of(context)!.durak_end_game_tooltip,
                                onPressed: status == 'active' && me != null
                                    ? () => unawaited(_surrender())
                                    : null,
                                icon: const Icon(Icons.flag_rounded),
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: AppLocalizations.of(context)!.durak_close_tooltip,
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 58,
                        left: 0,
                        right: 0,
                        child: _DurakTopOpponent(
                          seats: seats,
                          me: me,
                          attackerUid: attackerUid,
                          defenderUid: defenderUid,
                          activeThrowerUid: activeThrowerUid,
                          turnUid: turnUid,
                          turnStartedAt: turnStartedAt,
                          turnDeadlineAt: turnDeadlineAt,
                          now: _turnTimerNow,
                          handCounts: handCounts,
                        ),
                      ),
                      if (deckCount > 0)
                        Positioned(
                          left: 12,
                          top: 118,
                          child: Container(
                            key: _deckKey,
                            child: _DurakSideDeck(
                              deckCount: deckCount,
                              trumpSuit: trumpSuit,
                              trumpCard: trumpCard,
                            ),
                          ),
                        )
                      else if (trumpSuit.isNotEmpty)
                        Positioned(
                          left: 12,
                          top: 118,
                          child: _TrumpSuitBadge(trumpSuit: trumpSuit),
                        ),
                      Positioned(
                        right: 12,
                        top: 112,
                        child: _DurakDiscardPile(discardCount: discardCount),
                      ),
                      Positioned.fill(
                        top: 140,
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: DurakTableWidget(
                          key: ValueKey<String>(
                            't:${(publicView == null ? '' : (publicView['revision'] ?? '')).toString()}',
                          ),
                          pairKeyForFlight: _pairKeyForFlight,
                          nextAttackSlotKey: _nextAttackSlotKey,
                          attacks: tableAttacks,
                          defenses: tableDefenses,
                          selectedAttackIndex: _selectedAttackIndex,
                          onSelectAttackIndex: (i) =>
                              setState(() => _selectedAttackIndex = i),
                          canAcceptDefense: (card, idx) =>
                              _pendingMove == null &&
                              cardCanDefendAt(card, idx),
                          canAcceptAttack: (card) =>
                              _pendingMove == null && cardCanAttack(card),
                          onAttackDropped: _tryAttack,
                          canAcceptTransfer: (card) =>
                              _pendingMove == null && cardCanTransfer(card),
                          onTransferDropped: _tryTransfer,
                          onDefenseDropped: (idx, card) =>
                              _tryDefend(attackIndex: idx, card: card),
                          rankLabel: _rankLabel,
                          suitLabel: _suitLabel,
                          isRedSuit: _isRedSuit,
                          shulerFoulMode: shulerEnabled && status == 'active',
                          onShulerFoulCardTap: (shulerEnabled && status == 'active')
                              ? (card) => unawaited(_callFoul(card))
                              : null,
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
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (myTurnLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                            child: _TurnStatusPill(text: myTurnLabel),
                          ),
                        DurakPrimaryActionsBar(
                          l10n: l10n,
                          primaryActions:
                              _actionInFlight ? const [] : primaryActions,
                          overflowActions:
                              _actionInFlight ? const [] : overflowActions,
                        ),
                        buildHand(),
                      ],
                    ),
                  ),
                ),
                if (_drawFlights.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Stack(
                        children: [
                          for (final f in _drawFlights)
                            DurakDrawFlight(
                              key: ValueKey<int>(f.id),
                              from: f.from,
                              to: f.to,
                              overlayTopLeft: f.overlayTopLeft,
                              delay: f.delay,
                              onDone: () => _removeDrawFlight(f.id),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_showEmojiBurst)
                  const Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: _EmojiBurstOverlay(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawFlight {
  const _DrawFlight({
    required this.id,
    required this.from,
    required this.to,
    required this.overlayTopLeft,
    required this.delay,
  });

  final int id;
  final Rect from;
  final Rect to;
  final Offset overlayTopLeft;
  final Duration delay;
}

// _HandCard was replaced by DurakHandFan.

const _burstEmojis = ['😂', '🤣', '😈', '🃏', '💀', '😏', '🫵', '🤡', '😹', '👺'];

class _EmojiBurstOverlay extends StatefulWidget {
  const _EmojiBurstOverlay();

  @override
  State<_EmojiBurstOverlay> createState() => _EmojiBurstOverlayState();
}

class _EmojiBurstOverlayState extends State<_EmojiBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_EmojiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(30, (i) {
      return _EmojiParticle(
        emoji: _burstEmojis[i % _burstEmojis.length],
        left: rng.nextDouble(),
        delay: rng.nextDouble() * 0.8,
        size: 20 + rng.nextDouble() * 28,
        drift: -30 + rng.nextDouble() * 60,
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            for (final p in _particles)
              Builder(
                builder: (context) {
                  final t = (_ctrl.value - p.delay / 3.0).clamp(0.0, 1.0);
                  if (t <= 0) return const SizedBox.shrink();
                  final opacity = t < 0.5 ? 1.0 : (1.0 - (t - 0.5) * 2.0).clamp(0.0, 1.0);
                  return Positioned(
                    left: p.left * MediaQuery.sizeOf(context).width + p.drift * t,
                    bottom: -40 + t * (MediaQuery.sizeOf(context).height * 1.2),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: t * 6.28,
                        child: Transform.scale(
                          scale: 0.3 + t * 0.7,
                          child: Text(
                            p.emoji,
                            style: TextStyle(fontSize: p.size),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _EmojiParticle {
  const _EmojiParticle({
    required this.emoji,
    required this.left,
    required this.delay,
    required this.size,
    required this.drift,
  });

  final String emoji;
  final double left;
  final double delay;
  final double size;
  final double drift;
}

class _TurnStatusPill extends StatelessWidget {
  const _TurnStatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFB7F7E4).withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF155E52),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _DurakTopOpponent extends StatelessWidget {
  const _DurakTopOpponent({
    required this.seats,
    required this.me,
    required this.attackerUid,
    required this.defenderUid,
    required this.activeThrowerUid,
    required this.turnUid,
    required this.turnStartedAt,
    required this.turnDeadlineAt,
    required this.now,
    required this.handCounts,
  });

  final List<String> seats;
  final String? me;
  final String attackerUid;
  final String defenderUid;
  final String? activeThrowerUid;
  final String turnUid;
  final String turnStartedAt;
  final String turnDeadlineAt;
  final DateTime now;
  final Map? handCounts;

  @override
  Widget build(BuildContext context) {
    final opponentUid = seats.firstWhere(
      (uid) => uid.trim().isNotEmpty && uid != me,
      orElse: () => '',
    );
    if (opponentUid.isEmpty) return const SizedBox.shrink();
    final role = opponentUid == defenderUid
        ? AppLocalizations.of(context)!.durak_role_beats
        : (opponentUid == attackerUid
              ? AppLocalizations.of(context)!.durak_role_move
              : (opponentUid == activeThrowerUid ? AppLocalizations.of(context)!.durak_role_throw : ''));
    final count =
        int.tryParse(
          (handCounts == null ? '' : (handCounts![opponentUid] ?? ''))
              .toString(),
        ) ??
        0;
    final active =
        opponentUid == defenderUid ||
        opponentUid == attackerUid ||
        opponentUid == activeThrowerUid;
    final start = DateTime.tryParse(turnStartedAt);
    final deadline = DateTime.tryParse(turnDeadlineAt);
    final timerActive =
        turnUid == opponentUid && start != null && deadline != null;
    final progress = timerActive && deadline.isAfter(start)
        ? (now.difference(start).inMilliseconds /
                  deadline.difference(start).inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;

    return DurakPlayerNames(
      uids: <String>[opponentUid],
      builder: (context, nameByUid) {
        final name = nameByUid[opponentUid] ?? opponentUid;
        return DurakPlayerProfiles(
          uids: <String>[opponentUid],
          builder: (context, byUid) {
            final p = byUid[opponentUid];
            final avatarUrl = ((p?.avatarThumb ?? p?.avatar) ?? '').trim();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (timerActive)
                              SizedBox(
                                width: 76,
                                height: 76,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFA3E635),
                                      ),
                                ),
                              )
                            else if (active)
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFA3E635),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ClipOval(
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: avatarUrl.isNotEmpty
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.22),
                                                  child: const Icon(
                                                    Icons.person_rounded,
                                                    color: Colors.white70,
                                                    size: 30,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        color: Colors.white.withValues(
                                          alpha: 0.22,
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Colors.white70,
                                          size: 30,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0,
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _DurakOpponentCardsFan(count: count),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DurakOpponentCardsFan extends StatelessWidget {
  const _DurakOpponentCardsFan({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final visible = count <= 0 ? 0 : (count > 6 ? 6 : count);
    if (visible == 0) return const SizedBox(height: 12);
    return SizedBox(
      width: 84,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * 10.0,
              child: Transform.rotate(
                angle: (-0.18 + i * 0.06),
                child: const DurakCardWidget(
                  rankLabel: '',
                  suitLabel: '',
                  isRed: false,
                  faceUp: false,
                  disabled: true,
                  width: 26,
                  height: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurakSideDeck extends StatelessWidget {
  const _DurakSideDeck({
    required this.deckCount,
    required this.trumpSuit,
    required this.trumpCard,
  });

  final int deckCount;
  final String trumpSuit;
  final Map<String, dynamic>? trumpCard;

  @override
  Widget build(BuildContext context) {
    final suitSource = (trumpCard == null ? trumpSuit : (trumpCard!['s'] ?? ''))
        .toString();
    final suit =
        {'S': '♠', 'H': '♥', 'D': '♦', 'C': '♣'}[suitSource] ?? suitSource;
    final rankRaw = (trumpCard == null ? 6 : trumpCard!['r']).toString();
    final rank =
        {'11': 'J', '12': 'Q', '13': 'K', '14': 'A'}[rankRaw] ?? rankRaw;
    final isRed = suitSource == 'H' || suitSource == 'D';

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (trumpSuit.isNotEmpty)
            Positioned(
              left: 56,
              top: 22,
              child: Transform.rotate(
                angle: -1.18,
                child: DurakCardWidget(
                  rankLabel: rank,
                  suitLabel: suit,
                  isRed: isRed,
                  faceUp: true,
                  disabled: true,
                ),
              ),
            ),
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 3.0,
              top: 12 + i * 2.0,
              child: Transform.rotate(
                angle: -0.08 + i * 0.03,
                child: const DurakCardWidget(
                  rankLabel: '',
                  suitLabel: '',
                  isRed: false,
                  faceUp: false,
                  disabled: true,
                ),
              ),
            ),
          Positioned(
            left: 2,
            top: 6,
            child: Text(
              deckCount.toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrumpSuitBadge extends StatelessWidget {
  const _TrumpSuitBadge({required this.trumpSuit});

  final String trumpSuit;

  @override
  Widget build(BuildContext context) {
    final suit =
        {'S': '♠', 'H': '♥', 'D': '♦', 'C': '♣'}[trumpSuit] ?? trumpSuit;
    final isRed = trumpSuit == 'H' || trumpSuit == 'D';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        suit,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: isRed
              ? const Color(0xFFF87171)
              : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _DurakDiscardPile extends StatelessWidget {
  const _DurakDiscardPile({required this.discardCount});

  final int discardCount;

  @override
  Widget build(BuildContext context) {
    final stacks = discardCount <= 0
        ? 0
        : (discardCount > 5 ? 5 : discardCount);
    if (stacks == 0) {
      return const SizedBox(width: 90, height: 110);
    }
    return SizedBox(
      width: 90,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < stacks; i++)
            Positioned(
              right: i * 4.0,
              top: i * 2.0,
              child: Transform.rotate(
                angle: -0.18 + i * 0.05,
                child: const DurakCardWidget(
                  rankLabel: '',
                  suitLabel: '',
                  isRed: false,
                  faceUp: false,
                  disabled: true,
                  width: 68,
                  height: 96,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
                        AppLocalizations.of(context)!.durak_cheater_label,
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
                  ? AppLocalizations.of(context)!.durak_waiting_foll_confirm
                  : AppLocalizations.of(context)!.durak_waiting_foll_call,
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

class _DurakFinishedCard extends StatelessWidget {
  const _DurakFinishedCard({
    required this.winnerName,
    required this.winnerAvatarUrl,
    required this.loserLabel,
    required this.rematchBusy,
    required this.onRematch,
    required this.onBackToChat,
    this.isTournamentGame = false,
    this.tournamentId,
    this.onNextTournamentGame,
  });

  final String winnerName;
  final String? winnerAvatarUrl;
  final String loserLabel;
  final bool rematchBusy;
  final VoidCallback onRematch;
  final VoidCallback onBackToChat;
  final bool isTournamentGame;
  final String? tournamentId;
  final VoidCallback? onNextTournamentGame;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB8EC5C),
                ),
                child: ClipOval(
                  child: winnerAvatarUrl != null && winnerAvatarUrl!.isNotEmpty
                      ? Image.network(
                          winnerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _winnerFallbackAvatar(),
                        )
                      : _winnerFallbackAvatar(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8EC5C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
AppLocalizations.of(context)!.conversation_durak_winner,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF173217),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                winnerName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  height: 1.06,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loserLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
              const SizedBox(height: 18),
              if (isTournamentGame && tournamentId != null)
                _TournamentNextGameSection(
                  tournamentId: tournamentId!,
                  busy: rematchBusy,
                  onNextGame: onNextTournamentGame,
                )
              else
              SizedBox(
                width: 240,
                height: 52,
                child: FilledButton(
                  onPressed: rematchBusy ? null : onRematch,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF66798C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: rematchBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
AppLocalizations.of(context)!.conversation_durak_play_again,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 240,
                height: 44,
                child: TextButton(
                  onPressed: onBackToChat,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.conversation_durak_back_to_chat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winnerFallbackAvatar() {
    return Container(
      color: const Color(0xFF293F4F),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
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

class _TournamentNextGameSection extends StatelessWidget {
  const _TournamentNextGameSection({
    required this.tournamentId,
    required this.busy,
    required this.onNextGame,
  });

  final String tournamentId;
  final bool busy;
  final VoidCallback? onNextGame;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final data = snap.data?.data();
        final status = (data?['status'] ?? 'active').toString();
        final totalGames = (data?['totalGames'] is num)
            ? (data!['totalGames'] as num).toInt()
            : 0;
        final finishedCount =
            (data?['finishedGameIds'] is List)
                ? (data!['finishedGameIds'] as List).length
                : 0;
        final createdCount = (data?['gameIds'] is List)
            ? (data!['gameIds'] as List).length
            : 0;
        final limitReached = status == 'finished' ||
            (totalGames > 0 && createdCount >= totalGames);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalGames > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppLocalizations.of(context)!.durak_games_progress(finishedCount.toString(), totalGames.toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            if (limitReached)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context)!.durak_tournament_finished,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              )
            else
              SizedBox(
                width: 260,
                height: 52,
                child: FilledButton(
                  onPressed: (busy || onNextGame == null) ? null : onNextGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF66798C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
                          AppLocalizations.of(context)!.durak_next_round,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}
