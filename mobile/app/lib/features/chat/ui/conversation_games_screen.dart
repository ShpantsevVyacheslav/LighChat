import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'conversation_durak_create_lobby_sheet.dart';
import 'conversation_durak_lobby_screen.dart';
import 'conversation_durak_tournament_screen.dart';

class ConversationGamesScreen extends StatelessWidget {
  const ConversationGamesScreen({
    super.key,
    required this.conversationId,
    required this.isGroup,
  });

  final String conversationId;
  final bool isGroup;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openDurak(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final settingsRes = await showModalBottomSheet<DurakLobbySettingsResult>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ConversationDurakCreateLobbySheet(
          initial: const <String, dynamic>{
            'maxPlayers': 6,
            'deckSize': 36,
            'mode': 'podkidnoy',
            'withJokers': false,
            'turnTimeSec': null,
            'throwInPolicy': 'all',
            'shulerEnabled': false,
          },
        ),
      );
      if (settingsRes == null) return;

      final res = await GamesCallables().createDurakLobby(
        conversationId: conversationId,
        settings: settingsRes.settings,
      );
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDurakLobbyScreen(gameId: res.gameId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, l10n.conversation_game_lobby_create_failed(e));
    }
  }

  Future<void> _createTournament(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final res = await GamesCallables().createDurakTournament(conversationId: conversationId);
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDurakTournamentScreen(tournamentId: res.tournamentId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, l10n.tournament_create_failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lobbiesQuery = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('gameLobbies')
        .orderBy('createdAt', descending: true)
        .limit(10);
    final tournamentsQuery = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('tournaments')
        .orderBy('createdAt', descending: true)
        .limit(10);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conversation_games_title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: lobbiesQuery.snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? const [];
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            children: [
              ListTile(
                leading: const Icon(Icons.style_rounded),
                title: Text(l10n.conversation_games_durak),
                subtitle: Text(l10n.conversation_games_durak_subtitle),
                trailing: const Icon(Icons.add_rounded),
                onTap: () => unawaited(_openDurak(context)),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_rounded),
                title: Text(l10n.tournament_title),
                subtitle: Text(l10n.tournament_subtitle),
                trailing: const Icon(Icons.add_rounded),
                onTap: () => unawaited(_createTournament(context)),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: tournamentsQuery.snapshots(),
                builder: (context, tSnap) {
                  final tDocs = tSnap.data?.docs ?? const [];
                  if (tDocs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      for (final d in tDocs)
                        ListTile(
                          leading: const Icon(Icons.emoji_events_rounded),
                          title: Text((d.data()['title'] ?? l10n.tournament_title).toString()),
                          subtitle: Text(
                            l10n.conversation_game_lobby_status((d.data()['status'] ?? '').toString()),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => unawaited(
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => ConversationDurakTournamentScreen(tournamentId: d.id),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (docs.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final d in docs)
                  ListTile(
                    leading: const Icon(Icons.meeting_room_rounded),
                    title: Text(l10n.conversation_games_durak),
                    subtitle: Text(
                      l10n.conversation_game_lobby_status(
                        (d.data()['status'] ?? '').toString(),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ConversationDurakLobbyScreen(gameId: d.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
