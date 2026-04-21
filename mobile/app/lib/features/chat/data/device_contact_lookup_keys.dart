import 'dart:convert';

import 'package:flutter_contacts/flutter_contacts.dart';

String normalizePhoneDigits(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('8') && d.length == 11) d = '7${d.substring(1)}';
  if (d.length == 10) d = '7$d';
  return d;
}

String _utf8ToBase64Url(String value) {
  final bytes = utf8.encode(value);
  return base64Url.encode(bytes).replaceAll('=', '');
}

String? registrationPhoneKey(String? rawPhone) {
  final d = normalizePhoneDigits(rawPhone ?? '');
  if (d.length < 10) return null;
  return 'p_$d';
}

String? registrationEmailKey(String? rawEmail) {
  final email = (rawEmail ?? '').trim().toLowerCase();
  if (email.isEmpty) return null;
  return 'e_${_utf8ToBase64Url(email)}';
}

Map<String, String> collectLookupKeysFromDeviceContacts(
  List<Contact> contacts,
) {
  final out = <String, String>{};
  for (final c in contacts) {
    for (final phone in c.phones) {
      final key = registrationPhoneKey(phone.number);
      if (key != null) out[key] = 'phone';
    }
    for (final email in c.emails) {
      final key = registrationEmailKey(email.address);
      if (key != null) out[key] = 'email';
    }
  }
  return out;
}
