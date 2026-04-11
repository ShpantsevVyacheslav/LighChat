import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

enum MessageSheetAction { reply, forward, pin, edit, delete, select }

Future<MessageSheetAction?> showMessageActionSheet(
  BuildContext context, {
  required ChatMessage message,
  required bool canEdit,
  required bool canDelete,
}) {
  return showModalBottomSheet<MessageSheetAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Ответить'),
              onTap: () => Navigator.pop(ctx, MessageSheetAction.reply),
            ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Переслать'),
              onTap: () => Navigator.pop(ctx, MessageSheetAction.forward),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Закрепить'),
              onTap: () => Navigator.pop(ctx, MessageSheetAction.pin),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Выбрать'),
              onTap: () => Navigator.pop(ctx, MessageSheetAction.select),
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Изменить'),
                onTap: () => Navigator.pop(ctx, MessageSheetAction.edit),
              ),
            if (canDelete)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
                title: Text('Удалить', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () => Navigator.pop(ctx, MessageSheetAction.delete),
              ),
          ],
        ),
      );
    },
  );
}
