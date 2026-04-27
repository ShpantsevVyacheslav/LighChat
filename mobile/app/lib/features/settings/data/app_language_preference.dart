import 'dart:ui' show Locale;

import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguagePreference {
  system,
  ru,
  en;

  static AppLanguagePreference fromStorage(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'ru':
        return AppLanguagePreference.ru;
      case 'en':
        return AppLanguagePreference.en;
      case 'system':
      default:
        return AppLanguagePreference.system;
    }
  }

  String toStorage() => name;

  /// Null = follow device locale (Flutter default behavior).
  Locale? toLocaleOrNull() {
    switch (this) {
      case AppLanguagePreference.system:
        return null;
      case AppLanguagePreference.ru:
        return const Locale('ru');
      case AppLanguagePreference.en:
        return const Locale('en');
    }
  }
}

const _kPrefKey = 'appLanguagePreference';

class AppLanguagePreferenceNotifier extends Notifier<AppLanguagePreference> {
  @override
  AppLanguagePreference build() {
    // Default to system until prefs are loaded.
    unawaited(_loadFromPrefs());
    return AppLanguagePreference.system;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = AppLanguagePreference.fromStorage(
      prefs.getString(_kPrefKey),
    );
    if (state == loaded) return;
    state = loaded;
  }

  Future<void> setPreference(AppLanguagePreference next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, next.toStorage());
  }
}

final appLanguagePreferenceProvider =
    NotifierProvider<AppLanguagePreferenceNotifier, AppLanguagePreference>(
      AppLanguagePreferenceNotifier.new,
    );
