import 'user_contacts_repository.dart';

String buildContactDisplayName({String? firstName, String? lastName}) {
  final first = (firstName ?? '').trim();
  final last = (lastName ?? '').trim();
  return [first, last].where((x) => x.isNotEmpty).join(' ').trim();
}

String resolveContactDisplayName({
  required Map<String, ContactLocalProfile> contactProfiles,
  required String? contactUserId,
  required String fallbackName,
}) {
  final id = (contactUserId ?? '').trim();
  if (id.isEmpty) return fallbackName;
  final local = contactProfiles[id];
  if (local == null) return fallbackName;
  final display = (local.displayName ?? '').trim();
  if (display.isNotEmpty) return display;
  final composed = buildContactDisplayName(
    firstName: local.firstName,
    lastName: local.lastName,
  );
  return composed.isNotEmpty ? composed : fallbackName;
}

({String firstName, String lastName}) splitNameForContactForm(String source) {
  final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return (firstName: '', lastName: '');
  }
  final parts = normalized.split(' ');
  if (parts.length == 1) {
    return (firstName: parts.first, lastName: '');
  }
  return (firstName: parts.first, lastName: parts.skip(1).join(' ').trim());
}
