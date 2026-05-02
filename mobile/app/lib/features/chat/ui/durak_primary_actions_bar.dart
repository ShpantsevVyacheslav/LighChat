import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Large Pass / Take / Beat / Resolve row plus overflow for card-based and shuler actions.
class DurakPrimaryActionsBar extends StatelessWidget {
  const DurakPrimaryActionsBar({
    super.key,
    required this.l10n,
    required this.primaryActions,
    required this.overflowActions,
  });

  final AppLocalizations l10n;
  final List<({String label, VoidCallback onTap})> primaryActions;
  final List<({String label, VoidCallback onTap})> overflowActions;

  @override
  Widget build(BuildContext context) {
    final prim = primaryActions.take(2).toList();
    final hasOverflow = overflowActions.isNotEmpty;

    if (prim.isEmpty && !hasOverflow) {
      return const SizedBox.shrink();
    }

    if (prim.isEmpty && hasOverflow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SizedBox(
          width: double.infinity,
          child: PopupMenuButton<int>(
            onSelected: (i) => overflowActions[i].onTap(),
            itemBuilder: (context) => [
              for (var j = 0; j < overflowActions.length; j++)
                PopupMenuItem<int>(
                  value: j,
                  child: Text(overflowActions[j].label),
                ),
            ],
            child: _DurakActionButton(
              label: l10n.common_choose,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < prim.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _DurakActionButton(
                label: prim[i].label,
                onTap: prim[i].onTap,
              ),
            ),
          ],
          if (hasOverflow) ...[
            if (prim.isNotEmpty) const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              child: PopupMenuButton<int>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white.withValues(alpha: 0.88),
                  size: 26,
                ),
                onSelected: (i) => overflowActions[i].onTap(),
                itemBuilder: (context) => [
                  for (var j = 0; j < overflowActions.length; j++)
                    PopupMenuItem<int>(
                      value: j,
                      child: Text(overflowActions[j].label),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DurakActionButton extends StatelessWidget {
  const _DurakActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB8EC5C), Color(0xFF8FD43A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173217),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
