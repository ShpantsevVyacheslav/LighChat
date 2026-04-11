import 'last_seen_relative_ru.dart';
import 'user_profile.dart';

/// Подзаголовок шапки чата и профиля для личного диалога (онлайн / последний вход).
String partnerPresenceLine(UserProfile? p) {
  if (p == null) return 'Не в сети';
  if (p.deletedAt != null && p.deletedAt!.isNotEmpty) return '';
  if (p.online == true) return 'В сети';
  final last = p.lastSeenAt;
  if (last != null) return formatLastSeenStatusRu(last);
  return 'Не в сети';
}
