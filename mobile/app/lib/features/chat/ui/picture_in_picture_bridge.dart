import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Minimal platform PiP bridge used by the chat video call screen.
///
/// Android: enters native Picture-in-Picture for the current Activity.
/// iOS: not used for chat calls (CallKit/AVPlayer PiP is separate).
class ChatPictureInPictureBridge {
  static const MethodChannel _channel = MethodChannel('lighchat/pip');

  static Future<bool> isSupported() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('isSupported');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enterAndroid({required int aspectW, required int aspectH}) async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('enter', <String, int>{
        'aspectW': aspectW,
        'aspectH': aspectH,
      });
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}

