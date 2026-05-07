# LighChat Privacy Policy

**Last updated:** 2026-05-07
**Applies to:** web/PWA, desktop (Electron), mobile (iOS, Android)
**Contact:** legal@lighchat.app

> ⚠️ DRAFT. Requires legal review prior to publication. Placeholders marked `[…]`.

## 1. General

This Policy describes which personal data are collected and processed by [LEGAL ENTITY NAME] (the "Operator") when you use the LighChat messenger (the "Service").

Operator details:
- Legal name: [LEGAL ENTITY NAME]
- Registered address: [ADDRESS]
- Tax ID / Registration: [TAX_ID]
- Email: legal@lighchat.app

By using the Service you confirm you have read and agree to this Policy. If you do not agree with any term — stop using the Service.

## 2. Legal bases for processing

The Operator processes personal data on the following bases:

- Russian Federal Law No. 152-FZ "On Personal Data" (for users in the Russian Federation).
- General Data Protection Regulation (Regulation (EU) 2016/679, GDPR), Art. 6(1)(b), (c), (f) — for users in the EEA.
- California Consumer Privacy Act (CCPA) — for California residents.

Specific bases per data category are listed in section 4.

## 3. Data we collect

### 3.1 Account data (profile)
- name, display name, username;
- email address;
- phone number (optional, for verification and contact discovery);
- date of birth (to verify the 16+ age threshold);
- avatar, bio;
- UI preferences (language, theme, notification and privacy settings).

### 3.2 Content and communications
- messages (text, media, files, reactions, voice);
- message metadata (sender, recipient, timestamp, delivery / read status);
- call and meeting information (duration, participants, technical quality metrics);
- starred messages, contacts, blacklist.

E2EE chats (when enabled): message content is encrypted on-device and is not accessible to the Operator in plaintext. Only ciphertext and transport metadata are stored server-side.

### 3.3 Technical data
- IP address, device type, model, OS and version, build identifier;
- push tokens (Firebase Cloud Messaging);
- error and crash reports (Crashlytics);
- diagnostic events (without user message content).

### 3.4 Meetings and guest sessions
- meeting ID, guest display name, join/leave timestamps;
- WebRTC technical data (TURN/STUN ICE candidates, quality metrics);
- guest session data is **automatically deleted within 24 hours** after the meeting ends (see section 7).

### 3.5 Verification and security data
- sign-in history with device information (Devices);
- E2EE keys (public device keys on the server; private keys remain on-device);
- QR-login and paired-device parameters.

### 3.6 Payment data (where applicable)
The Operator does not store payment instruments. Payments are processed by third-party payment providers.

## 4. Purposes and bases of processing

| Purpose | Categories | Basis |
|---------|------------|-------|
| Registration and authentication | Profile, phone/email | Contract (152-FZ Art. 6(1)(5); GDPR 6(1)(b)) |
| Providing the messenger | Content, metadata | Contract |
| Push notifications | FCM tokens, events | Contract; consent |
| Account security | Devices, IP, logs | Legitimate interest (GDPR 6(1)(f)) |
| Legal compliance | All applicable | Legal obligation (GDPR 6(1)(c)) |
| Analytics and product improvement | Aggregated technical data | Legitimate interest |

## 5. Sharing with third parties

The Operator shares data with the following processors and service providers:

- **Google LLC / Firebase** (Auth, Firestore, Cloud Functions, Cloud Storage, FCM, Crashlytics) — processing and storage of account data, messages and media; notification delivery. Stored in Google Cloud data centers (including regions outside the RF/EEA).
- **WebRTC TURN/STUN servers** — relay of media streams for calls and meetings when peer-to-peer is unavailable.
- **Apple Inc., Google LLC** — push delivery (APNs, FCM).
- **Payment providers** — for paid features (to be specified upon integration).

The Operator does not sell personal data to third parties.

## 6. Cross-border data transfers

Data may be transferred and processed outside the Russian Federation (in Google Cloud data centers). The Operator notifies you and obtains consent at registration in accordance with Art. 12 of 152-FZ.

For EEA users, transfers outside the EEA are based on Standard Contractual Clauses approved by the European Commission.

## 7. Retention periods

- Active account — for the duration of the contract.
- Deleted account — messages and media deleted within 30 days; security logs retained up to 12 months.
- Guest session data (no account) — **24 hours** after the meeting ends, then auto-deleted.
- Error and crash logs — up to 90 days.
- Financial records (if any) — 5 years (per Russian Federal Law No. 402-FZ).

## 8. Data subject rights

You have the right to:

- be informed about the processing of your data;
- obtain a machine-readable copy of your data (portability, GDPR Art. 20);
- request rectification of inaccurate data;
- request erasure (right to be forgotten);
- withdraw consent;
- restrict or object to processing;
- lodge a complaint with Roskomnadzor (RF) or your national EEA supervisory authority.

Send requests to legal@lighchat.app. Response within 30 days.

## 9. Cookies and similar technologies

The web version of LighChat uses cookies and similar technologies (localStorage, sessionStorage, IndexedDB). See the [Cookie Policy](/legal/cookie-policy).

## 10. Data security

- TLS 1.2+ for all network connections;
- E2EE for secret chats (Signal-like protocol, see `docs/arcitecture/07-e2ee-v2-protocol.md`);
- password hashing — bcrypt/Argon2 on Firebase Auth side;
- regular Firestore Security Rules and Cloud Functions audits.

In the event of a data breach, the Operator notifies affected users and supervisory authorities within statutory deadlines (72 hours per GDPR Art. 33).

## 11. Minors

The Service is not intended for individuals under 16. See the [Children Policy](/legal/children-policy).

## 12. Changes to this Policy

The Operator may update this Policy. Material changes are published with at least 14 days' notice prior to the effective date. Continued use after the effective date constitutes acceptance.

## 13. Contact

Inquiries and requests: **legal@lighchat.app**

DPO (for EEA users): [DPO_NAME], [DPO_EMAIL]
