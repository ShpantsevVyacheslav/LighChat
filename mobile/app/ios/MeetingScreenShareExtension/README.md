# iOS Screen Share (ReplayKit Broadcast Extension)

This folder contains the **source** for an iOS Broadcast Upload Extension that captures
the user's screen via ReplayKit and forwards frames to the Runner app so that
`flutter_webrtc` can publish them into the active meeting.

The files here are **not yet wired into the Xcode project**. To enable iOS screen sharing:

## 1. Add an Xcode target

Open `Runner.xcworkspace`:

1. **File → New → Target...**
2. Choose **Broadcast Upload Extension** (iOS, App).
3. Product name: `MeetingScreenShareExtension`.
4. Team: same as `Runner` (so App Group can be shared).
5. Bundle Identifier: e.g. `com.lighchat.app.MeetingScreenShareExtension` (replace
   `com.lighchat.app` with whatever `PRODUCT_BUNDLE_IDENTIFIER` you use for Runner).
6. Language: **Swift**. Embed in Application: **Runner**.
7. After Xcode generates files, **replace** the generated
   `SampleHandler.swift` and `Info.plist` with the ones in this folder.

## 2. App Group

The extension and the main app share a CFNotification + UserDefaults via App Group.

1. Select **Runner** target → **Signing & Capabilities** → **+ Capability** →
   **App Groups** → add `group.com.lighchat.app`.
2. Repeat for **MeetingScreenShareExtension** target.

The provided `MeetingScreenShareExtension.entitlements` file already lists the group;
point your target's `CODE_SIGN_ENTITLEMENTS` build setting at it.

## 3. Frame receiver in Runner

The receiver is added in `ios/MeetingPip/MeetingScreenShareReceiver.swift` and
registered in `AppDelegate.swift` on the `lighchat/meeting_screen_share` MethodChannel.

It listens for the Darwin notification `com.lighchat.app.screen_share.frame`,
reads the latest `CVPixelBuffer` payload from the App Group's UserDefaults,
and forwards it to `flutter_webrtc`'s `RTCVideoCapturer` (TODO: bridge).

## 4. Flutter side

After enabling, flip `_screenShareSupported` in
[`features/meetings/ui/meeting_room_screen.dart`](../../lib/features/meetings/ui/meeting_room_screen.dart)
to include `Platform.isIOS`, and update `meeting_webrtc.dart` to invoke
the `RPSystemBroadcastPickerView` via a `UiKitView` or `MethodChannel`
helper.

The full wiring (frame → `RTCVideoSource` → outgoing track) requires deeper
flutter_webrtc integration and is intentionally left as a follow-up PR — the
scaffolding here is everything that's safe to add without modifying the Xcode
project.
