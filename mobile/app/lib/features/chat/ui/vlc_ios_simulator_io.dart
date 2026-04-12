import 'dart:io' show Platform;

/// true на iOS Simulator — VLC там часто даёт PlatformException(channel-error).
bool vlcIosSimulatorHost() {
  try {
    if (!Platform.isIOS) return false;
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_UDID');
  } catch (_) {
    return false;
  }
}
