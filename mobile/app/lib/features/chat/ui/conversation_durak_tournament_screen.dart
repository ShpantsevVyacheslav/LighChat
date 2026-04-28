import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/games_callables.dart';
import 'conversation_durak_create_lobby_sheet.dart';
import 'conversation_durak_lobby_screen.dart';
import 'durak_player_profiles.dart';

class ConversationDurakTournamentScreen extends StatelessWidget {
  const ConversationDurakTournamentScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _newGame(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tSnap =
          await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
      final t = tSnap.data() ?? const <String, dynamic>{};
      final conversationId = (t['conversationId'] ?? '').toString();
      final isGroup = conversationId.isEmpty
          ? true
          : (await FirebaseFirestore.instance.collection('conversations').doc(conversationId).get())
                  .data()?['isGroup'] ==
              true;
      if (!context.mounted) return;

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
          isGroup: isGroup,
        ),
      );
      if (settingsRes == null) return;

      final res = await GamesCallables().createTournamentDurakLobby(
        tournamentId: tournamentId,
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
      _toast(context, l10n.tournament_create_game_failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tRef = FirebaseFirestore.instance.collection('tournaments').doc(tournamentId);
    final gamesQuery = tRef.collection('games').orderBy('createdAt', descending: true).limit(20);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tournament_title),
        actions: [
          IconButton(
            tooltip: l10n.tournament_new_game,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => unawaited(_newGame(context)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_newGame(context)),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.tournament_new_game),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: tRef.snapshots(),
        builder: (context, snap) {
          final t = snap.data?.data() ?? const <String, dynamic>{};
          final pointsByUid = (t['pointsByUid'] is Map) ? Map<String, dynamic>.from(t['pointsByUid'] as Map) : {};
          final playedByUid =
              (t['gamesPlayedByUid'] is Map) ? Map<String, dynamic>.from(t['gamesPlayedByUid'] as Map) : {};

          final standingsUids = <String>{
            ...pointsByUid.keys.map((e) => e.toString()),
            ...playedByUid.keys.map((e) => e.toString()),
          }.toList();

          standingsUids.sort((a, b) {
            final pa = (pointsByUid[a] is num) ? (pointsByUid[a] as num).toDouble() : 0.0;
            final pb = (pointsByUid[b] is num) ? (pointsByUid[b] as num).toDouble() : 0.0;
            if (pa != pb) return pb.compareTo(pa);
            final ga = (playedByUid[a] is num) ? (playedByUid[a] as num).toInt() : 0;
            final gb = (playedByUid[b] is num) ? (playedByUid[b] as num).toInt() : 0;
            return gb.compareTo(ga);
          });

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: gamesQuery.snapshots(),
            builder: (context, gamesSnap) {
              final gameDocs = gamesSnap.data?.docs ?? const [];
              final gameUids = <String>{};
              for (final d in gameDocs) {
                final m = d.data();
                final ids = (m['playerIds'] is List) ? List<Object?>.from(m['playerIds'] as List) : const <Object?>[];
                for (final x in ids) {
                  final s = (x ?? '').toString().trim();
                  if (s.isNotEmpty) gameUids.add(s);
                }
              }

              final allUids = <String>{...standingsUids, ...gameUids}.toList();

              return DurakPlayerProfiles(
                uids: allUids,
                builder: (context, byUid) {
                  String nameOf(String uid) => (byUid[uid]?.name ?? uid).toString();

                  String gameResultText(Map<String, dynamic> m) {
                    final status = (m['status'] ?? '').toString();
                    if (status != 'finished') return '';
                    final loserUid = (m['loserUid'] ?? '').toString().trim();
                    if (loserUid.isEmpty) return l10n.tournament_game_result_draw;
                    return l10n.tournament_game_result_loser(nameOf(loserUid));
                  }

                  String gamePlayersText(Map<String, dynamic> m) {
                    final ids = (m['playerIds'] is List) ? List<Object?>.from(m['playerIds'] as List) : const <Object?>[];
                    final names = ids.map((x) => nameOf((x ?? '').toString().trim())).where((s) => s.trim().isNotEmpty).toList();
                    if (names.isEmpty) return '';
                    return l10n.tournament_game_players(names.join(', '));
                  }

                  String gamePlacementsText(Map<String, dynamic> m) {
                    final status = (m['status'] ?? '').toString();
                    if (status != 'finished') return '';
                    final raw = m['placements'];
                    if (raw is! List) return '';
                    final groups = raw
                        .whereType<Map>()
                        .map((g) => (g['uids'] is List) ? List<Object?>.from(g['uids'] as List) : const <Object?>[])
                        .map((uids) => uids.map((x) => nameOf((x ?? '').toString().trim())).where((s) => s.trim().isNotEmpty).toList())
                        .where((uids) => uids.isNotEmpty)
                        .toList();
                    if (groups.isEmpty) return '';
                    final lines = <String>[];
                    var place = 1;
                    for (final g in groups) {
                      final label = g.length == 1 ? '$place' : '$place-${place + g.length - 1}';
                      lines.add('${l10n.tournament_game_place(label)}: ${g.join(', ')}');
                      place += g.length;
                    }
                    return lines.join('\n');
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    children: [
                      Text(l10n.tournament_standings, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (standingsUids.isEmpty)
                        Text(l10n.tournament_standings_empty)
                      else
                        for (final uid in standingsUids)
                          ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: ((byUid[uid]?.avatarThumb ?? byUid[uid]?.avatar) ?? '').trim().isEmpty
                                  ? null
                                  : NetworkImage((byUid[uid]!.avatarThumb ?? byUid[uid]!.avatar)!),
                              child: (((byUid[uid]?.avatarThumb ?? byUid[uid]?.avatar) ?? '').trim().isEmpty)
                                  ? const Icon(Icons.person_rounded, size: 18)
                                  : null,
                            ),
                            title: Text(nameOf(uid)),
                            subtitle: Text(l10n.tournament_games_played((playedByUid[uid] ?? 0).toString())),
                            trailing: Text(
                              l10n.tournament_points((pointsByUid[uid] ?? 0).toString()),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                      const SizedBox(height: 16),
                      Text(l10n.tournament_games, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (gameDocs.isEmpty)
                        Text(l10n.tournament_games_empty)
                      else
                        for (final d in gameDocs)
                          ListTile(
                            leading: const Icon(Icons.style_rounded),
                            title: Text(l10n.conversation_games_durak),
                            subtitle: Text([
                              l10n.conversation_game_lobby_status((d.data()['status'] ?? '').toString()),
                              gamePlayersText(d.data()),
                              gameResultText(d.data()),
                              gamePlacementsText(d.data()),
                            ].where((s) => s.trim().isNotEmpty).join('\n')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => unawaited(
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConversationDurakLobbyScreen(gameId: d.id),
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 80),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

