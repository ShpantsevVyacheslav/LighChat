import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Global controller for an in-app mini window during a call.
///
/// Implementation note: this is intentionally tiny and uses a ValueNotifier so
/// that it can be consumed from `MaterialApp.builder` without adding new deps.
class InAppCallMiniWindowController {
  InAppCallMiniWindowController._();

  static final ValueNotifier<InAppCallMiniWindowPayload?> notifier =
      ValueNotifier<InAppCallMiniWindowPayload?>(null);

  static bool get isVisible => notifier.value != null;

  static void show(InAppCallMiniWindowPayload payload) {
    notifier.value = payload;
  }

  static void hide() {
    notifier.value = null;
  }
}

class InAppCallMiniWindowPayload {
  InAppCallMiniWindowPayload({
    required this.remoteRenderer,
    required this.localRenderer,
    required this.onReturnToCall,
    required this.onHangUp,
    required this.title,
  });

  final RTCVideoRenderer remoteRenderer;
  final RTCVideoRenderer localRenderer;
  final VoidCallback onReturnToCall;
  final VoidCallback onHangUp;
  final String title;
}

