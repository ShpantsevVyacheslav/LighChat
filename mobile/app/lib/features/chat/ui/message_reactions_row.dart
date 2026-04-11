import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

class MessageReactionsRow extends StatelessWidget {
  const MessageReactionsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.alignRight,
  });

  final Map<String, List<ReactionEntry>> reactions;
  final String currentUserId;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final chips = reactions.entries
        .where((e) => e.key.isNotEmpty && e.value.isNotEmpty)
        .map((e) => _ReactionChip(
              emoji: e.key,
              userIds: e.value.map((x) => x.userId).where((s) => s.isNotEmpty).toSet().toList(growable: false),
              currentUserId: currentUserId,
            ))
        .toList(growable: false);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: chips,
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.userIds, required this.currentUserId});

  final String emoji;
  final List<String> userIds;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMine = userIds.contains(currentUserId);
    final dark = scheme.brightness == Brightness.dark;

    final bg = isMine ? scheme.primary.withValues(alpha: 0.14) : Colors.black.withValues(alpha: dark ? 0.12 : 0.06);
    final fg = isMine ? scheme.primary : scheme.onSurface.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18, height: 1.0)),
          const SizedBox(width: 6),
          Text(
            userIds.length.toString(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
          ),
        ],
      ),
    );
  }
}

