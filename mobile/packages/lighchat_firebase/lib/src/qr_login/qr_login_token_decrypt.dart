/// SECURITY: mobile-side decrypt for the customToken delivered through QR
/// login. Mirrors functions/src/lib/qr-login-token-crypto.ts (server) and
/// src/lib/qr-login/decrypt.ts (web). Any change here MUST be matched in
/// both other places — they share an HKDF info string and AAD.
///
/// Construction: ECDH-P256 + HKDF-SHA256 + AES-256-GCM, with sessionId
/// fed in as both HKDF salt and GCM AAD so a leaked ciphertext is bound
/// to its specific session.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../e2ee/webcrypto_compat.dart';

const String _hkdfInfo = 'lighchat/qr-login/v1';
const String _algLabel = 'ecdh-p256-hkdf-aesgcm-v1';

class EncryptedQrCustomToken {
  const EncryptedQrCustomToken({
    required this.alg,
    required this.ephPubB64,
    required this.ivB64,
    required this.ctB64,
  });

  final String alg;
  final String ephPubB64;
  final String ivB64;
  final String ctB64;

  factory EncryptedQrCustomToken.fromJson(Map<Object?, Object?> json) {
    return EncryptedQrCustomToken(
      alg: (json['alg'] as String?) ?? '',
      ephPubB64: (json['ephPub'] as String?) ?? '',
      ivB64: (json['iv'] as String?) ?? '',
      ctB64: (json['ct'] as String?) ?? '',
    );
  }
}

class QrTokenDecryptError implements Exception {
  QrTokenDecryptError(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'QrTokenDecryptError($code${message == null ? '' : ': $message'})';
}

/// Decrypt the customToken using this device's static ECDH P-256 private key
/// (the same one published as `publicKeySpkiB64` in requestQrLogin —
/// `getOrCreateMobileDeviceIdentity()` on this device holds the matching
/// private side).
Future<String> decryptQrCustomToken({
  required EncryptedQrCustomToken cipher,
  required ECPrivateKey recipientPrivateKey,
  required String sessionId,
}) async {
  if (cipher.alg != _algLabel) {
    throw QrTokenDecryptError('BAD_ALG', cipher.alg);
  }
  if (cipher.ephPubB64.isEmpty || cipher.ivB64.isEmpty || cipher.ctB64.isEmpty) {
    throw QrTokenDecryptError('BAD_FIELDS');
  }
  if (sessionId.length < 16) {
    throw QrTokenDecryptError('BAD_SESSION');
  }

  final ephPubSpki = base64.decode(cipher.ephPubB64);
  final ephPub = await importSpkiP256(spki: Uint8List.fromList(ephPubSpki));

  final z = await ecdhP256DeriveBits32(
    privateKey: recipientPrivateKey,
    remotePublic: ephPub,
  );
  final salt = Uint8List.fromList(utf8.encode(sessionId));
  final wrapKey = await hkdfSha256(
    ikm: z,
    salt: salt,
    info: _hkdfInfo,
    lengthBytes: 32,
  );

  final iv = base64.decode(cipher.ivB64);
  final ct = base64.decode(cipher.ctB64);
  final aad = Uint8List.fromList(utf8.encode(sessionId));

  Uint8List plain;
  try {
    plain = await aesGcmDecryptV2(
      key: Uint8List.fromList(wrapKey),
      iv: Uint8List.fromList(iv),
      ciphertextPlusTag: Uint8List.fromList(ct),
      aad: aad,
    );
  } on InvalidCipherTextException {
    throw QrTokenDecryptError('AUTH_FAILURE');
  }
  return utf8.decode(plain);
}
