import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/disappearing_messages_label.dart';

/// Пресеты TTL (секунды); null = выкл.
const List<({String label, int? ttlSec})> _kPresets = <({String label, int? ttlSec})>[
  (label: 'Выключено', ttlSec: null),
  (label: '1 ч', ttlSec: 3600),
  (label: '24 ч', ttlSec: 86400),
  (label: '7 дн.', ttlSec: 604800),
  (label: '30 дн.', ttlSec: 2592000),
];

bool _canEditDisappearing(Conversation c, String uid) {
  if (!c.isGroup) return true;
  final created = c.createdByUserId;
  if (created != null && created == uid) return true;
  return c.adminIds.contains(uid);
}

/// Настройка исчезающих сообщений для беседы (личная или группа).
class ConversationDisappearingScreen extends StatelessWidget {
  const ConversationDisappearingScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.initialConversation,
  });

  final String conversationId;
  final String currentUserId;
  final Conversation initialConversation;

  Future<void> _apply(BuildContext context, Conversation conv, int? ttlSec) async {
    if (!_canEditDisappearing(conv, currentUserId)) return;
    final ref = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
    final now = DateTime.now().toUtc().toIso8601String();
    await ref.update(<String, Object?>{
      'disappearingMessageTtlSec': ttlSec,
      'disappearingMessagesUpdatedAt': now,
      'disappearingMessagesUpdatedBy': currentUserId,
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ttlSec == null ? 'Исчезающие сообщения выключены' : 'Таймер обновлён',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Исчезающие сообщения')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .snapshots(),
        builder: (context, snap) {
          final conv = snap.hasData &&
                  snap.data != null &&
                  snap.data!.exists &&
                  snap.data!.data() != null
              ? Conversation.fromJson(
                  Map<String, Object?>.from(snap.data!.data()!),
                )
              : initialConversation;
          final canEdit = _canEditDisappearing(conv, currentUserId);
          final current = conv.disappearingMessageTtlSec;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Новые сообщения автоматически удаляются из базы после выбранного времени '
                '(от момента отправки). Уже отправленные не меняются.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (!canEdit)
                Text(
                  'Только администраторы группы могут менять этот параметр. '
                  'Сейчас: ${formatDisappearingTtlSummary(current)}.',
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8)),
                )
              else
                ..._kPresets.map((p) {
                  final active = p.ttlSec == current;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: active
                              ? scheme.primary.withValues(alpha: 0.65)
                              : scheme.outline.withValues(alpha: 0.35),
                        ),
                      ),
                      tileColor: active
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      title: Text(p.label),
                      trailing: active ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                      onTap: () => _apply(context, conv, p.ttlSec),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
