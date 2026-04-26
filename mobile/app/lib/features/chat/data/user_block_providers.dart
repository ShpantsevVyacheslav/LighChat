import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'chat_outbox_attachment_notifier.dart';

/// Список uid, которых этот пользователь заблокировал (`users.blockedUserIds`).
final userBlockedUserIdsProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  final u = uid.trim();
  if (u.isEmpty) {
    return Stream<List<String>>.value(const <String>[]);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(u)
      .snapshots()
      .map((s) {
    final raw = s.data()?['blockedUserIds'];
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  });
});

/// Баннер для [ChatComposer.e2eeDisabledBanner]: личный чат, блокировка с любой стороны.
Widget? dmComposerBlockBanner({
  required BuildContext context,
  required WidgetRef ref,
  required String currentUserId,
  required Conversation? conv,
}) {
  if (conv == null || conv.isGroup) return null;
  final others =
      conv.participantIds.where((id) => id != currentUserId).toList();
  if (others.length != 1) return null;
  final partnerId = others.first;
  final myAsync = ref.watch(userBlockedUserIdsProvider(currentUserId));
  final theirAsync = ref.watch(userBlockedUserIdsProvider(partnerId));
  final myBlocked = myAsync.value ?? const <String>[];
  final theirBlocked = theirAsync.value ?? const <String>[];
  final iBlocked = myBlocked.contains(partnerId);
  final theyBlockedMe = theirBlocked.contains(currentUserId);
  if (!iBlocked && !theyBlockedMe) return null;

  final scheme = Theme.of(context).colorScheme;
  final msg = iBlocked
      ? 'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.'
      : 'Пользователь ограничил с вами общение. Отправка недоступна.';
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          msg,
          style: TextStyle(
            color: scheme.onErrorContainer,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    ),
  );
}

void handleOutboxRetry(WidgetRef ref, String messageId) {
  final jid = outboxJobIdFromSyntheticMessageId(messageId);
  if (jid == null) return;
  ref.read(chatOutboxAttachmentNotifierProvider.notifier).retry(jid);
}

Future<void> handleOutboxDismiss(WidgetRef ref, String messageId) async {
  final jid = outboxJobIdFromSyntheticMessageId(messageId);
  if (jid == null) return;
  final jobs = ref.read(chatOutboxAttachmentNotifierProvider);
  OutboxAttachmentJob? hit;
  for (final j in jobs) {
    if (j.id == jid) {
      hit = j;
      break;
    }
  }
  if (hit == null) return;
  final n = ref.read(chatOutboxAttachmentNotifierProvider.notifier);
  if (hit.phase == OutboxAttachmentPhase.failed) {
    await n.removeJobDisplay(jid);
  } else {
    n.requestCancelInFlight(jid);
  }
}
