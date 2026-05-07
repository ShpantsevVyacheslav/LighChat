import 'dart:ui' show Locale;

import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguagePreference {
  system,
  ru,
  en,
  kk,
  uz,
  tr,
  id,
  ptBR,
  esMX;

  /// Нативное название языка — отображается в списке выбора.
  String get nativeName {
    switch (this) {
      case AppLanguagePreference.system:
        return 'System';
      case AppLanguagePreference.ru:
        return 'Русский';
      case AppLanguagePreference.en:
        return 'English';
      case AppLanguagePreference.kk:
        return 'Қазақша';
      case AppLanguagePreference.uz:
        return 'Oʻzbekcha';
      case AppLanguagePreference.tr:
        return 'Türkçe';
      case AppLanguagePreference.id:
        return 'Bahasa Indonesia';
      case AppLanguagePreference.ptBR:
        return 'Português (BR)';
      case AppLanguagePreference.esMX:
        return 'Español (MX)';
    }
  }

  static AppLanguagePreference fromStorage(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'ru':
        return AppLanguagePreference.ru;
      case 'en':
        return AppLanguagePreference.en;
      case 'kk':
        return AppLanguagePreference.kk;
      case 'uz':
        return AppLanguagePreference.uz;
      case 'tr':
        return AppLanguagePreference.tr;
      case 'id':
        return AppLanguagePreference.id;
      case 'ptbr':
      case 'pt-br':
      case 'pt_br':
        return AppLanguagePreference.ptBR;
      case 'esmx':
      case 'es-mx':
      case 'es_mx':
        return AppLanguagePreference.esMX;
      case 'system':
      default:
        return AppLanguagePreference.system;
    }
  }

  String toStorage() {
    switch (this) {
      case AppLanguagePreference.ptBR:
        return 'ptBR';
      case AppLanguagePreference.esMX:
        return 'esMX';
      default:
        return name;
    }
  }

  /// Null = follow device locale (Flutter default behavior).
  Locale? toLocaleOrNull() {
    switch (this) {
      case AppLanguagePreference.system:
        return null;
      case AppLanguagePreference.ru:
        return const Locale('ru');
      case AppLanguagePreference.en:
        return const Locale('en');
      case AppLanguagePreference.kk:
        return const Locale('kk');
      case AppLanguagePreference.uz:
        return const Locale('uz');
      case AppLanguagePreference.tr:
        return const Locale('tr');
      case AppLanguagePreference.id:
        return const Locale('id');
      case AppLanguagePreference.ptBR:
        return const Locale('pt', 'BR');
      case AppLanguagePreference.esMX:
        return const Locale('es', 'MX');
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
