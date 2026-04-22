/// Phase 8 — mobile-хелпер для публикации system-маркеров E2EE в timeline.
///
/// Зеркало web-модуля `src/lib/e2ee/v2/system-events.ts`.
///
/// Что делает:
///  * Пишет system-message в `conversations/{cid}/messages/` с полем
///    `systemEvent: { type, data }` и `senderId = '__system__'`.
///  * Тело `text` пустое — клиент рендерит divider вместо bubble.
/// Почему не шифруется: divider обязан быть виден любому клиенту, даже без
/// ключа эпохи (например, свежедобавленному устройству).
/// Idempotency: каждый вызов — это addDoc, повторная доставка одного и того же
/// события создаст второй маркер. Продуцент должен звать этот хелпер только
/// после успешной записи основного E2EE-обновления.

library;

import 'package:cloud_firestore/cloud_firestore.dart';

const String kChatSystemSenderId = '__system__';

/// Коды типов — строковые литералы, 1:1 с web (`ChatSystemEventType`).
class ChatSystemEventTypes {
  static const String e2eeV2Enabled = 'e2ee.v2.enabled';
  static const String e2eeV2Disabled = 'e2ee.v2.disabled';
  static const String e2eeV2EpochRotated = 'e2ee.v2.epoch.rotated';
  static const String e2eeV2DeviceAdded = 'e2ee.v2.device.added';
  static const String e2eeV2DeviceRevoked = 'e2ee.v2.device.revoked';
  static const String e2eeV2FingerprintChanged = 'e2ee.v2.fingerprint.changed';
}

/// Публикует system-маркер в чат. Возвращает id нового документа.
Future<String> postChatSystemEventV2({
  required FirebaseFirestore firestore,
  required String conversationId,
  required String type,
  Map<String, Object?>? data,
}) async {
  final col = firestore.collection('conversations/$conversationId/messages');
  final ref = await col.add({
    'senderId': kChatSystemSenderId,
    'text': '',
    'attachments': <Object?>[],
    'createdAt': FieldValue.serverTimestamp(),
    'readAt': null,
    'systemEvent': {
      'type': type,
      'data': ?data,
    },
  });
  return ref.id;
}

/// Shortcut-фабрики — полные аналоги `chatSystemEvents` из web-модуля.
class ChatSystemEventFactories {
  static Future<String> e2eeEnabled({
    required FirebaseFirestore firestore,
    required String conversationId,
    required int epoch,
    String? actorUserId,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2Enabled,
      data: {
        'epoch': epoch,
        'actorUserId': ?actorUserId,
      },
    );
  }

  /// Divider «Сквозное шифрование отключено». Вызывать **после** успешного
  /// обновления `e2eeEnabled=false` в документе беседы.
  static Future<String> e2eeDisabled({
    required FirebaseFirestore firestore,
    required String conversationId,
    required int previousEpoch,
    String? actorUserId,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2Disabled,
      data: {
        'epoch': previousEpoch,
        'actorUserId': ?actorUserId,
      },
    );
  }

  static Future<String> epochRotated({
    required FirebaseFirestore firestore,
    required String conversationId,
    required int epoch,
    String? actorUserId,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2EpochRotated,
      data: {
        'epoch': epoch,
        'actorUserId': ?actorUserId,
      },
    );
  }

  static Future<String> deviceAdded({
    required FirebaseFirestore firestore,
    required String conversationId,
    required String deviceId,
    required String deviceLabel,
    String? actorUserId,
    String? actorName,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2DeviceAdded,
      data: {
        'deviceId': deviceId,
        'deviceLabel': deviceLabel,
        'actorUserId': ?actorUserId,
        'actorName': ?actorName,
      },
    );
  }

  static Future<String> deviceRevoked({
    required FirebaseFirestore firestore,
    required String conversationId,
    required String deviceId,
    required String deviceLabel,
    String? actorUserId,
    String? actorName,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2DeviceRevoked,
      data: {
        'deviceId': deviceId,
        'deviceLabel': deviceLabel,
        'actorUserId': ?actorUserId,
        'actorName': ?actorName,
      },
    );
  }

  static Future<String> fingerprintChanged({
    required FirebaseFirestore firestore,
    required String conversationId,
    required String nextFingerprint,
    String? previousFingerprint,
    String? actorUserId,
    String? actorName,
  }) {
    return postChatSystemEventV2(
      firestore: firestore,
      conversationId: conversationId,
      type: ChatSystemEventTypes.e2eeV2FingerprintChanged,
      data: {
        'nextFingerprint': nextFingerprint,
        'previousFingerprint': ?previousFingerprint,
        'actorUserId': ?actorUserId,
        'actorName': ?actorName,
      },
    );
  }
}
