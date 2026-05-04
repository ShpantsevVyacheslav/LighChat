import 'package:lighchat_firebase/lighchat_firebase.dart'
    show isNormalizedUsernameTokenAllowed, normalizeUsernameCandidate;

import '../../../l10n/app_localizations.dart';
import 'phone_ru_format.dart';

String normalizePhoneDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String? validateName(String value, AppLocalizations l10n) {
  if (value.trim().length < 2) {
    return l10n.auth_validate_name_min_length;
  }
  return null;
}

String? validateUsername(String value, AppLocalizations l10n) {
  final raw = value.trim();
  final normalized = normalizeUsernameCandidate(raw);
  if (normalized.length < 3) {
    return l10n.auth_validate_username_min_length;
  }
  if (normalized.length > 30) return l10n.auth_validate_username_max_length;
  if (!isNormalizedUsernameTokenAllowed(normalized)) {
    return l10n.auth_validate_username_format;
  }
  return null;
}

String? validatePhone11(String value, AppLocalizations l10n) {
  final digits = normalizePhoneDigits(normalizePhoneRuToE164(value));
  if (digits.length != 11) return l10n.auth_validate_phone_11_digits;
  return null;
}

/// Допускает пустой телефон (0 цифр или только код страны "7").
/// Используется при редактировании профиля, где номер опционален
/// (например, для OAuth-аккаунтов без телефона).
String? validatePhoneOptional(String value, AppLocalizations l10n) {
  final digits = normalizePhoneDigits(normalizePhoneRuToE164(value));
  if (digits.isEmpty || digits == '7') return null;
  if (digits.length != 11) return l10n.auth_validate_phone_11_digits;
  return null;
}

String? validateEmail(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
    return l10n.auth_validate_email_format;
  }
  return null;
}

String? validateDateOfBirth(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (v.isEmpty) return null;
  final dt = DateTime.tryParse(v);
  if (dt == null) return l10n.auth_validate_dob_invalid;
  final year = dt.year;
  final currentYear = DateTime.now().year;
  if (year < 1920 || year > currentYear) return l10n.auth_validate_dob_invalid;
  return null;
}

String? validateBio(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (v.isEmpty) return null;
  if (v.length > 200) return l10n.auth_validate_bio_max_length;
  return null;
}

String? validatePassword(String value, AppLocalizations l10n) {
  if (value.length < 6) return l10n.auth_validate_password_min_length;
  return null;
}

String? validateConfirmPassword(
  String password,
  String confirm,
  AppLocalizations l10n,
) {
  if (password != confirm) return l10n.auth_validate_passwords_mismatch;
  return null;
}
