import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/group_mention_candidates.dart';
import 'chat_avatar.dart';

class GroupMentionSuggestions extends StatelessWidget {
  const GroupMentionSuggestions({
    super.key,
    required this.items,
    required this.onPick,
  });

  final List<GroupMentionCandidate> items;
  final ValueChanged<GroupMentionCandidate> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    const maxHeight = 280.0;
    const rowHeight = 56.0;
    const emptyRowHeight = 42.0;
    const listPadding = 12.0;
    final rowCount = items.isEmpty ? 1 : items.length;
    final desiredHeight =
        (items.isEmpty ? emptyRowHeight : rowCount * rowHeight) + listPadding;
    final panelHeight = desiredHeight.clamp(54.0, maxHeight).toDouble();
    final scrollable = rowCount > 4;
    return Container(
      height: panelHeight,
      constraints: const BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (dark ? const Color(0xFF0C1018) : scheme.surfaceContainerLow)
            .withValues(alpha: dark ? 0.88 : 0.96),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.14 : 0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListView.builder(
          physics: scrollable
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(6),
          itemCount: items.isEmpty ? 1 : items.length,
          itemBuilder: (context, i) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  AppLocalizations.of(context)!.chat_mention_no_matches,
                  style: TextStyle(
                    color: fg.withValues(alpha: dark ? 0.62 : 0.56),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }
            final p = items[i];
            final username = p.username.trim();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPick(p),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    children: [
                      ChatAvatar(
                        title: p.name,
                        radius: 16,
                        avatarUrl: p.avatarUrl,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: fg.withValues(alpha: dark ? 0.92 : 0.88),
                              ),
                            ),
                            if (username.isNotEmpty)
                              Text(
                                '@$username',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: fg.withValues(
                                    alpha: dark ? 0.62 : 0.56,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
