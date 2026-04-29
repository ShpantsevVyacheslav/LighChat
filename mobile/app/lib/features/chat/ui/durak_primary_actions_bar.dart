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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Text(
                l10n.common_choose,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < prim.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: prim[i].onTap,
                child: Text(prim[i].label),
              ),
            ),
          ],
          if (hasOverflow) ...[
            if (prim.isNotEmpty) const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              child: PopupMenuButton<int>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white.withValues(alpha: 0.88),
                  size: 28,
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
