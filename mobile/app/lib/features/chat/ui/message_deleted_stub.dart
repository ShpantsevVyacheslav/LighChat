import 'package:flutter/material.dart';

class MessageDeletedStub extends StatelessWidget {
  const MessageDeletedStub({super.key, required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, size: 16, color: scheme.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 6),
            Text(
              'Сообщение удалено',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

