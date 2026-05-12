# iOS Meeting PiP

`MeetingPipBridge.swift` adds a `MethodChannel("lighchat/meeting_pip")` plugin
that opens a real iOS Picture-in-Picture window for the active video conference
(separate from the existing video-player PiP on `lighchat/pip`).

## How to enable

1. Drag `MeetingPipBridge.swift` into the **Runner** Xcode target (Project
   Navigator → drop the file onto Runner; make sure "Target Membership" has
   Runner checked, **not** any extension targets).
2. In `Runner/AppDelegate.swift`, register the bridge inside
   `didInitializeImplicitFlutterEngine`:

   ```swift
   if #available(iOS 15.0, *) {
     LighChatMeetingPipBridge.shared.register(
       messenger: engineBridge.applicationRegistrar.messenger())
   }
   ```
3. In `Runner/Info.plist` confirm that `UIBackgroundModes` includes `voip` and
   `audio` (already required for WebRTC; double-check after merge).

4. Flip the Dart side: edit
   [`features/meetings/data/meeting_pip_controller.dart`](../../lib/features/meetings/data/meeting_pip_controller.dart)
   to use the new channel on iOS:

   ```dart
   : _channel = channel ?? MethodChannel(
       Platform.isIOS ? 'lighchat/meeting_pip' : 'lighchat/pip');
   ```
   and remove the hardcoded `Platform.isIOS → false` from `isSupported()`.

## What still needs wiring

The current bridge opens a PiP window backed by an `AVSampleBufferDisplayLayer`
and shows a dark grey placeholder. To display the **active speaker's live
video** there, push `CMSampleBuffer` frames into
`LighChatMeetingPipFrameSink.shared` from your WebRTC track receiver. This
requires a small native shim on top of `flutter_webrtc`'s
`RTCVideoRenderer` (subscribe to the WebRTC frame callback, convert
`RTCVideoFrame` → `CMSampleBuffer`, forward). That bridging is left as a
follow-up because it touches the flutter_webrtc plugin internals.

For audio-only / "phone-call-style" PiP behaviour the placeholder is enough —
the meeting keeps running, audio plays through the speaker, and the user can
return to the room from the PiP window.
