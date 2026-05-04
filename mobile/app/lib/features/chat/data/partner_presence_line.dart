import '../../../l10n/app_localizations.dart';
import 'last_seen_relative.dart';
import 'user_profile.dart';

/// Подзаголовок шапки чата и профиля для личного диалога (онлайн / последний вход).
String partnerPresenceLine(UserProfile? p, AppLocalizations l10n) {
  if (p == null) return l10n.presence_offline;
  if (p.deletedAt != null && p.deletedAt!.isNotEmpty) return '';
  final privacy = p.privacySettings;
  final canShowOnline = privacy?.showOnlineStatus != false;
  final canShowLastSeen = privacy?.showLastSeen != false;
  if (canShowOnline && p.online == true) return l10n.presence_online;
  final last = p.lastSeenAt;
  if (canShowLastSeen && last != null) return formatLastSeenStatus(last, l10n);
  return l10n.presence_offline;
}
