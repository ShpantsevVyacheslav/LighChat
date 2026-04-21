/// Публикация / чтение / revoke документов `users/{uid}/e2eeDevices/{deviceId}`.
///
/// Отдельный файл (user rule #1): эту логику удобно менять независимо от
/// crypto-слоя. Любой вызов сюда — это сеть. `device_identity.dart` — pure
/// Dart, без Firestore.
///
/// Формат документа совпадает с TS `E2eeDeviceDocV2` (`src/lib/types.ts`):
///
/// ```
/// {
///   deviceId: string,
///   publicKeySpki: string,         // base64
///   platform: 'ios' | 'android' | 'web',
///   label: string,
///   createdAt: ISO-string,
///   lastSeenAt: ISO-string,
///   keyBundleVersion: 1,
///   revoked?: boolean,
///   revokedAt?: ISO-string,
///   revokedByDeviceId?: string,
/// }
/// ```
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_identity.dart';

/// Документ устройства в виде, в котором мы читаем его обратно. Поля опционны,
/// чтобы можно было безопасно парсить даже частично-заполненные записи (например,
/// после ручной правки администратором).
class E2eeDeviceDoc {
  E2eeDeviceDoc({
    required this.deviceId,
    required this.publicKeySpkiB64,
    required this.platform,
    required this.label,
    required this.createdAt,
    required this.lastSeenAt,
    this.keyBundleVersion = 1,
    this.revoked = false,
    this.revokedAt,
    this.revokedByDeviceId,
  });

  final String deviceId;
  final String publicKeySpkiB64;
  final String platform;
  final String label;
  final String createdAt;
  final String lastSeenAt;
  final int keyBundleVersion;
  final bool revoked;
  final String? revokedAt;
  final String? revokedByDeviceId;

  factory E2eeDeviceDoc.fromMap(String id, Map<String, dynamic> data) {
    return E2eeDeviceDoc(
      deviceId: (data['deviceId'] as String?) ?? id,
      publicKeySpkiB64: (data['publicKeySpki'] as String?) ?? '',
      platform: (data['platform'] as String?) ?? 'unknown',
      label: (data['label'] as String?) ?? id,
      createdAt: (data['createdAt'] as String?) ?? '',
      lastSeenAt: (data['lastSeenAt'] as String?) ?? '',
      keyBundleVersion: (data['keyBundleVersion'] as num?)?.toInt() ?? 1,
      revoked: data['revoked'] == true,
      revokedAt: data['revokedAt'] as String?,
      revokedByDeviceId: data['revokedByDeviceId'] as String?,
    );
  }

  Map<String, Object?> toInitialMap() => <String, Object?>{
        'deviceId': deviceId,
        'publicKeySpki': publicKeySpkiB64,
        'platform': platform,
        'label': label,
        'createdAt': createdAt,
        'lastSeenAt': lastSeenAt,
        'keyBundleVersion': keyBundleVersion,
      };
}

/// Определяет метку платформы в формате, совместимом с TS (`'ios'`, `'android'`).
String detectMobilePlatform() {
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

String _defaultLabel(String platform) {
  try {
    return '$platform/${Platform.operatingSystemVersion}';
  } catch (_) {
    return platform;
  }
}

/// Публикует (или обновляет `lastSeenAt`) документ устройства. Безопасно
/// вызывать при каждом старте приложения.
Future<void> publishMobileDevice({
  required FirebaseFirestore firestore,
  required String userId,
  required MobileDeviceIdentityV2 identity,
  String? label,
}) async {
  final platform = detectMobilePlatform();
  final ref = firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .doc(identity.deviceId);
  final snap = await ref.get();
  final nowIso = DateTime.now().toUtc().toIso8601String();
  if (!snap.exists) {
    final doc = E2eeDeviceDoc(
      deviceId: identity.deviceId,
      publicKeySpkiB64: identity.publicKeySpkiB64,
      platform: platform,
      label: label ?? _defaultLabel(platform),
      createdAt: nowIso,
      lastSeenAt: nowIso,
    );
    await ref.set(doc.toInitialMap());
    return;
  }
  await ref.update(<String, Object?>{'lastSeenAt': nowIso});
}

/// Читает все активные устройства пользователя (revoked исключены). Нужен
/// при создании новой эпохи — под каждое устройство получателя мы делаем
/// отдельную обёртку chat-key.
Future<List<E2eeDeviceDoc>> listActiveMobileDevices({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  final snap = await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .get();
  final out = <E2eeDeviceDoc>[];
  for (final d in snap.docs) {
    final doc = E2eeDeviceDoc.fromMap(d.id, d.data());
    if (doc.revoked) continue;
    if (doc.publicKeySpkiB64.isEmpty) continue;
    out.add(doc);
  }
  return out;
}

/// Возвращает все устройства (включая revoked) — для UI устройств.
Future<List<E2eeDeviceDoc>> listAllMobileDevices({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  final snap = await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .get();
  return snap.docs
      .map((d) => E2eeDeviceDoc.fromMap(d.id, d.data()))
      .toList(growable: false);
}

/// Помечает устройство как revoked. По rules пишет только владелец.
Future<void> revokeMobileDevice({
  required FirebaseFirestore firestore,
  required String userId,
  required String deviceId,
  required String revokedByDeviceId,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .doc(deviceId)
      .update(<String, Object?>{
    'revoked': true,
    'revokedAt': DateTime.now().toUtc().toIso8601String(),
    'revokedByDeviceId': revokedByDeviceId,
  });
}

/// Fallback-чтение legacy v1 ключа из `users/{uid}/e2ee/device`. Нужно нам
/// только когда собеседник ещё не опубликовал ни одного v2-устройства.
/// Возвращает `null`, если v1 ключа тоже нет.
Future<E2eeDeviceDoc?> readLegacyV1Device({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  final snap = await firestore
      .collection('users')
      .doc(userId)
      .collection('e2ee')
      .doc('device')
      .get();
  if (!snap.exists) return null;
  final data = snap.data();
  if (data == null) return null;
  final pub = data['publicKeySpki'];
  if (pub is! String || pub.isEmpty) return null;
  final updatedAt =
      (data['updatedAt'] as String?) ?? DateTime(1970).toUtc().toIso8601String();
  return E2eeDeviceDoc(
    deviceId: 'legacy-v1',
    publicKeySpkiB64: pub,
    platform: (data['platform'] as String?) ?? 'web',
    label: 'Legacy v1',
    createdAt: updatedAt,
    lastSeenAt: updatedAt,
  );
}
