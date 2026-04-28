import 'package:flutter/material.dart';

import 'durak_player_profiles.dart';

class DurakPlayersStrip extends StatelessWidget {
  const DurakPlayersStrip({
    super.key,
    required this.seats,
    required this.attackerUid,
    required this.defenderUid,
    required this.throwerUids,
    required this.passedUids,
    required this.activeThrowerUid,
    required this.handCounts,
    required this.me,
  });

  final List<String> seats;
  final String attackerUid;
  final String defenderUid;
  final Set<String> throwerUids;
  final Set<String> passedUids;
  final String? activeThrowerUid;
  final Map? handCounts;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final ids = seats.where((s) => s.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const SizedBox.shrink();

    return DurakPlayerProfiles(
      uids: ids,
      builder: (context, byUid) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final uid in ids)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _PlayerChip(
                    uid: uid,
                    name: byUid[uid]?.name ?? uid,
                    avatarUrl: _avatarUrl(byUid[uid]?.avatarThumb, byUid[uid]?.avatar),
                    isMe: me != null && uid == me,
                    isActive: activeThrowerUid != null && uid == activeThrowerUid,
                    isAttacker: uid == attackerUid,
                    isDefender: uid == defenderUid,
                    canThrowIn: throwerUids.contains(uid) && uid != defenderUid,
                    passed: passedUids.contains(uid),
                    cardCount: int.tryParse((handCounts == null ? '' : (handCounts![uid] ?? '')).toString()) ?? 0,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _avatarUrl(String? thumb, String? full) {
    final t = thumb?.trim();
    if (t != null && t.isNotEmpty) return t;
    final f = full?.trim();
    if (f != null && f.isNotEmpty) return f;
    return null;
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.isMe,
    required this.isActive,
    required this.isAttacker,
    required this.isDefender,
    required this.canThrowIn,
    required this.passed,
    required this.cardCount,
  });

  final String uid;
  final String name;
  final String? avatarUrl;
  final bool isMe;
  final bool isActive;
  final bool isAttacker;
  final bool isDefender;
  final bool canThrowIn;
  final bool passed;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final border = isActive
        ? const Color(0xFFFFC107).withValues(alpha: 0.75)
        : (isMe
            ? const Color(0xFF2E86FF).withValues(alpha: 0.70)
            : Colors.white.withValues(alpha: 0.10));

    final roleColor = isDefender
        ? const Color(0xFFEF4444)
        : (isAttacker ? const Color(0xFF22C55E) : const Color(0xFF93C5FD));

    final roleLabel = isDefender
        ? 'DEF'
        : (isAttacker ? 'ATK' : (canThrowIn ? 'THR' : '—'));

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: border),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 18, color: Colors.white70)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: roleColor.withValues(alpha: 0.85),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: isMe ? 0.95 : 0.88),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              cardCount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (passed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                'PASS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

