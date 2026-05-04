import 'package:lighchat_firebase/lighchat_firebase.dart'
    show isNormalizedUsernameTokenAllowed, normalizeUsernameCandidate;

import 'phone_ru_format.dart';

String normalizePhoneDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String? validateName(String value) {
  if (value.trim().length < 2) {
    return 'Укажите имя (не менее 2 символов).';
  }
  return null;
}

String? validateUsername(String value) {
  final raw = value.trim();
  final normalized = normalizeUsernameCandidate(raw);
  if (normalized.length < 3) {
    return 'Логин должен содержать не менее 3 символов.';
  }
  if (normalized.length > 30) return 'Логин не должен превышать 30 символов.';
  if (!isNormalizedUsernameTokenAllowed(normalized)) {
    return 'Только латиница, цифры, _ и . (точка не в начале/конце, без ..).';
  }
  return null;
}

String? validatePhone11(String value) {
  final digits = normalizePhoneDigits(normalizePhoneRuToE164(value));
  if (digits.length != 11) return 'Введите полный номер телефона (11 цифр).';
  return null;
}

/// Допускает пустой телефон (0 цифр или только код страны "7").
/// Используется при редактировании профиля, где номер опционален
/// (например, для OAuth-аккаунтов без телефона).
String? validatePhoneOptional(String value) {
  final digits = normalizePhoneDigits(normalizePhoneRuToE164(value));
  if (digits.isEmpty || digits == '7') return null;
  if (digits.length != 11) return 'Введите полный номер телефона (11 цифр).';
  return null;
}

String? validateEmail(String value) {
  final v = value.trim();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
    return 'Неверный формат email.';
  }
  return null;
}

String? validateDateOfBirth(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  final dt = DateTime.tryParse(v);
  if (dt == null) return 'Некорректная дата рождения.';
  final year = dt.year;
  final currentYear = DateTime.now().year;
  if (year < 1920 || year > currentYear) return 'Некорректная дата рождения.';
  return null;
}

String? validateBio(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  if (v.length > 200) return 'Не более 200 символов.';
  return null;
}

String? validatePassword(String value) {
  if (value.length < 6) return 'Пароль должен содержать не менее 6 символов.';
  return null;
}

String? validateConfirmPassword(String password, String confirm) {
  if (password != confirm) return 'Пароли не совпадают.';
  return null;
}
