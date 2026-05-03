import '../../../l10n/app_localizations.dart';

// Паритет с web `src/lib/user-block-utils.ts`.

List<String> normalizeBlockedUserIds(Object? raw) {
  if (raw is! List) return const <String>[];
  final out = <String>{};
  for (final e in raw) {
    final s = e.toString().trim();
    if (s.isNotEmpty) out.add(s);
  }
  return out.toList(growable: false);
}

/// Личный чат: viewer заблокировал partner **или** partner заблокировал viewer.
///
/// [partnerBlockedIds] — текущее содержимое `users/{partnerId}.blockedUserIds` (может быть пустым).
/// [partnerUserDocDenied] — `true`, если документ партнёра недоступен (часто partner заблокировал viewer).
bool isEitherBlockingFromUserIds({
  required String viewerId,
  required List<String> viewerBlockedIds,
  required String partnerId,
  required List<String> partnerBlockedIds,
  bool partnerUserDocDenied = false,
}) {
  final my = normalizeBlockedUserIds(viewerBlockedIds);
  if (my.contains(partnerId)) return true;
  if (partnerUserDocDenied) return true;
  return normalizeBlockedUserIds(partnerBlockedIds).contains(viewerId);
}

String directCallBlockedMessageRu({
  required AppLocalizations l10n,
  required String viewerId,
  required List<String> viewerBlockedIds,
  required String partnerId,
  required List<String> partnerBlockedIds,
  bool partnerUserDocDenied = false,
}) {
  if (normalizeBlockedUserIds(viewerBlockedIds).contains(partnerId)) {
    return l10n.block_call_viewer_blocked;
  }
  if (partnerUserDocDenied ||
      normalizeBlockedUserIds(partnerBlockedIds).contains(viewerId)) {
    return l10n.block_call_partner_blocked;
  }
  return l10n.block_call_unavailable;
}
