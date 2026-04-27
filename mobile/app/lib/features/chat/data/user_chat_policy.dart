import 'user_block_utils.dart';
import 'user_profile.dart';

/// Как web `canStartDirectChat` (`src/lib/user-chat-policy.ts`).
///
/// [partnerBlockedIdsSupplement] — если нужно переопределить `other.blockedUserIds` (например поток
/// `userBlockedUserIdsProvider` при «урезанном» [other] из `participantInfo`).
/// [partnerUserDocDenied] — `users/{other.id}` недоступен (часто other заблокировал текущего).
bool canStartDirectChat(
  UserProfile currentUser,
  UserProfile other, {
  List<String>? partnerBlockedIdsSupplement,
  bool partnerUserDocDenied = false,
}) {
  if (currentUser.id == other.id) return false;
  if (other.deletedAt != null && other.deletedAt!.isNotEmpty) return false;

  final partnerBlock =
      partnerBlockedIdsSupplement ?? other.blockedUserIds;

  if (isEitherBlockingFromUserIds(
    viewerId: currentUser.id,
    viewerBlockedIds: currentUser.blockedUserIds,
    partnerId: other.id,
    partnerBlockedIds: partnerBlock,
    partnerUserDocDenied: partnerUserDocDenied,
  )) {
    return false;
  }

  if (currentUser.role == 'admin') return true;
  if (other.role == 'admin') return true;
  if (currentUser.role == 'worker') return other.role == 'worker';
  return other.role != 'worker';
}
