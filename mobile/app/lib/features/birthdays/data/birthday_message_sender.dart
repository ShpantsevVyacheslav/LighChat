import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/core/app_logger.dart';
import 'package:lighchat_mobile/features/chat/data/chat_message_draft_storage.dart';
import 'package:lighchat_mobile/features/chat/data/user_profile.dart';

/// Открывает DM с именинником и отправляет в него простой текст. Если
/// прямая отправка падает (чаще всего — E2EE-active чат, в котором мобайл-репо
/// требует encrypted envelope, или Firestore rule на конкретное сообщение) —
/// сохраняем текст как chat-draft и возвращаем `needsManualSend: true`. Тогда
/// UI открывает чат, юзер допишет/допроверит и тапнет Send в основном
/// композере, который умеет E2EE.
class BirthdaySendResult {
  const BirthdaySendResult({
    this.conversationId,
    this.needsManualSend = false,
  });

  final String? conversationId;
  final bool needsManualSend;
}

class BirthdayMessageSender {
  BirthdayMessageSender(this._ref);

  final Ref _ref;

  Future<BirthdaySendResult> sendText({
    required String currentUserId,
    required UserProfile self,
    required String contactUserId,
    required UserProfile? contactProfile,
    required String contactDisplayName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const BirthdaySendResult();
    final repo = _ref.read(chatRepositoryProvider);
    if (repo == null) return const BirthdaySendResult();

    final String convId;
    try {
      convId = await repo.createOrOpenDirectChat(
        currentUserId: currentUserId,
        otherUserId: contactUserId,
        currentUserInfo: (
          name: self.name,
          avatar: self.avatar,
          avatarThumb: self.avatarThumb,
        ),
        otherUserInfo: (
          name: contactProfile?.name ?? contactDisplayName,
          avatar: contactProfile?.avatar,
          avatarThumb: contactProfile?.avatarThumb,
        ),
      );
    } catch (e, st) {
      appLogger.w('birthday: createOrOpenDirectChat failed',
          error: e, stackTrace: st);
      return const BirthdaySendResult();
    }

    try {
      await repo.sendTextMessage(
        conversationId: convId,
        senderId: currentUserId,
        text: trimmed,
      );
      return BirthdaySendResult(conversationId: convId);
    } catch (e, st) {
      // Чаще всего сюда падает E2eeNotSupportedOnMobileException — чат уже
      // E2EE-active, и наш плейн-отправка не подходит. Сохраняем как черновик,
      // UI откроет чат — там основной композер зашифрует и отправит как надо.
      appLogger.w('birthday: sendTextMessage failed, fallback to draft',
          error: e, stackTrace: st);
      await saveChatMessageDraft(
        currentUserId,
        convId,
        StoredChatMessageDraft(
          html: trimmed,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return BirthdaySendResult(
        conversationId: convId,
        needsManualSend: true,
      );
    }
  }
}

final birthdayMessageSenderProvider =
    Provider<BirthdayMessageSender>((ref) => BirthdayMessageSender(ref));
