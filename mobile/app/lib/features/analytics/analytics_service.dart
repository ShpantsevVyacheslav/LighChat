import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_events.dart';

/// Абстрактный sink — позволяет подменить транспорт в тестах и под Windows/Linux,
/// где `firebase_analytics` нет.
abstract class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object?> params);
  Future<void> setUserId(String? uid);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setCollectionEnabled(bool enabled);
}

class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink(this._fa, this._log);
  final FirebaseAnalytics _fa;
  final Logger _log;

  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {
    try {
      await _fa.logEvent(name: name, parameters: _toFa(params));
    } catch (e, st) {
      _log.d('analytics.logEvent($name) failed: $e\n$st');
    }
  }

  @override
  Future<void> setUserId(String? uid) async {
    try {
      await _fa.setUserId(id: uid);
    } catch (e) {
      _log.d('analytics.setUserId failed: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _fa.setUserProperty(name: name, value: value);
    } catch (e) {
      _log.d('analytics.setUserProperty failed: $e');
    }
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await _fa.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      _log.d('analytics.setCollectionEnabled failed: $e');
    }
  }

  Map<String, Object> _toFa(Map<String, Object?> params) {
    final out = <String, Object>{};
    params.forEach((k, v) {
      if (v == null) return;
      if (v is String || v is num || v is bool) {
        out[k] = v;
      } else {
        out[k] = v.toString();
      }
    });
    return out;
  }
}

/// Fallback для Windows/Linux: события идут через callable `logAnalyticsEvent`.
class CallableAnalyticsSink implements AnalyticsSink {
  CallableAnalyticsSink(this._functions, this._log);
  final FirebaseFunctions _functions;
  final Logger _log;

  String? _uid;
  bool _enabled = true;

  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {
    if (!_enabled) return;
    try {
      await _functions.httpsCallable('logAnalyticsEvent').call({
        'event': name,
        'params': params,
        'uid': _uid,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _log.d('callable analytics($name) failed: $e');
    }
  }

  @override
  Future<void> setUserId(String? uid) async {
    _uid = uid;
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    // user properties для callable не очень полезны на десктопе — сохраняем
    // в Firestore через тот же callable как отдельное событие.
    if (!_enabled) return;
    await logEvent('user_property_set', {'name': name, 'value': value});
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
  }
}

class NoopAnalyticsSink implements AnalyticsSink {
  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {}
  @override
  Future<void> setUserId(String? uid) async {}
  @override
  Future<void> setUserProperty(String name, String? value) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Возвращает имя текущей платформы для параметра `platform` всех событий.
String currentPlatformLabel() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'web';
}

bool platformSupportsFirebaseAnalytics() {
  if (kIsWeb) return true;
  return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
}

class AnalyticsService {
  AnalyticsService({required AnalyticsSink sink, required Logger logger})
      : _sink = sink,
        _log = logger,
        _platform = currentPlatformLabel();

  final AnalyticsSink _sink;
  final Logger _log;
  final String _platform;

  bool _consentGranted = false;
  String? _appVersion;
  String? _locale;
  final Set<String> _openedChats = {};

  static const _kConsentPrefsKey = 'lc_analytics_consent_v1';

  /// Вычитывает consent из SharedPreferences. Возвращает true если был выдан.
  Future<bool> init({String? appVersion, String? locale}) async {
    _appVersion = appVersion;
    _locale = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kConsentPrefsKey);
      _consentGranted = v == 'all';
      await _sink.setCollectionEnabled(_consentGranted);
    } catch (e) {
      _log.d('analytics.init prefs read failed: $e');
    }
    return _consentGranted;
  }

  Future<void> setConsent(String decision) async {
    _consentGranted = decision == 'all';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kConsentPrefsKey, decision);
    } catch (_) {}
    await _sink.setCollectionEnabled(_consentGranted);
    if (_consentGranted) {
      await logEvent(AnalyticsEvents.sessionStart, const {});
    }
  }

  bool get hasConsent => _consentGranted;

  Future<void> logEvent(String name, Map<String, Object?> params) async {
    if (!_consentGranted && !_alwaysServer.contains(name)) {
      _log.d('analytics: drop $name (no consent)');
      return;
    }
    final enriched = <String, Object?>{
      ...params,
      'platform': _platform,
      if (_appVersion != null) 'app_version': _appVersion,
      if (_locale != null) 'locale': _locale,
    };
    await _sink.logEvent(name, enriched);
  }

  Future<void> identify(String? uid) async {
    await _sink.setUserId(uid);
  }

  Future<void> setUserProperty(String name, String? value) async {
    if (!_consentGranted) return;
    await _sink.setUserProperty(name, value);
  }

  /// Идемпотент: первое открытие конкретного `chatId` помечается флагом.
  Future<void> trackChatOpened(String chatId, {required String chatType}) async {
    final isFirst = !_openedChats.contains(chatId);
    _openedChats.add(chatId);
    await logEvent(AnalyticsEvents.chatOpened, {
      'chat_type': chatType,
      'is_first_open': isFirst,
    });
  }

  static const _alwaysServer = <String>{
    AnalyticsEvents.signUpSuccess,
    AnalyticsEvents.signUpFailure,
    AnalyticsEvents.loginSuccess,
    AnalyticsEvents.errorOccurred,
    AnalyticsEvents.accountDeleted,
    AnalyticsEvents.purchaseCompleted,
    AnalyticsEvents.purchaseFailed,
  };
}
