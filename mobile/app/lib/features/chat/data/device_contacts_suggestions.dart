import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../l10n/app_localizations.dart';
import 'device_contact_lookup_keys.dart';
import 'new_chat_user_search.dart' show ruEnSubstringMatch;
import 'user_contacts_repository.dart';

class DeviceContactCandidate {
  const DeviceContactCandidate({
    required this.contactId,
    required this.displayName,
    required this.subtitle,
    required this.lookupKeys,
  });

  final String contactId;
  final String displayName;
  final String subtitle;
  final Set<String> lookupKeys;
}

class DeviceContactResolved {
  const DeviceContactResolved({required this.candidate, required this.userId});

  final DeviceContactCandidate candidate;
  final String userId;
}

String _normalizeSearch(String input) {
  return input.trim().toLowerCase();
}

bool deviceContactMatchesQuery(Contact c, String rawTerm) {
  final term = _normalizeSearch(rawTerm);
  if (term.isEmpty) return false;
  final displayName = (c.displayName ?? '').trim();
  if (displayName.isNotEmpty && ruEnSubstringMatch(displayName, term)) {
    return true;
  }
  final termDigits = term.replaceAll(RegExp(r'\D'), '');
  for (final p in c.phones) {
    final digits = normalizePhoneDigits(p.number);
    if (termDigits.isNotEmpty && digits.contains(termDigits)) return true;
  }
  for (final e in c.emails) {
    final addr = (e.address).trim();
    if (addr.isNotEmpty && ruEnSubstringMatch(addr, term)) return true;
  }
  return false;
}

Future<List<Contact>> loadDeviceContactsIfGranted() async {
  final permission = await FlutterContacts.permissions.request(
    PermissionType.read,
  );
  final granted =
      permission == PermissionStatus.granted ||
      permission == PermissionStatus.limited;
  if (!granted) return const <Contact>[];
  return FlutterContacts.getAll(
    properties: <ContactProperty>{ContactProperty.phone, ContactProperty.email},
  );
}

List<DeviceContactCandidate> buildDeviceContactCandidates({
  required List<Contact> contacts,
  required String term,
  required AppLocalizations l10n,
  int limit = 24,
}) {
  final out = <DeviceContactCandidate>[];
  for (final c in contacts) {
    if (!deviceContactMatchesQuery(c, term)) continue;
    final keys = collectLookupKeysFromDeviceContacts([c]).keys.toSet();
    if (keys.isEmpty) continue;
    final displayName = (c.displayName ?? '').trim();
    final title = displayName.isNotEmpty ? displayName : l10n.contacts_fallback_name;
    final subtitle = () {
      final phone = c.phones.isNotEmpty ? (c.phones.first.number).trim() : '';
      if (phone.isNotEmpty) return phone;
      final email = c.emails.isNotEmpty ? c.emails.first.address.trim() : '';
      return email;
    }();
    out.add(
      DeviceContactCandidate(
        contactId: (c.id ?? '').trim(),
        displayName: title,
        subtitle: subtitle,
        lookupKeys: keys,
      ),
    );
    if (out.length >= limit) break;
  }
  return out;
}

Future<Map<String, String>> resolveCandidatesToUserIds({
  required UserContactsRepository repo,
  required List<DeviceContactCandidate> candidates,
}) async {
  if (candidates.isEmpty) return const <String, String>{};
  final allKeys = <String>{};
  for (final c in candidates) {
    allKeys.addAll(c.lookupKeys);
  }
  final userIds = await repo.resolveUserIdsByRegistrationLookupKeys(allKeys);
  if (userIds.isEmpty) return const <String, String>{};

  // Map key -> uid by re-reading registrationIndex is too expensive here.
  // We instead best-effort: for each candidate, re-check its keys until first uid found.
  // This stays small because candidates are already limited.
  final out = <String, String>{};
  for (final cand in candidates) {
    final hit = await repo.resolveUserIdsByRegistrationLookupKeys(
      cand.lookupKeys,
    );
    if (hit.isNotEmpty) {
      out[cand.contactId] = hit.first;
    }
  }
  return out;
}

Rect shareOriginForContext(BuildContext context) {
  final mq = MediaQuery.maybeOf(context);
  final size = mq?.size;
  if (size == null) return const Rect.fromLTWH(0, 0, 1, 1);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
