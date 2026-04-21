import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'chat_avatar.dart';

class ReactionUserView {
  const ReactionUserView({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.timestamp,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? timestamp;
}

class MessageReactionsRow extends StatelessWidget {
  const MessageReactionsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.alignRight,
    required this.isGroup,
    required this.resolveUser,
    required this.onToggleReaction,
    this.enabled = true,
  });

  final Map<String, List<ReactionEntry>> reactions;
  final String currentUserId;
  final bool alignRight;
  final bool isGroup;
  final ReactionUserView Function(String userId, {String? timestamp})
  resolveUser;
  final Future<void> Function(String emoji) onToggleReaction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final chips = reactions.entries
        .where((e) => e.key.isNotEmpty && e.value.isNotEmpty)
        .map(
          (e) => _ReactionChip(
            emoji: e.key,
            currentUserId: currentUserId,
            isGroup: isGroup,
            enabled: enabled,
            users: _dedupUsers(e.value),
            resolveUser: resolveUser,
            onToggleReaction: onToggleReaction,
          ),
        )
        .toList(growable: false);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Wrap(spacing: 8, runSpacing: 6, children: chips),
      ),
    );
  }

  List<ReactionEntry> _dedupUsers(List<ReactionEntry> raw) {
    final seen = <String>{};
    final out = <ReactionEntry>[];
    for (final r in raw) {
      final uid = r.userId.trim();
      if (uid.isEmpty) continue;
      if (seen.add(uid)) out.add(r);
    }
    return out;
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.users,
    required this.currentUserId,
    required this.isGroup,
    required this.enabled,
    required this.resolveUser,
    required this.onToggleReaction,
  });

  final String emoji;
  final List<ReactionEntry> users;
  final String currentUserId;
  final bool isGroup;
  final bool enabled;
  final ReactionUserView Function(String userId, {String? timestamp})
  resolveUser;
  final Future<void> Function(String emoji) onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final hasMine = users.any((u) => u.userId == currentUserId);

    final bg = hasMine
        ? scheme.primary.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: dark ? 0.12 : 0.06);
    final fg = hasMine
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.72);
    final userViews = users
        .map((u) => resolveUser(u.userId, timestamp: u.timestamp))
        .toList(growable: false);
    final showCounterOnly = isGroup && userViews.length > 3;

    return GestureDetector(
      onTap: !enabled ? null : () => onToggleReaction(emoji),
      onLongPress: () =>
          _showReactionUsersPopover(context, emoji: emoji, users: userViews),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18, height: 1.0)),
            const SizedBox(width: 6),
            if (showCounterOnly)
              Text(
                userViews.length.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final u in userViews.take(3))
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChatAvatar(
                        title: u.name,
                        radius: 8,
                        avatarUrl: u.avatarUrl,
                      ),
                    ),
                  Text(
                    userViews.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReactionUsersPopover(
    BuildContext context, {
    required String emoji,
    required List<ReactionUserView> users,
  }) async {
    if (users.isEmpty) return;

    final box = context.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox) return;

    final target = MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );

    const popoverW = 280.0;
    const sideGap = 8.0;
    const verticalGap = 8.0;
    const rowH = 56.0;
    const headerH = 52.0;
    final estH = (headerH + users.length * rowH).clamp(120.0, 320.0);
    final screenSize = overlay.size;
    final left = target.left.clamp(
      sideGap,
      screenSize.width - popoverW - sideGap,
    );

    final belowTop = target.bottom + verticalGap;
    final fitsBelow = belowTop + estH <= screenSize.height - 12;
    final top = fitsBelow
        ? belowTop
        : (target.top - estH - verticalGap).clamp(
            12.0,
            screenSize.height - estH - 12,
          );

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'reaction_users_popover',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, _) {
        final scheme = Theme.of(ctx).colorScheme;
        final fg = Colors.white.withValues(alpha: 0.96);
        final muted = Colors.white.withValues(alpha: 0.72);
        final isDark = scheme.brightness == Brightness.dark;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Navigator.of(ctx).maybePop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: left.toDouble(),
                  top: top.toDouble(),
                  child: GestureDetector(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: popoverW,
                          constraints: const BoxConstraints(maxHeight: 320),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.14 : 0.18,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.32),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Оценили: ${users.length}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.35,
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: users.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  itemBuilder: (ctx, i) {
                                    final u = users[i];
                                    return Theme(
                                      data: Theme.of(ctx).copyWith(
                                        textTheme: Theme.of(ctx).textTheme
                                            .apply(
                                              bodyColor: fg,
                                              displayColor: fg,
                                            ),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        leading: ChatAvatar(
                                          title: u.name,
                                          radius: 16,
                                          avatarUrl: u.avatarUrl,
                                        ),
                                        title: Text(
                                          u.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: fg,
                                          ),
                                        ),
                                        subtitle:
                                            (u.timestamp ?? '').trim().isEmpty
                                            ? null
                                            : Text(
                                                _formatReactionTime(
                                                  u.timestamp!,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, a, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
  }

  String _formatReactionTime(String timestamp) {
    final d = DateTime.tryParse(timestamp)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Сегодня, $hh:$mm';
    }
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }
}
