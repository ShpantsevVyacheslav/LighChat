import 'user_profile.dart';

/// Как web `isProfileFieldVisibleToOthers`: если флаг в `privacySettings` не задан — `true`.
bool isProfileFieldVisibleToOthers(UserProfile? subject, String field) {
  final p = subject?.privacySettings;
  if (p == null) return true;
  switch (field) {
    case 'email':
      return p.showEmailToOthers != false;
    case 'phone':
      return p.showPhoneToOthers != false;
    case 'bio':
      return p.showBioToOthers != false;
    case 'dateOfBirth':
      return p.showDateOfBirthToOthers != false;
    default:
      return true;
  }
}
