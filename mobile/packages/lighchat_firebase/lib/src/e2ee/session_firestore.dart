/// Read / write `conversations/{cid}/e2eeSessions/{epoch}` для мобайла.
///
/// Зеркало `src/lib/e2ee/v2/session-firestore-v2.ts`. После Phase 10
/// cleanup legacy-v1 формат не поддерживается — любой не-v2
/// `protocolVersion` считаем unsupported и триггерим self-heal (ротация
/// эпохи в v2). Web и мобайл в этом поведении идентичны.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_firestore.dart';
import 'device_identity.dart';
import 'webcrypto_compat.dart';

const String e2eeV2Protocol = v2Protocol;
const String e2eeV2WrapContext = v2WrapContext;

/// Ошибки, которые UI слой должен распознавать специально. Текстовые коды
/// выбраны в соответствии с web-клиентом, чтобы error-таблица в
/// `07-e2ee-v2-protocol.md` была единой.
class E2eeSessionException implements Exception {
  const E2eeSessionException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'E2eeSessionException($code${message == null ? '' : ': $message'})';
}

/// Класс сессии «как пришло из Firestore» — удобно сериализовать в UI,
/// кэш, тесты.
class E2eeSessionDocV2Mobile {
  E2eeSessionDocV2Mobile({
    required this.epoch,
    required this.createdAt,
    required this.createdByUserId,
    required this.createdByDeviceId,
    required this.participantIds,
    required this.wraps,
    this.wrapContext = e2eeV2WrapContext,
  });

  final int epoch;
  final String createdAt;
  final String createdByUserId;
  final String createdByDeviceId;
  final List<String> participantIds;
  final Map<String, Map<String, WrapEntryBase64>> wraps;
  final String wrapContext;

