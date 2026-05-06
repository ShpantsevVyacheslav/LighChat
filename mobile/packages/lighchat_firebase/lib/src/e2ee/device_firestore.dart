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

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firebase_callable_http.dart';
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
    this.lastLoginAt,
    this.lastLoginCountry,
    this.lastLoginCity,
    this.lastLoginIp,
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
  final String? lastLoginAt;
  final String? lastLoginCountry;
  final String? lastLoginCity;
  final String? lastLoginIp;

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
      lastLoginAt: data['lastLoginAt'] as String?,
      lastLoginCountry: data['lastLoginCountry'] as String?,
      lastLoginCity: data['lastLoginCity'] as String?,
      lastLoginIp: data['lastLoginIp'] as String?,
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
    unawaited(_refreshDeviceLastLocation(identity.deviceId));
    return;
  }
  await ref.update(<String, Object?>{'lastSeenAt': nowIso});
  unawaited(_refreshDeviceLastLocation(identity.deviceId));
}

/// In-memory throttle: на холодном старте делаем максимум один вызов callable
/// `updateDeviceLastLocation` в [_locThrottle]. Серверный throttle 30 мин —
/// последний рубеж от абуза.
DateTime? _lastLocationCallAt;
const Duration _locThrottle = Duration(minutes: 30);

Future<void> _refreshDeviceLastLocation(String deviceId) async {
  final prev = _lastLocationCallAt;
  if (prev != null && DateTime.now().difference(prev) < _locThrottle) {
    return;
  }
  try {
    // iOS Release: `cloud_functions` плагин (FunctionsContext.context с тремя
    // параллельными `async let` в Swift Concurrency) воспроизводимо крашит
    // процесс в `_swift_task_dealloc_specific` (SIGABRT). Идём напрямую через
    // HTTPS, как уже сделано для qr-login / secret-chat / checkGroupInvites.
    if (Platform.isIOS) {
      await callFirebaseCallableHttp(
        name: 'updateDeviceLastLocation',
        region: 'us-central1',
        data: <String, dynamic>{'deviceId': deviceId},
        timeout: const Duration(seconds: 30),
      );
    } else {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('updateDeviceLastLocation');
      await fn.call<dynamic>(<String, dynamic>{'deviceId': deviceId});
    }
    _lastLocationCallAt = DateTime.now();
  } catch (_) {
    // best-effort, локация — украшение, не блокер
  }
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

