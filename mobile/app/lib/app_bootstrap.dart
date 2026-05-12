import 'dart:io' show Platform;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:logger/logger.dart';

import 'firebase_options.dart';

final logger = Logger();

/// Application bootstrap (Firebase must finish before [runApp]).
Future<void> bootstrap() async {
  // If native iOS configured Firebase early (AppDelegate), avoid double init.
  if (Firebase.apps.isNotEmpty) {
    await _activateAppCheck();
    return;
  }

  // Prevent native Firebase from crashing the process when options are clearly
  // not meant for this platform (e.g. web appId on macOS/iOS/Android).
  //
  // Исключения — Windows и Linux: у них **легитимно** используются web-style
  // appId, потому что нативного Firebase SDK для этих платформ нет
  // (`firebase_core` под Windows/Linux работает через web REST). Не
  // фильтруем `:web:` для них, иначе `Firebase.initializeApp` не вызывается
  // и весь auth/firestore стек падает с `[core/no-app]`.
  if (!kIsWeb && !Platform.isWindows && !Platform.isLinux) {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts.appId.contains(':web:')) {
      logger.w(
        'Firebase options look like web options (appId contains ":web:"). '
        'Skipping Firebase.initializeApp on native until you run FlutterFire configure.',
      );
      return;
    }
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    logger.w('Firebase.initializeApp failed.', error: e, stackTrace: st);
    return;
  }

  await _activateAppCheck();
}

/// [audit CR-002] Firebase App Check для mobile (iOS + Android).
///
/// - iOS 14+: `AppleProvider.appAttestWithDeviceCheckFallback` — Secure Enclave
///   через App Attest, fallback на DeviceCheck для iOS <14 (мало кто остался).
/// - Android: `AndroidProvider.playIntegrity` — подпись Play Store + Play
///   Integrity API.
/// - Debug builds: `AppleProvider.debug` / `AndroidProvider.debug` — печатают
///   debug-токен в логах; токен нужно зарегистрировать в Firebase Console →
///   App Check → app → Manage debug tokens. Без этого dev-сборка не
///   проходит attestation.
/// - Monitor mode на стороне Firebase Console — failure не валит UX. Через
///   неделю observation переключим на Enforce + functions getoff.
Future<void> _activateAppCheck() async {
  if (kIsWeb) return;
  // LOCAL OVERRIDE для free Apple ID (Personal Team) на iOS: AppAttest
  // provisioning не выдан Apple для Bundle ID на free-аккаунте →
  // FirebaseAppCheck.activate() возвращает невалидный токен, и следующие
  // Firestore-запросы маскируются как `[cloud_firestore/internal]`. Сервер
  // в Monitor mode → App Check токен не обязателен. Возвращаемся к этому
  // блоку после покупки paid Apple Developer Program:
  //   git checkout HEAD -- mobile/app/lib/app_bootstrap.dart
  return;
  // ignore: dead_code
  try {
    await FirebaseAppCheck.instance.activate(
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (e, st) {
    // Monitor mode tolerates this — мы пишем warn чтобы заметить регрессию
    // при следующем deploy, но прод не валится.
    logger.w('FirebaseAppCheck.activate failed.', error: e, stackTrace: st);
  }
}

