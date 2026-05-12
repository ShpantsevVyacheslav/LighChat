/// QR pairing (device → device) для E2EE v2 — mobile.
///
/// Зеркалит `src/lib/e2ee/v2/pairing-qr.ts`. Совместимость с веб-клиентом
/// гарантируется одинаковым форматом `users/{uid}/e2eePairingSessions/{id}`,
/// одинаковым AAD (`lighchat/v2/pairing|{uid}|{sessionId}`) и одинаковой
/// сериализацией QR-payload.
///
/// Этот модуль реализует чистый **протокол**: эфемерный ECDH, шифрование
/// приватника, 6-значный код для сверки. Камера/QR-рендер живут на UI-слое
/// (`mobile/app/lib/features/settings/ui/devices_screen.dart` сможет
/// добавить сканирование через `mobile_scanner` позже, без изменений здесь).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pointycastle/export.dart';

import 'webcrypto_compat.dart';

/// Версия протокола pairing — дублируется внутрь QR payload, чтобы старые
/// клиенты могли отвергнуть неизвестный формат.
const String e2eePairingQrVersion = 'v2-pairing-1';

/// TTL сессии. Сервер / cleanup-CF чистит по этому же сроку.
const Duration e2eePairingTtl = Duration(minutes: 10);

/// Публичный payload, который кодируется в QR. Идентичен web-формату.
class PairingQrPayload {
  const PairingQrPayload({
    required this.uid,
    required this.sessionId,
    required this.initiatorEphPubSpkiB64,
  });

  final String uid;
  final String sessionId;
  final String initiatorEphPubSpkiB64;

  Map<String, Object?> toJson() => <String, Object?>{
        'v': e2eePairingQrVersion,
        'uid': uid,
        'sessionId': sessionId,
        'initiatorEphPub': initiatorEphPubSpkiB64,
      };

  static PairingQrPayload fromJson(Map<String, Object?> json) {
    final version = json['v'];
    if (version != e2eePairingQrVersion) {
      throw StateError('E2EE_PAIRING_INVALID_QR');
    }
    final uid = json['uid'];
    final sessionId = json['sessionId'];
    final initiatorEphPub = json['initiatorEphPub'];
    if (uid is! String || sessionId is! String || initiatorEphPub is! String) {
      throw StateError('E2EE_PAIRING_INVALID_QR');
    }
    return PairingQrPayload(
      uid: uid,
      sessionId: sessionId,
      initiatorEphPubSpkiB64: initiatorEphPub,
    );
  }
}

