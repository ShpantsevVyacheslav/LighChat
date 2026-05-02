import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'schedule_message_sheet.dart';

/// Экран управления отложенными сообщениями текущего пользователя в чате.
/// Показывает список pending-сообщений (отсортирован по `sendAt asc`),
/// позволяет отменить или перенести время.
class ScheduledMessagesScreen extends StatelessWidget {
  const ScheduledMessagesScreen({
    super.key,
    required this.repository,
    required this.conversationId,
    required this.currentUserId,
    this.e2eeEnabled = false,
  });

  final ChatRepository repository;
  final String conversationId;
  final String currentUserId;
  final bool e2eeEnabled;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy, HH:mm', 'ru');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запланированные сообщения'),
      ),
      body: StreamBuilder<List<ScheduledChatMessage>>(
        stream: repository.watchScheduledMessages(
          conversationId: conversationId,
          userId: currentUserId,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Не удалось загрузить: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snap.data ?? const <ScheduledChatMessage>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_send_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Нет запланированных сообщений',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Удерживайте кнопку «Отправить», чтобы запланировать.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length + (e2eeEnabled ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              if (e2eeEnabled && idx == items.length) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'В E2EE-чате запланированные сообщения хранятся '
                          'и публикуются в открытом виде.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final m = items[idx];
              return _ScheduledMessageTile(
                message: m,
                dateFmt: dateFmt,
                onCancel: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Отменить отправку?'),
                      content: const Text(
                        'Запланированное сообщение будет удалено.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Не отменять'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Отменить'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  try {
                    await repository.cancelScheduledMessage(
                      conversationId: conversationId,
                      scheduledMessageId: m.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Отменено')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  }
                },
                onReschedule: () async {
                  final picked = await showScheduleMessageSheet(
                    context: context,
                    initialSendAt: m.sendAt,
                    showE2eeWarning: e2eeEnabled,
                  );
                  if (picked == null) return;
                  try {
                    await repository.rescheduleMessage(
                      conversationId: conversationId,
                      scheduledMessageId: m.id,
                      sendAt: picked,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Время изменено: ${dateFmt.format(picked)}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ScheduledMessageTile extends StatelessWidget {
  const _ScheduledMessageTile({
    required this.message,
    required this.dateFmt,
    required this.onCancel,
    required this.onReschedule,
  });

  final ScheduledChatMessage message;
  final DateFormat dateFmt;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  String _previewText() {
    if (message.pendingPoll != null) {
      return '📊 Опрос: ${message.pendingPoll!.question}';
    }
    if (message.locationShare != null) return '📍 Локация';
    final t = message.text;
    if (t != null) {
      final stripped = t
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      if (stripped.isNotEmpty) return stripped;
    }
    if (message.attachments.isNotEmpty) {
      return '📎 Вложение${message.attachments.length > 1 ? ' (×${message.attachments.length})' : ''}';
    }
    return 'Сообщение';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onReschedule,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(message.sendAt),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _previewText(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Изменить время',
                icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                onPressed: onReschedule,
              ),
              IconButton(
                tooltip: 'Отменить',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: cs.error,
                ),
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
