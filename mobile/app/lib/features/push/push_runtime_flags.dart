import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Temporary safeguard for iOS debug builds on Personal Team accounts
/// where APNs/VoIP entitlements are unavailable.
const bool kDisableIosPushInDebug = true;

bool get iosPushRuntimeEnabled {
  if (kIsWeb) return false;
  if (!Platform.isIOS) return true;
  if (kDebugMode && kDisableIosPushInDebug) return false;
  return true;
}

/// Доступен ли нативный Firebase Messaging на текущей платформе.
/// На Windows и Linux нативного FCM SDK нет — используем [pushFallbackEnabled].
bool get nativePushAvailable {
  if (kIsWeb) return false; // web использует Service Worker отдельно
  return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
}

/// Должен ли запускаться `PushFallbackService` поверх Firestore listener'а.
/// Включается там, где нативного FCM нет (Windows/Linux).
bool get pushFallbackEnabled {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux;
}

/// Поддерживается ли пакет `flutter_callkit_incoming` (системный UI входящего
/// звонка). На macOS/Windows/Linux замещается кастомным borderless-окном.
bool get callKitSupported {
  if (kIsWeb) return false;
  return Platform.isIOS || Platform.isAndroid;
}
