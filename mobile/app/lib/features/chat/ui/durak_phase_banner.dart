import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class DurakPhaseBanner extends StatelessWidget {
  const DurakPhaseBanner({
    super.key,
    required this.phase,
    required this.attackerUid,
    required this.defenderUid,
    required this.throwerUids,
    required this.pendingResolution,
    required this.me,
  });

  final String phase;
  final String attackerUid;
  final String defenderUid;
  final List<String> throwerUids;
  final bool pendingResolution;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String phaseLabel() {
      if (pendingResolution) return l10n.durak_phase_pending_foul;
      switch (phase) {
        case 'attack':
          return l10n.durak_phase_attack;
        case 'defense':
          return l10n.durak_phase_defense;
        case 'throwIn':
          return l10n.durak_phase_throw_in;
        case 'resolution':
          return l10n.durak_phase_resolution;
        case 'finished':
          return l10n.durak_phase_finished;
        default:
          return phase.isEmpty ? '—' : phase;
      }
    }

    final role = me == null
        ? ''
        : (me == attackerUid
            ? l10n.conversation_durak_role_attacker
            : (me == defenderUid
                ? l10n.conversation_durak_role_defender
                : l10n.conversation_durak_role_thrower));

    final meCanThrowIn = me != null && throwerUids.contains(me);
    final hint = pendingResolution
        ? (me == attackerUid
            ? l10n.durak_phase_pending_foul_hint_attacker
            : l10n.durak_phase_pending_foul_hint_other)
        : (meCanThrowIn ? l10n.durak_phase_hint_can_throw_in : l10n.durak_phase_hint_wait);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey<String>('p:$phase:pr:$pendingResolution:r:$role:t:$meCanThrowIn'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pendingResolution
                    ? const Color(0xFFFFC107)
                    : const Color(0xFF6EE7B7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.durak_phase_prefix}: ${phaseLabel()}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.isEmpty ? hint : '$role · $hint',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
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

