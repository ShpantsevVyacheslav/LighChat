import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: isBusy ? null : onClose,
      ),
      title: Text('$count выбрано', style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          tooltip: 'Переслать',
          onPressed: isBusy || count == 0 ? null : onForward,
          icon: const Icon(Icons.forward_rounded),
        ),
        IconButton(
          tooltip: 'Удалить',
          onPressed: isBusy || count == 0 || !canDelete ? null : onDelete,
          icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
        ),
      ],
    );
  }
}
