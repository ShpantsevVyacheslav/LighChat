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
- **Backend**: transcription is performed server-side via Firebase Cloud Functions callable `transcribeVoiceMessage` (`us-central1`).
- **API keys**: **do not** add any OpenAI (or other provider) key to the mobile app. The provider key is configured on the server as `OPENAI_API_KEY` (Cloud Functions env/secret).

### iOS checklist (when transcription fails)

- Verify Firebase iOS app is configured (correct bundle id + `GoogleService-Info.plist` and `Firebase.initializeApp()` is called).
- Ensure the user is authenticated (callable requires auth).