  factory E2eeSessionDocV2Mobile.fromMap(Map<String, dynamic> data) {
    final participants = (data['participantIds'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final rawWraps = (data['wraps'] as Map?) ?? const <String, dynamic>{};
    final parsedWraps = <String, Map<String, WrapEntryBase64>>{};
    rawWraps.forEach((userId, devicesEntry) {
      if (userId is! String || devicesEntry is! Map) return;
      final inner = <String, WrapEntryBase64>{};
      devicesEntry.forEach((deviceId, wrapJson) {
        if (deviceId is! String || wrapJson is! Map) return;
        inner[deviceId] = WrapEntryBase64.fromJson(
          wrapJson.map((k, v) => MapEntry(k.toString(), v)),
        );
      });
      parsedWraps[userId] = inner;
    });
    return E2eeSessionDocV2Mobile(
      epoch: (data['epoch'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as String?) ?? '',
      createdByUserId: (data['createdByUserId'] as String?) ?? '',
      createdByDeviceId: (data['createdByDeviceId'] as String?) ?? '',
      participantIds: participants,
      wraps: parsedWraps,
      wrapContext: (data['wrapContext'] as String?) ?? e2eeV2WrapContext,
    );
  }

  Map<String, Object?> toMap() {
    final wrapsMap = <String, Map<String, Object?>>{};
    wraps.forEach((uid, devices) {
      wrapsMap[uid] = {
        for (final e in devices.entries) e.key: e.value.toJson(),
      };
    });
    return <String, Object?>{
      'protocolVersion': e2eeV2Protocol,
      'epoch': epoch,
      'createdAt': createdAt,
      'createdByUserId': createdByUserId,
      'createdByDeviceId': createdByDeviceId,
      'participantIds': participantIds,
      'wraps': wrapsMap,
      'wrapContext': wrapContext,
    };
  }
}

/// Результат `fetchSessionAny`: либо v2, либо sentinel «несовместимая версия».
class FetchedSession {
  FetchedSession._({this.v2, this.legacyVersion});

  final E2eeSessionDocV2Mobile? v2;
  final String? legacyVersion;

  bool get isV2 => v2 != null;
  bool get isUnsupported => legacyVersion != null;
}

Future<FetchedSession?> fetchE2eeSessionAny({
  required FirebaseFirestore firestore,
  required String conversationId,
  required int epoch,
}) async {
  final snap = await firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('e2eeSessions')
      .doc(epoch.toString())
      .get();
  if (!snap.exists) return null;
  final data = snap.data();
  if (data == null) return null;
  final proto = data['protocolVersion'];
  if (proto == e2eeV2Protocol) {
    return FetchedSession._(v2: E2eeSessionDocV2Mobile.fromMap(data));
  }
  return FetchedSession._(
    legacyVersion: proto is String ? proto : 'unknown',
  );
}

/// Разворачивает chat-key для текущего устройства. Если обёртки под
/// `identity.deviceId` нет — бросаем `E2EE_NO_WRAP_FOR_DEVICE`, UI
/// должен запустить self-heal (`healSessionForCurrentDevices`).
Future<Uint8List> unwrapChatKeyForMobile({
  required E2eeSessionDocV2Mobile session,
  required String userId,
  required MobileDeviceIdentityV2 identity,
  required String conversationId,
}) async {
  final perUser = session.wraps[userId];
  if (perUser == null || perUser.isEmpty) {
    throw const E2eeSessionException('E2EE_NO_WRAP_FOR_USER');
  }
  final epochId = '$conversationId:${session.epoch}';
  final myWrap = perUser[identity.deviceId];
  if (myWrap == null) {
    throw const E2eeSessionException(
      'E2EE_NO_WRAP_FOR_DEVICE',
      'Нет обёртки chat-key под текущее устройство. '
          'Запросите ротацию эпохи из веб-клиента или подтвердите устройство через QR.',
    );
  }
  return unwrapChatKeyForDeviceV2(
    wrap: myWrap,
    recipientPrivateKey: identity.keyPair.privateKey,
    epochId: epochId,
    deviceId: identity.deviceId,
  );
}

/// Публикует наш девайс перед тем, как мы собираемся создать новую эпоху
/// или просто запросить её. Идемпотентно.
Future<void> ensureMobileDevicePublished({
  required FirebaseFirestore firestore,
  required String userId,
  required MobileDeviceIdentityV2 identity,
}) async {
  await publishMobileDevice(
    firestore: firestore,
    userId: userId,
    identity: identity,
  );
}

/// Собирает список активных устройств каждого участника. Если у кого-то нет
/// v2-устройств, бросаем `E2EE_NO_DEVICE:{uid}` — UI должен попросить
/// собеседника залогиниться хотя бы раз, чтобы опубликовать ключ.
Future<Map<String, List<E2eeDeviceDoc>>> collectParticipantDevices({
  required FirebaseFirestore firestore,
  required List<String> participantIds,
}) async {
  final out = <String, List<E2eeDeviceDoc>>{};
  for (final uid in participantIds) {
    final devices = await listActiveMobileDevices(
      firestore: firestore,
      userId: uid,
    );
    if (devices.isEmpty) {
      throw E2eeSessionException('E2EE_NO_DEVICE', uid);
    }
    out[uid] = devices;
  }
  return out;
}

/// Создаёт новый v2 session-doc, обёртывая свежий chat-key под все устройства
/// каждого участника. Использовать при: enable E2EE, add member, remove member,
/// revoke, периодическом re-key.
Future<void> createE2eeSessionDocV2({
  required FirebaseFirestore firestore,
  required String conversationId,
  required int epoch,
  required MobileDeviceIdentityV2 currentIdentity,
  required String currentUserId,
  required Map<String, List<E2eeDeviceDoc>> participantDevices,
}) async {
  final chatKeyRaw = randomChatKeyRawV2();
  final wraps = <String, Map<String, WrapEntryBase64>>{};
  final epochId = '$conversationId:$epoch';

  for (final entry in participantDevices.entries) {
    final perDevice = <String, WrapEntryBase64>{};
    for (final dev in entry.value) {
      final spki = Uint8List.fromList(base64.decode(dev.publicKeySpkiB64));
      final wrap = await wrapChatKeyForDeviceV2(
        chatKey32: chatKeyRaw,
        recipientPublicSpki: spki,
        epochId: epochId,
        deviceId: dev.deviceId,
      );
      perDevice[dev.deviceId] = wrap;
    }
    wraps[entry.key] = perDevice;
  }

  final session = E2eeSessionDocV2Mobile(
    epoch: epoch,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    createdByUserId: currentUserId,
    createdByDeviceId: currentIdentity.deviceId,
    participantIds: participantDevices.keys.toList(growable: false),
    wraps: wraps,
  );

  await firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('e2eeSessions')
      .doc(epoch.toString())
      .set(session.toMap());
}
