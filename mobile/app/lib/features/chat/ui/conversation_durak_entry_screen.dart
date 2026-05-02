import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'conversation_durak_create_lobby_sheet.dart';
import 'conversation_durak_lobby_screen.dart';
import 'conversation_durak_tournament_screen.dart';

class ConversationDurakEntryScreen extends StatelessWidget {
  const ConversationDurakEntryScreen({
    super.key,
    required this.conversationId,
    required this.isGroup,
  });

  final String conversationId;
  final bool isGroup;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finishGame(BuildContext context, String gameId) async {
    try {
      await GamesCallables().makeDurakMove(
        gameId: gameId,
        clientMoveId: DateTime.now().microsecondsSinceEpoch.toString(),
        actionType: 'surrender',
      );
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, friendlyGamesCallableError(e, AppLocalizations.of(context)!));
    }
  }

  Future<void> _openSingleGame(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final settingsRes = await showModalBottomSheet<DurakLobbySettingsResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => ConversationDurakCreateLobbySheet(
          initial: <String, dynamic>{
            'maxPlayers': isGroup ? 6 : 2,
            'deckSize': 36,
            'mode': 'podkidnoy',
            'withJokers': false,
            'turnTimeSec': 15,
            'throwInPolicy': 'all',
            'shulerEnabled': false,
          },
          isGroup: isGroup,
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
    final totalGames = await showDialog<int>(
      context: context,
      builder: (ctx) => const _TournamentTotalGamesDialog(),
    );
    if (totalGames == null) return;
    if (!context.mounted) return;
    try {
      final res = await GamesCallables().createDurakTournament(
        conversationId: conversationId,
        totalGames: totalGames,
      );
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              ConversationDurakTournamentScreen(tournamentId: res.tournamentId),
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
      appBar: AppBar(title: Text(l10n.conversation_games_durak)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: lobbiesQuery.snapshots(),
        builder: (context, lobbySnap) {
          final lobbies = (lobbySnap.data?.docs ?? const [])
              .where((d) {
                final data = d.data();
                final status = (data['status'] ?? '').toString();
                final type = (data['type'] ?? 'durak').toString();
                return type == 'durak' &&
                    (status == 'lobby' || status == 'active');
              })
              .toList(growable: false);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: tournamentsQuery.snapshots(),
            builder: (context, tournamentSnap) {
              final tournaments = (tournamentSnap.data?.docs ?? const [])
                  .where(
                    (d) => (d.data()['type'] ?? 'durak').toString() == 'durak',
                  )
                  .toList(growable: false);

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: [
                  _DurakActionTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: l10n.durak_entry_single_game,
                    subtitle: l10n.conversation_games_durak_subtitle,
                    onTap: () => unawaited(_openSingleGame(context)),
                  ),
                  const SizedBox(height: 8),
                  _DurakActionTile(
                    icon: Icons.emoji_events_rounded,
                    title: l10n.tournament_title,
                    subtitle: l10n.tournament_subtitle,
                    onTap: () => unawaited(_createTournament(context)),
                  ),
                  if (lobbies.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _SectionLabel(text: l10n.conversation_game_lobby_title),
                    const SizedBox(height: 6),
                    for (final d in lobbies)
                      ListTile(
                        leading: const Icon(Icons.meeting_room_rounded),
                        title: Text(l10n.conversation_games_durak),
                        subtitle: Text(
                          l10n.conversation_game_lobby_status(
                            (d.data()['status'] ?? '').toString(),
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: l10n.durak_entry_finish_game_tooltip,
                              onPressed: () =>
                                  unawaited(_finishGame(context, d.id)),
                              icon: const Icon(Icons.flag_rounded),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
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
                  if (tournaments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _SectionLabel(text: l10n.tournament_title),
                    const SizedBox(height: 6),
                    for (final d in tournaments)
                      ListTile(
                        leading: const Icon(Icons.emoji_events_rounded),
                        title: Text(
                          (d.data()['title'] ?? l10n.tournament_title)
                              .toString(),
                        ),
                        subtitle: Text(
                          l10n.conversation_game_lobby_status(
                            (d.data()['status'] ?? '').toString(),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => unawaited(
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ConversationDurakTournamentScreen(
                                tournamentId: d.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DurakActionTile extends StatelessWidget {
  const _DurakActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _TournamentTotalGamesDialog extends StatefulWidget {
  const _TournamentTotalGamesDialog();

  @override
  State<_TournamentTotalGamesDialog> createState() =>
      _TournamentTotalGamesDialogState();
}

class _TournamentTotalGamesDialogState
    extends State<_TournamentTotalGamesDialog> {
  int _value = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.durak_entry_tournament_games_dialog_title),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _value > 1 ? () => setState(() => _value -= 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$_value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: _value < 50 ? () => setState(() => _value += 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.durak_entry_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: Text(l10n.durak_entry_create),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
