<h1 align="center">LighChat</h1>

<p align="center">
  <strong>Secure messenger with E2E encryption, QR multi-device login and HD video calls</strong>
</p>

<p align="center">
  Alternative to WhatsApp and Telegram for iOS, Android, Web (PWA), Windows, macOS and Linux.
</p>

<p align="center">
  <a href="https://github.com/ShpantsevVyacheslav/LighChat/stargazers">
    <img src="https://img.shields.io/github/stars/ShpantsevVyacheslav/LighChat?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/ShpantsevVyacheslav/LighChat/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/ShpantsevVyacheslav/LighChat" alt="License">
  </a>
  <a href="https://lighchat.online">
    <img src="https://img.shields.io/badge/website-lighchat.online-blue" alt="Website">
  </a>
  <img src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-brightgreen" alt="Platforms">
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#getting-started">Getting started</a> •
  <a href="#mobile-flutter">Mobile</a> •
  <a href="README.md">Русский</a>
</p>

---

**LighChat** is an open-source messenger with end-to-end encryption, multi-device sync via QR code, HD video calls and custom chat themes. A secure alternative to WhatsApp and Telegram for iOS, Android, Windows, macOS, Linux and web.

⭐ Star the project on GitHub if you find it useful — it helps others discover it.

## Features

- **Chats**: 1:1 and group chats, threads, reactions, forwarding, attachments (photos, videos, files, audio, video messages), rich text, folders, search
- **Video conferencing**: multi-user conferences via WebRTC, screen sharing, virtual backgrounds, polls, in-conference chat
- **1:1 calls**: audio and video calls between users
- **QR multi-device**: log in on a new device by scanning a QR code — no SMS, no chat history loss
- **Custom themes**: each chat can have its own theme — colors, background, fonts
- **PWA**: install as a mobile app from the browser
- **Desktop**: native app via Electron (Windows, macOS, Linux)
- **End-to-end encryption** for messages and calls
- **Cross-platform sync** between all your devices

## Stack

- **Mobile**: Flutter (Dart) — `mobile/app/`
- **Web / PWA**: Next.js 14 + Tailwind + shadcn/ui — `src/`
- **Desktop**: Electron — `electron/`
- **Backend**: Firebase (Firestore, Auth, Cloud Functions, Cloud Messaging, Storage, Crashlytics)
- **Calls**: WebRTC + iOS CallKit + Android ConnectionService

## Getting started

Requires [Node.js](https://nodejs.org/) v20+.

```bash
# 1. Install dependencies
npm install

# 2. Configure environment variables
# Create .env.local with Firebase keys

# 3. Run web version
npm run dev

# 4. Run desktop version (Electron)
npm run desktop
```

## Mobile (Flutter)

The Flutter client lives in `mobile/app/` (iOS/Android).

```bash
# Install Flutter (macOS)
brew install --cask flutter

# Get dependencies and run
cd mobile/app
flutter pub get
flutter run
```

## Documentation

- [README (Russian)](README.md) — primary documentation
- [docs/](docs/) — architecture, integrations, troubleshooting
- [docs/marketing/](docs/marketing/) — marketing strategy, ASO/SEO recommendations, 90-day plans

## License

See [LICENSE](LICENSE).

## Contributing

Issues and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) (TBD) and [SECURITY.md](SECURITY.md) (TBD).

---

<p align="center">
  Made with focus on privacy, control and cross-platform freedom.
</p>
