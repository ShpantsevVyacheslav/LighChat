import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'conversation_durak_game_screen.dart';
import 'durak_card_widget.dart';
import 'durak_felt_background.dart';
import 'durak_player_profiles.dart';

class ConversationDurakLobbyScreen extends StatelessWidget {
  const ConversationDurakLobbyScreen({super.key, required this.gameId});

  final String gameId;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isOwner(Map<String, dynamic> data, String uid) {
    final createdBy = (data['createdBy'] ?? '').toString();
    return createdBy == uid;
  }

  bool _isBenignStartTransitionError(Object error) {
    final upper = error.toString().toUpperCase();
    return upper.contains('NOT_IN_LOBBY') ||
        upper.contains('GAME_NOT_ACTIVE') ||
        upper.contains('GAME_ALREADY_ACTIVE');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ref = FirebaseFirestore.instance.collection('games').doc(gameId);
    final me = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          final code = (snap.error is FirebaseException)
              ? ((snap.error as FirebaseException).code.toLowerCase())
              : '';
          final removed = code == 'permission-denied' || code == 'not-found';
          return _LobbyShell(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      removed
                          ? l10n.conversation_game_lobby_unavailable
                          : l10n.conversation_game_lobby_error(
                              (snap.error ?? 'unknown').toString(),
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.common_close),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const _LobbyShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final doc = snap.data!;
        if (!doc.exists) {
          return _LobbyShell(
            child: Center(
              child: Text(
                l10n.conversation_game_lobby_not_found,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final data = doc.data() ?? const <String, dynamic>{};
        final status = (data['status'] ?? '').toString();
        final playerIdsRaw = data['playerIds'];
        final playerIds = playerIdsRaw is List
            ? playerIdsRaw.map((e) => e.toString()).toList()
            : const <String>[];
        final iAmPlayer = me != null && playerIds.contains(me);
        final maxPlayers = (data['settings'] is Map)
            ? (((data['settings'] as Map)['maxPlayers']) is int
                ? ((data['settings'] as Map)['maxPlayers'] as int)
                : int.tryParse(
                      ((data['settings'] as Map)['maxPlayers'] ?? '').toString(),
                    ) ??
                    2)
            : 2;
        final readyRaw = data['readyUids'];
        final readyUids = readyRaw is List
            ? readyRaw.map((e) => e.toString()).toSet()
            : <String>{};
        final iAmReady = me != null && readyUids.contains(me);
        final allReady =
            playerIds.isNotEmpty && readyUids.length >= playerIds.length;
        final canReady = me != null && iAmPlayer && status == 'lobby';
        final canStart =
            me != null &&
                iAmPlayer &&
                status == 'lobby' &&
                playerIds.length >= 2 &&
                allReady;
        final canCancel = me != null && status == 'lobby' && _isOwner(data, me);
        final canJoin =
            me != null && !iAmPlayer && status == 'lobby' && playerIds.length < maxPlayers;

        if (status == 'active' || status == 'finished') {
          return ConversationDurakGameScreen(gameId: gameId);
        }

        return _LobbyShell(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: l10n.conversation_game_lobby_back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      Text(
                        l10n.conversation_game_lobby_title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      if (canCancel)
                        IconButton.filledTonal(
                          tooltip: l10n.conversation_game_lobby_cancel,
                          onPressed: () async {
                            try {
                              await GamesCallables().cancelLobby(
                                gameId: gameId,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (!context.mounted) return;
                              _toast(
                                context,
                                l10n.conversation_game_lobby_cancel_failed(e),
                              );
                            }
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _PlayerSlotsRow(
                  playerIds: playerIds,
                  readyUids: readyUids,
                  maxPlayers: maxPlayers,
                  meUid: me,
                ),
                const SizedBox(height: 36),
                const _DeckPreview(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iAmPlayer && playerIds.length < 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
l10n.conversation_game_lobby_waiting_opponent,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: canStart
                                ? const Color(0xFFA3E635)
                                : (iAmReady
                                      ? const Color(0xFF4B6477)
                                      : const Color(0xFF8FB2C8)),
                            foregroundColor: canStart
                                ? const Color(0xFF173217)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: me == null
                              ? null
                              : (canJoin
                                    ? () async {
                                        try {
                                          await GamesCallables().joinLobby(
                                            gameId: gameId,
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          _toast(
                                            context,
                                            l10n.conversation_game_lobby_join_failed(
                                              e,
                                            ),
                                          );
                                        }
                                      }
                                    : ((canReady && !iAmReady) || canStart
                                          ? () async {
                                              try {
                                                await GamesCallables()
                                                    .startDurak(gameId: gameId);
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                if (_isBenignStartTransitionError(
                                                  e,
                                                )) {
                                                  return;
                                                }
                                                _toast(
                                                  context,
                                                  l10n.conversation_game_lobby_start_failed(
                                                    e,
                                                  ),
                                                );
                                              }
                                            }
                                          : null)),
                          child: Text(
                            canJoin
                                ? l10n.conversation_game_lobby_join
                                : (canStart
                                      ? l10n.conversation_game_lobby_start_game
: (iAmReady ? l10n.conversation_game_lobby_waiting : l10n.conversation_game_lobby_ready)),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
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
        );
      },
    );
  }

}

class _LobbyShell extends StatelessWidget {
  const _LobbyShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A3A),
      body: DurakFeltBackground(child: child),
    );
  }
}

class _PlayerSlotsRow extends StatelessWidget {
  const _PlayerSlotsRow({
    required this.playerIds,
    required this.readyUids,
    required this.maxPlayers,
    required this.meUid,
  });

  final List<String> playerIds;
  final Set<String> readyUids;
  final int maxPlayers;
  final String? meUid;

  @override
  Widget build(BuildContext context) {
    final slots = maxPlayers > 0 ? maxPlayers : 2;
    return DurakPlayerProfiles(
      uids: playerIds,
      builder: (context, byUid) {
        final children = <Widget>[];
        for (var i = 0; i < slots; i++) {
          if (i < playerIds.length) {
            final uid = playerIds[i];
            final p = byUid[uid];
            final avatarUrl = ((p?.avatarThumb ?? p?.avatar) ?? '').trim();
            final name = p?.name ?? '—';
            final isMe = uid == meUid;
            final isReady = readyUids.contains(uid);
            children.add(
              _PlayerSlot(
                avatarUrl: avatarUrl,
                name: name,
                isMe: isMe,
                isReady: isReady,
              ),
            );
          } else {
            children.add(const _EmptySlot());
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 18,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.avatarUrl,
    required this.name,
    required this.isMe,
    required this.isReady,
  });

  final String avatarUrl;
  final String name;
  final bool isMe;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isReady
                        ? const Color(0xFFA3E635)
                        : Colors.white.withValues(alpha: 0.45),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _AvatarFallback(),
                        )
                      : _AvatarFallback(),
                ),
              ),
              if (isReady)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFA3E635),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF173217),
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: isMe
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Colors.white70, size: 32),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 28,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
AppLocalizations.of(context)!.conversation_game_lobby_waiting,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckPreview extends StatelessWidget {
  const _DeckPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Positioned(
              left: 14 + i * 3.0,
              top: 6 + i * 2.0,
              child: Transform.rotate(
                angle: -0.05 + i * 0.025,
                child: const DurakCardWidget(
                  rankLabel: '',
                  suitLabel: '',
                  isRed: false,
                  faceUp: false,
                  disabled: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
