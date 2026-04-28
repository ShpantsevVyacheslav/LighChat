import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ChatSelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatSelectionAppBar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onForward,
    required this.onDelete,
    required this.canDelete,
    this.isBusy = false,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final bool canDelete;
  final bool isBusy;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: isBusy ? null : onClose,
      ),
      title: Text(
        l10n.chat_selection_selected_count(count),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: l10n.chat_selection_tooltip_forward,
          onPressed: isBusy || count == 0 ? null : onForward,
          icon: const Icon(Icons.forward_rounded),
        ),
        IconButton(
          tooltip: l10n.chat_selection_tooltip_delete,
          onPressed: isBusy || count == 0 || !canDelete ? null : onDelete,
          icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
        ),
      ],
    );
  }
}
