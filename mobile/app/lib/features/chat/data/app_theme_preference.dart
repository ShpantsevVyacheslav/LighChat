import '../../../l10n/app_localizations.dart';

enum AppThemePreference { light, dark, chat }

AppThemePreference appThemePreferenceFromRaw(Object? raw) {
  final value = raw is String ? raw.trim().toLowerCase() : '';
  switch (value) {
    case 'light':
      return AppThemePreference.light;
    case 'chat':
      return AppThemePreference.chat;
    case 'dark':
    default:
      return AppThemePreference.dark;
  }
}

String appThemePreferenceToRaw(AppThemePreference pref) {
  switch (pref) {
    case AppThemePreference.light:
      return 'light';
    case AppThemePreference.dark:
      return 'dark';
    case AppThemePreference.chat:
      return 'chat';
  }
}

String appThemePreferenceLabel(AppThemePreference pref, AppLocalizations l10n) {
  switch (pref) {
    case AppThemePreference.light:
      return l10n.theme_label_light;
    case AppThemePreference.dark:
      return l10n.theme_label_dark;
    case AppThemePreference.chat:
      return l10n.theme_label_auto;
  }
}

AppThemePreference nextAppThemePreference(AppThemePreference current) {
  switch (current) {
    case AppThemePreference.light:
      return AppThemePreference.dark;
    case AppThemePreference.dark:
      return AppThemePreference.chat;
    case AppThemePreference.chat:
      return AppThemePreference.light;
  }
}
