import 'last_seen_relative_ru.dart';
import 'user_profile.dart';

/// Подзаголовок шапки чата и профиля для личного диалога (онлайн / последний вход).
String partnerPresenceLine(UserProfile? p) {
  if (p == null) return 'Не в сети';
  if (p.deletedAt != null && p.deletedAt!.isNotEmpty) return '';
  final privacy = p.privacySettings;
  final canShowOnline = privacy?.showOnlineStatus != false;
  final canShowLastSeen = privacy?.showLastSeen != false;
  if (canShowOnline && p.online == true) return 'В сети';
  final last = p.lastSeenAt;
  if (canShowLastSeen && last != null) return formatLastSeenStatusRu(last);
  return 'Не в сети';
}
