import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'conversation_durak_lobby_screen.dart';

class DmGameLobbyBanner extends StatefulWidget {
  const DmGameLobbyBanner({
    super.key,
    required this.conversationId,
    required this.isGroup,
  });

  final String conversationId;
  final bool isGroup;

  @override
  State<DmGameLobbyBanner> createState() => _DmGameLobbyBannerState();
}

class _DmGameLobbyBannerState extends State<DmGameLobbyBanner> {
  bool _dismissed = false;
  final Set<String> _cleanupInFlight = <String>{};

  Future<void> _cleanupDeadLobbyDoc(String gameId) async {
    final gid = gameId.trim();
    if (gid.isEmpty || _cleanupInFlight.contains(gid)) return;
    _cleanupInFlight.add(gid);
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('gameLobbies')
          .doc(gid)
          .delete();
    } on FirebaseException catch (_) {
      // Best-effort cleanup only.
    } finally {
      _cleanupInFlight.remove(gid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return const SizedBox.shrink();

    final q = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('gameLobbies')
        .orderBy('createdAt', descending: true)
        .limit(10);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        QueryDocumentSnapshot<Map<String, dynamic>>? lobby;
        for (final d in docs) {
          final m = d.data();
          if ((m['type'] ?? '').toString() != 'durak') continue;
          if (!{'lobby', 'active'}.contains((m['status'] ?? '').toString())) {
            continue;
          }
          lobby = d;
          break;
        }
        if (lobby == null) return const SizedBox.shrink();
        final lobbyGameId = lobby.id;
        final lobbyData = lobby.data();
        final lobbyPlayerCount = (lobbyData['playerCount'] ?? 0) is int
            ? lobbyData['playerCount'] as int
            : int.tryParse((lobbyData['playerCount'] ?? '0').toString()) ?? 0;
        final lobbyMaxPlayers = (lobbyData['maxPlayers'] ?? 0) is int
            ? lobbyData['maxPlayers'] as int
            : int.tryParse((lobbyData['maxPlayers'] ?? '0').toString()) ?? 0;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('games')
              .doc(lobbyGameId)
              .snapshots(),
          builder: (context, gSnap) {
            if (gSnap.hasError) {
              final code = (gSnap.error is FirebaseException)
                  ? ((gSnap.error as FirebaseException).code.toLowerCase())
                  : '';
              if (code == 'not-found') {
                unawaited(_cleanupDeadLobbyDoc(lobbyGameId));
                return const SizedBox.shrink();
              }
              return const SizedBox.shrink();
            }
            final gameDoc = gSnap.data;
            if (gameDoc != null && !gameDoc.exists) {
              unawaited(_cleanupDeadLobbyDoc(lobbyGameId));
              return const SizedBox.shrink();
            }
            final g = gSnap.data?.data() ?? const <String, dynamic>{};
            final playerIds = g['playerIds'];
            final ids = playerIds is List
                ? playerIds.map((e) => e.toString()).toList()
                : const <String>[];
            final iAmPlayer = ids.contains(me);
            final l10n = AppLocalizations.of(context)!;
            final lobbyStatus = (lobbyData['status'] ?? '').toString();
            final title = lobbyStatus == 'active'
                ? l10n.dm_game_banner_active
                : l10n.dm_game_banner_created;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFC107).withValues(alpha: 0.10),
                    border: Border.all(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.style_rounded, color: Color(0xFFFFC107)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$title\n${l10n.conversation_game_lobby_players(lobbyPlayerCount, lobbyMaxPlayers)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => unawaited(
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ConversationDurakLobbyScreen(
                                gameId: lobbyGameId,
                              ),
                            ),
                          ),
                        ),
                        child: Text(
                          iAmPlayer
                              ? l10n.durak_dm_lobby_open
                              : l10n.conversation_game_lobby_join,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.common_close,
                        onPressed: () => setState(() => _dismissed = true),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
