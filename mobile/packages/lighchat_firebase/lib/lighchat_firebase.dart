export 'src/auth_repository.dart';
export 'src/auth_errors.dart';
export 'src/chat_repository.dart';
export 'src/firebase_ready.dart';
export 'src/registration/registration_models.dart';
export 'src/registration/registration_profile_complete.dart';
export 'src/registration/username_candidate.dart';
export 'src/registration/registration_service.dart';

// E2EE v2 — mobile layer.
// Явный публичный список: именно эти функции/классы нужны UI-слою.
// Остальное (webcrypto_compat внутренние ASN.1 хелперы) — package-private.
export 'src/e2ee/webcrypto_compat.dart'
    show
        aesKeyBitsV2,
        gcmIvBytes,
        gcmTagBitsV2,
        v2Protocol,
        v2WrapContext,
        buildAadV2,
        hkdfSha256,
        randomBytes,
        randomChatKeyRawV2,
        generateEcdhP256KeyPair,
        importSpkiP256,
        importPkcs8P256,
        wrapChatKeyForDeviceV2,
        unwrapChatKeyForDeviceV2,
        encryptMessageV2,
        decryptMessageV2,
        aesGcmEncryptV2,
        aesGcmDecryptV2,
        EcdhP256KeyPair,
        WrapEntryBase64,
        V2MessageAadContext,
        MessageCiphertext;
export 'src/e2ee/device_identity.dart';
export 'src/e2ee/device_firestore.dart';
export 'src/e2ee/session_firestore.dart';
export 'src/e2ee/auto_enable.dart';
export 'src/e2ee/revoke_device.dart';
// Phase 6 recovery paths.
export 'src/e2ee/password_backup.dart';
export 'src/e2ee/pairing_qr.dart';
// Phase 7 media encryption: per-file AES-GCM keys, chunked AEAD, symmetric wrap.
export 'src/e2ee/media_crypto.dart';
export 'src/e2ee/media_storage.dart';
// Phase 8 timeline markers.
export 'src/e2ee/system_events.dart';
// Phase 9 lightweight telemetry.
export 'src/e2ee/telemetry.dart';
// Post-launch fix: self-heal session при рассинхроне device-set ↔ wraps.
export 'src/e2ee/heal_session.dart';
