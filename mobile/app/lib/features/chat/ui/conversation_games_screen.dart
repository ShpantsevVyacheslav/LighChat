import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'conversation_durak_entry_screen.dart';
import 'profile_subpage_header.dart';

class ConversationGamesScreen extends StatelessWidget {
  const ConversationGamesScreen({
    super.key,
    required this.conversationId,
    required this.isGroup,
  });

  final String conversationId;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ChatProfileSubpageHeader(title: l10n.conversation_games_title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.style_rounded),
                    title: Text(l10n.conversation_games_durak),
                    subtitle: Text(l10n.conversation_games_durak_subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationDurakEntryScreen(
                            conversationId: conversationId,
                            isGroup: isGroup,
                          ),
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
  }
}
