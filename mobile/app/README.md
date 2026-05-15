# lighchat_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Voice message transcription (Show text)

- **Client UI**: the button lives in `lib/features/chat/ui/message_voice_attachment.dart` and requests transcription on demand.
- **Engine**: transcription runs **on-device** via native speech recognition. iOS uses `SFSpeechRecognizer` (Apple Speech Framework); Android 13+ uses `SpeechRecognizer.createOnDeviceSpeechRecognizer`. No network, no API keys, no server. Works in E2EE chats since plaintext audio never leaves the device.
- **Implementation**: Dart wrapper `lib/features/chat/data/local_voice_transcriber.dart` + native bridges `ios/Runner/Speech/VoiceTranscriberBridge.swift` and `android/app/src/main/kotlin/com/lighchat/lighchat_mobile/VoiceTranscriberBridge.kt`. MethodChannel: `lighchat/voice_transcribe`. See `docs/arcitecture/05-integrations.md` for the full contract.

## Android build: `flutter_windowmanager` + AGP namespace

If `flutter build apk --release` fails with **"Namespace not specified"** for `:flutter_windowmanager`, this repo includes a **project-level Gradle workaround** in `android/build.gradle.kts` that sets the missing `namespace` for that plugin when using **Gradle 8 / AGP 8+**.

### iOS checklist (when transcription fails)

- Verify Firebase iOS app is configured (correct bundle id + `GoogleService-Info.plist` and `Firebase.initializeApp()` is called).
- Ensure the user is authenticated (callable requires auth).