/// base64-url сериализация (compatible с web `buildQrPayload`).
String buildQrPayload(PairingQrPayload payload) {
  final json = jsonEncode(payload.toJson());
  final b64 = base64.encode(utf8.encode(json));
  return b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

/// Разбор строки со сканера. Throws `E2EE_PAIRING_INVALID_QR` на битом входе.
PairingQrPayload parseQrPayload(String raw) {
  final normalized = raw.replaceAll('-', '+').replaceAll('_', '/');
  final padLen = (4 - normalized.length % 4) % 4;
  final padded = normalized + '=' * padLen;
  try {
    final decoded = utf8.decode(base64.decode(padded));
    final obj = jsonDecode(decoded);
    if (obj is! Map) {
      throw StateError('E2EE_PAIRING_INVALID_QR');
    }
    return PairingQrPayload.fromJson(Map<String, Object?>.from(obj));
  } catch (_) {
    throw StateError('E2EE_PAIRING_INVALID_QR');
  }
}

String _randomSessionId() {
  final bytes = randomBytes(12);
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List _pairingAad(String userId, String sessionId) {
  return Uint8List.fromList(
    utf8.encode('lighchat/v2/pairing|$userId|$sessionId'),
  );
}

/// Короткий 6-значный код, сверяется глазами. HMAC(sharedKey, "pairing-code"),
/// первые 4 байта → mod 10^6 → 6 цифр. Тот же алгоритм, что в web.
Future<String> _shortPairingCode(Uint8List sharedKey) async {
  final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(sharedKey));
  final msg = Uint8List.fromList(utf8.encode('lighchat/v2/pairing-code'));
  hmac.update(msg, 0, msg.length);
  final tag = Uint8List(hmac.macSize);
  hmac.doFinal(tag, 0);
  final n = (tag[0] << 24 | tag[1] << 16 | tag[2] << 8 | tag[3]) & 0xFFFFFFFF;
  return (n % 1000000).toString().padLeft(6, '0');
}

/* -------------------------------------------------------------------------- */
/*                              INITIATOR (new device)                        */
/* -------------------------------------------------------------------------- */

/// Состояние, возвращаемое `initiateMobilePairingSession`. UI хранит его в
/// памяти до истечения TTL или ручной отмены.
class MobileInitiatorSession {
  MobileInitiatorSession({
    required this.sessionId,
    required this.payload,
    required this.encoded,
    required this.ephemeralKeyPair,
  });

  final String sessionId;
  final PairingQrPayload payload;
  final String encoded;
  final EcdhP256KeyPair ephemeralKeyPair;
}

/// Вызывается на новом устройстве. Создаёт документ сессии и возвращает
/// данные для отрисовки QR.
Future<MobileInitiatorSession> initiateMobilePairingSession({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  debugPrint('[QR-PAIR/init] step=1 generate ECDH P-256 keypair');
  final EcdhP256KeyPair eph;
  try {
    eph = await generateEcdhP256KeyPair();
  } catch (e, st) {
    debugPrint('[QR-PAIR/init] FAIL generateEcdhP256KeyPair: $e\n$st');
    rethrow;
  }
  debugPrint('[QR-PAIR/init] step=2 export SPKI public');
  final Uint8List pubSpki;
  try {
    pubSpki = await eph.exportSpkiPublic();
  } catch (e, st) {
    debugPrint('[QR-PAIR/init] FAIL exportSpkiPublic: $e\n$st');
    rethrow;
  }
  final pubB64 = base64.encode(pubSpki);
  final sessionId = _randomSessionId();
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final expiresIso = DateTime.now()
      .toUtc()
      .add(e2eePairingTtl)
      .toIso8601String();
  final path = 'users/$userId/e2eePairingSessions/$sessionId';
  debugPrint('[QR-PAIR/init] step=3 firestore.set path=$path pubB64.len=${pubB64.length}');
  try {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('e2eePairingSessions')
        .doc(sessionId)
        .set(<String, Object?>{
      'sessionId': sessionId,
      'createdAt': nowIso,
      'expiresAt': expiresIso,
      'state': 'awaiting_scan',
      'initiatorEphPubSpkiB64': pubB64,
    });
  } catch (e, st) {
    debugPrint('[QR-PAIR/init] FAIL firestore.set path=$path: $e\n$st');
    rethrow;
  }
  debugPrint('[QR-PAIR/init] step=4 firestore.set OK; building QR payload');
  final payload = PairingQrPayload(
    uid: userId,
    sessionId: sessionId,
    initiatorEphPubSpkiB64: pubB64,
  );
  return MobileInitiatorSession(
    sessionId: sessionId,
    payload: payload,
    encoded: buildQrPayload(payload),
    ephemeralKeyPair: eph,
  );
}

/// Подписка на Firestore-сессию. UI смотрит на смену `state` для перехода
/// к экрану сверки кода.
Stream<Map<String, Object?>?> watchMobilePairingSession({
  required FirebaseFirestore firestore,
  required String userId,
  required String sessionId,
}) {
  return firestore
      .collection('users')
      .doc(userId)
      .collection('e2eePairingSessions')
      .doc(sessionId)
      .snapshots()
      .map((snap) => snap.data());
}

class ConsumeDonorResult {
  const ConsumeDonorResult({required this.privateKeyPkcs8, required this.pairingCode});
  final Uint8List privateKeyPkcs8;
  final String pairingCode;
}

/// Вызывается на initiator после того, как donor записал `donorPayload`.
/// Разбирает документ и возвращает расшифрованный PKCS#8 приватник.
Future<ConsumeDonorResult> consumeDonorPayloadMobile({
  required FirebaseFirestore firestore,
  required String userId,
  required String sessionId,
  required EcdhP256KeyPair initiatorEphemeral,
  required Map<String, Object?> donorDocument,
}) async {
  debugPrint('[QR-PAIR/consume] step=1 parse donorPayload');
  final donor = donorDocument['donorPayload'];
  if (donor is! Map) {
    debugPrint('[QR-PAIR/consume] FAIL donorPayload is not Map: ${donor.runtimeType}');
    throw StateError('E2EE_PAIRING_DONOR_PAYLOAD_MISSING');
  }
  final donorMap = Map<String, Object?>.from(donor);
  debugPrint('[QR-PAIR/consume] step=2 ECDH derive shared key');
  late final Uint8List pt;
  try {
    final donorEphSpki = Uint8List.fromList(
      base64.decode(donorMap['donorEphPubSpkiB64'] as String),
    );
    final donorEph = await importSpkiP256(spki: donorEphSpki);
    final shared = await ecdhP256DeriveBits32(
      privateKey: initiatorEphemeral.privateKey,
      remotePublic: donorEph,
    );
    final iv = Uint8List.fromList(base64.decode(donorMap['ivB64'] as String));
    final ct = Uint8List.fromList(base64.decode(donorMap['ciphertextB64'] as String));
    final aad = _pairingAad(userId, sessionId);
    debugPrint('[QR-PAIR/consume] step=3 AES-GCM decrypt ct.len=${ct.length} iv.len=${iv.length}');
    try {
      pt = await aesGcmDecryptV2(
        key: shared,
        iv: iv,
        ciphertextPlusTag: ct,
        aad: aad,
      );
    } catch (e, st) {
      debugPrint('[QR-PAIR/consume] FAIL aesGcmDecryptV2: $e\n$st');
      throw StateError('E2EE_PAIRING_DECRYPT_FAILED');
    }
    final code = await _shortPairingCode(shared);
    debugPrint('[QR-PAIR/consume] step=4 firestore.set state=completed sessionId=$sessionId');
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('e2eePairingSessions')
          .doc(sessionId)
          .set(<String, Object?>{'state': 'completed'}, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[QR-PAIR/consume] FAIL firestore.set completed: $e\n$st');
      rethrow;
    }
    debugPrint('[QR-PAIR/consume] OK pairingCode=$code pt.len=${pt.length}');
    return ConsumeDonorResult(privateKeyPkcs8: pt, pairingCode: code);
  } catch (e, st) {
    debugPrint('[QR-PAIR/consume] outer FAIL: $e\n$st');
    rethrow;
  }
}

/* -------------------------------------------------------------------------- */
/*                                  DONOR                                     */
/* -------------------------------------------------------------------------- */

/// Мета-инфа нового устройства, которую donor-клиент встраивает в документ
/// (чтобы UI initiator'а мог отрисовать «подтверждаете добавление X?»).
class MobileDeviceDraft {
  const MobileDeviceDraft({
    required this.deviceId,
    required this.platform,
    required this.label,
    required this.publicKeySpkiB64,
  });

  final String deviceId;
  final String platform;
  final String label;
  final String publicKeySpkiB64;

  Map<String, Object?> toJson() => <String, Object?>{
        'deviceId': deviceId,
        'platform': platform,
        'label': label,
        'publicKeySpki': publicKeySpkiB64,
      };
}

/// Вызывается на donor-устройстве после сканирования QR нового устройства.
/// Генерирует эфемерный ключ, шифрует приватник, пишет `donorPayload`.
/// Возвращает 6-значный код, который надо показать для сверки.
Future<String> donorRespondToPairingMobile({
  required FirebaseFirestore firestore,
  required String userId,
  required String sessionId,
  required String initiatorEphPubSpkiB64,
  required Uint8List privateKeyPkcs8,
  required MobileDeviceDraft deviceDraft,
}) async {
  debugPrint('[QR-PAIR/donor] step=1 generate ECDH P-256 keypair');
  final donorEph = await generateEcdhP256KeyPair();
  debugPrint('[QR-PAIR/donor] step=2 export SPKI public + derive shared');
  final donorPubSpki = await donorEph.exportSpkiPublic();
  final initiatorSpki = Uint8List.fromList(
    base64.decode(initiatorEphPubSpkiB64),
  );
  final initiatorPub = await importSpkiP256(spki: initiatorSpki);
  final shared = await ecdhP256DeriveBits32(
    privateKey: donorEph.privateKey,
    remotePublic: initiatorPub,
  );
  final iv = randomBytes(12);
  final aad = _pairingAad(userId, sessionId);
  debugPrint('[QR-PAIR/donor] step=3 AES-GCM encrypt pkcs8.len=${privateKeyPkcs8.length}');
  final ct = await aesGcmEncryptV2(
    key: shared,
    iv: iv,
    plaintext: privateKeyPkcs8,
    aad: aad,
  );
  final path = 'users/$userId/e2eePairingSessions/$sessionId';
  debugPrint('[QR-PAIR/donor] step=4 firestore.set path=$path (awaiting_accept + donorPayload) ct.len=${ct.length}');
  try {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('e2eePairingSessions')
        .doc(sessionId)
        .set(<String, Object?>{
      'state': 'awaiting_accept',
      'donorPayload': <String, Object?>{
        'donorEphPubSpkiB64': base64.encode(donorPubSpki),
        'ivB64': base64.encode(iv),
        'ciphertextB64': base64.encode(ct),
        'deviceDraft': deviceDraft.toJson(),
      },
    }, SetOptions(merge: true));
  } catch (e, st) {
    debugPrint('[QR-PAIR/donor] FAIL firestore.set awaiting_accept path=$path: $e\n$st');
    rethrow;
  }
  debugPrint('[QR-PAIR/donor] OK firestore.set done');
  return _shortPairingCode(shared);
}

/// Ручная отмена сессии (пользователь нажал "Отмена" или код не совпал).
/// Помечаем `rejected` и пытаемся удалить — ошибки игнорируются
/// (идемпотентно).
Future<void> rejectMobilePairingSession({
  required FirebaseFirestore firestore,
  required String userId,
  required String sessionId,
}) async {
  final ref = firestore
      .collection('users')
      .doc(userId)
      .collection('e2eePairingSessions')
      .doc(sessionId);
  try {
    await ref.set(<String, Object?>{'state': 'rejected'}, SetOptions(merge: true));
  } catch (_) {
    // ignore — документа может не быть.
  }
  try {
    await ref.delete();
  } catch (_) {
    // idempotent.
  }
}
