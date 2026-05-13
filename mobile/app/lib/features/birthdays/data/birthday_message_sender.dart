import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/chat/data/user_profile.dart';

/// Открывает DM с именинником и отправляет в него простой текст.
/// Возвращает `conversationId` либо `null` если что-то пошло не так
/// (например, нет ChatRepository — Firebase ещё не готов).
class BirthdaySendResult {
  const BirthdaySendResult(this.conversationId);
  final String? conversationId;
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
    if (trimmed.isEmpty) return const BirthdaySendResult(null);
    final repo = _ref.read(chatRepositoryProvider);
    if (repo == null) return const BirthdaySendResult(null);

    final convId = await repo.createOrOpenDirectChat(
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
    await repo.sendTextMessage(
      conversationId: convId,
      senderId: currentUserId,
      text: trimmed,
    );
    return BirthdaySendResult(convId);
  }
}

final birthdayMessageSenderProvider =
    Provider<BirthdayMessageSender>((ref) => BirthdayMessageSender(ref));
