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
