import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'conversation_durak_game_screen.dart';

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    removed
                        ? 'Игра недоступна или была удалена'
                        : l10n.conversation_game_lobby_error(
                            (snap.error ?? 'unknown').toString(),
                          ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.common_close),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snap.data!;
        if (!doc.exists) {
          return Center(child: Text(l10n.conversation_game_lobby_not_found));
        }

        final data = doc.data() ?? const <String, dynamic>{};
        final status = (data['status'] ?? '').toString();
        final playerIds = data['playerIds'];
        final ids = playerIds is List
            ? playerIds.map((e) => e.toString()).toList()
            : const <String>[];
        final iAmPlayer = me != null && ids.contains(me);
        final players = data['players'];
        final playerCount = players is List ? players.length : 0;
        final maxPlayers = (data['settings'] is Map)
            ? ((data['settings'] as Map)['maxPlayers'] ?? 0)
            : 0;
        final canStart =
            me != null &&
            iAmPlayer &&
            status == 'lobby' &&
            playerCount >= 2 &&
            _isOwner(data, me);
        final canCancel = me != null && status == 'lobby' && _isOwner(data, me);

        if (status == 'active') {
          return ConversationDurakGameScreen(gameId: gameId);
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.conversation_games_durak)),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            children: [
              Text(
                l10n.conversation_game_lobby_title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(l10n.conversation_game_lobby_game_id(gameId)),
              const SizedBox(height: 8),
              Text(l10n.conversation_game_lobby_status(status)),
              const SizedBox(height: 8),
              Text(
                l10n.conversation_game_lobby_players(
                  playerCount,
                  maxPlayers is int ? maxPlayers : 0,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: me == null
                    ? null
                    : (!iAmPlayer && status == 'lobby'
                          ? () async {
                              try {
                                await GamesCallables().joinLobby(
                                  gameId: gameId,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                _toast(
                                  context,
                                  l10n.conversation_game_lobby_join_failed(e),
                                );
                              }
                            }
                          : (canStart
                                ? () async {
                                    try {
                                      await GamesCallables().startDurak(
                                        gameId: gameId,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
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
                  !iAmPlayer && status == 'lobby'
                      ? l10n.conversation_game_lobby_join
                      : (canStart
                            ? l10n.conversation_game_lobby_start
                            : l10n.common_soon),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await GamesCallables().cancelLobby(gameId: gameId);
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
                  child: Text(l10n.conversation_game_lobby_cancel),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
