import 'user_profile.dart';

/// Как web `canStartDirectChat`.
bool canStartDirectChat(UserProfile currentUser, UserProfile other) {
  if (currentUser.id == other.id) return false;
  if (other.deletedAt != null && other.deletedAt!.isNotEmpty) return false;
  if (currentUser.role == 'admin') return true;
  if (other.role == 'admin') return true;
  if (currentUser.role == 'worker') return other.role == 'worker';
  return other.role != 'worker';
}
