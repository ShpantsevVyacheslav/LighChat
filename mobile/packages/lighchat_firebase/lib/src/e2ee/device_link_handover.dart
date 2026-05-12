/// Гибридная передача доступа к зашифрованным чатам новому устройству при
/// QR-логине — mobile parity с web `src/lib/e2ee/v2/device-handover.ts`.
///
/// Алгоритм идентичен web:
///   1. Публикуем новое устройство в `e2eeDevices/{newDeviceId}` (от старого
///      устройства); merge с тем, что новое устройство потом обновит из
///      Keychain после signInWithCustomToken.
///   2. Для каждого E2EE-чата текущего пользователя:
///      a) re-wrap chat-key текущей эпохи под `publicKeySpki` нового устройства
///         (через unwrap → wrap нашими ECDH/HKDF/AES-GCM хелперами);
///      b) опционально создаём новую эпоху со wraps под все устройства
///         (включая новое) — forward secrecy + явная регистрация.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'device_firestore.dart';
import 'device_identity.dart';
import 'session_firestore.dart';
import 'system_events.dart';
import 'webcrypto_compat.dart';

/// [QR-PAIR fix] iOS Firestore SDK иногда возвращает `[cloud_firestore/internal]`
/// для batch-query `conversations.where(participantIds, arrayContains)`,
/// особенно когда у юзера много чатов + есть persistent cache.
///
/// Стратегия:
///  1. Первая попытка — default (через cache, server-fallback по умолчанию).
///  2. На `internal` → retry с `GetOptions(source: Source.server)` чтобы
///     пропустить локальный кэш (если он повреждён).
///  3. Третья попытка — снова server с задержкой 800ms (gRPC transient).
///  4. После 3-х неудач — выбрасываем оригинал.
///
/// Не вызываем `clearPersistence()` — это сносит ВСЕ snapshot listener'ы
/// в приложении (chat list, profile и т.д.), пользователь увидит пустоту
/// и долгий reconnect. Лучше fall back на server-only get.
Future<QuerySnapshot<Map<String, dynamic>>> _getConversationsWithRetry(
  Query<Map<String, dynamic>> query,
) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final source = attempt == 0 ? Source.serverAndCache : Source.server;
      debugPrint('[handover] conversations.get attempt=${attempt + 1} source=$source');
      return await query.get(GetOptions(source: source));
    } on FirebaseException catch (e, st) {
      debugPrint('[handover] conversations.get FAIL attempt=${attempt + 1} code=${e.code} plugin=${e.plugin} msg=${e.message}');
      if (e.code != 'internal' || attempt == 2) {
        debugPrint('[handover] conversations.get giving up\n$st');
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }
  // unreachable (loop либо возвращает, либо rethrows на attempt==2)
  throw StateError('conversations.get retry loop exhausted');
}

class DeviceHandoverProgress {
  const DeviceHandoverProgress({
    required this.conversationId,
    required this.stage,
    this.reason,
    this.newEpoch,
  });

  final String conversationId;

  /// `'rewrapped' | 'rotated' | 'skipped' | 'failed'`.
  final String stage;
  final String? reason;
  final int? newEpoch;
}

class DeviceHandoverResult {
  const DeviceHandoverResult({
    required this.rewrapped,
    required this.rotated,
    required this.failed,
    required this.entries,
  });

  final int rewrapped;
  final int rotated;
  final int failed;
  final List<DeviceHandoverProgress> entries;
}

class IncomingDeviceInfo {
  const IncomingDeviceInfo({
    required this.deviceId,
    required this.publicKeySpkiB64,
    required this.platform,
    required this.label,
  });

  final String deviceId;
  final String publicKeySpkiB64;

  /// `'web' | 'ios' | 'android'`.
  final String platform;
  final String label;
}

typedef DeviceHandoverProgressCallback = void Function(
  DeviceHandoverProgress entry,
  int done,
  int total,
);

Future<DeviceHandoverResult> handoverDeviceAccessMobile({
  required FirebaseFirestore firestore,
  required String userId,
  required MobileDeviceIdentityV2 donorIdentity,
  required IncomingDeviceInfo newDevice,
  bool rotateEpoch = true,
  DeviceHandoverProgressCallback? onProgress,
}) async {
  // 1) Опубликовать e2eeDevices/{newDeviceId}.
  await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .doc(newDevice.deviceId)
      .set(<String, Object?>{
    'deviceId': newDevice.deviceId,
    'publicKeySpki': newDevice.publicKeySpkiB64,
    'platform': newDevice.platform,
    'label': newDevice.label,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
    'keyBundleVersion': 1,
  }, SetOptions(merge: true));
  // Освежаем lastSeenAt на нашем устройстве.
  await publishMobileDevice(
    firestore: firestore,
    userId: userId,
    identity: donorIdentity,
  );

  final convs = await _getConversationsWithRetry(
    firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId),
  );
  final targets = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (final d in convs.docs) {
    final data = d.data();
    if (data['e2eeEnabled'] == true) targets.add(d);
  }

  final entries = <DeviceHandoverProgress>[];
  var rewrapped = 0;
  var rotated = 0;
  var failed = 0;

  for (var i = 0; i < targets.length; i += 1) {
    final d = targets[i];
    final conversationId = d.id;
    final data = d.data();
    final currentEpoch = (data['e2eeKeyEpoch'] as num?)?.toInt() ?? 0;
    final participants = (data['participantIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];

    try {
      var didRewrap = false;
      if (currentEpoch > 0) {
        final fetched = await fetchE2eeSessionAny(
          firestore: firestore,
          conversationId: conversationId,
          epoch: currentEpoch,
        );
        if (fetched != null && fetched.isV2) {
          final session = fetched.v2!;
          final myWraps = session.wraps[userId] ?? const {};
          if (myWraps.containsKey(newDevice.deviceId)) {
            // Идемпотентно — re-wrap уже сделан.
          } else {
            final donorWrap = myWraps[donorIdentity.deviceId];
            if (donorWrap != null) {
              final epochId = '$conversationId:${session.epoch}';
              final chatKeyRaw = await unwrapChatKeyForDeviceV2(
                wrap: donorWrap,
                recipientPrivateKey: donorIdentity.keyPair.privateKey,
                epochId: epochId,
                deviceId: donorIdentity.deviceId,
              );
              final spki = Uint8List.fromList(
                base64.decode(newDevice.publicKeySpkiB64),
              );
              final newWrap = await wrapChatKeyForDeviceV2(
                chatKey32: chatKeyRaw,
                recipientPublicSpki: spki,
                epochId: epochId,
                deviceId: newDevice.deviceId,
              );
              final updatedMyWraps = Map<String, WrapEntryBase64>.from(myWraps)
                ..[newDevice.deviceId] = newWrap;
              final updatedWraps =
                  Map<String, Map<String, WrapEntryBase64>>.from(session.wraps)
                    ..[userId] = updatedMyWraps;
              final patched = E2eeSessionDocV2Mobile(
                epoch: session.epoch,
                createdAt: session.createdAt,
                createdByUserId: session.createdByUserId,
                createdByDeviceId: session.createdByDeviceId,
                participantIds: session.participantIds,
                wraps: updatedWraps,
                wrapContext: session.wrapContext,
              );
              await firestore
                  .collection('conversations')
                  .doc(conversationId)
                  .collection('e2eeSessions')
                  .doc(session.epoch.toString())
                  .set(patched.toMap(), SetOptions(merge: true));
              didRewrap = true;
              rewrapped += 1;
              final progress = DeviceHandoverProgress(
                conversationId: conversationId,
                stage: 'rewrapped',
              );
              entries.add(progress);
              onProgress?.call(progress, i + 1, targets.length);
            }
          }
        }
      }

      if (rotateEpoch) {
        final bundles = await collectParticipantDevices(
          firestore: firestore,
          participantIds: participants,
        );
        final nextEpoch = currentEpoch + 1;
        await createE2eeSessionDocV2(
          firestore: firestore,
          conversationId: conversationId,
          epoch: nextEpoch,
          currentIdentity: donorIdentity,
          currentUserId: userId,
          participantDevices: bundles,
        );
        await firestore
            .collection('conversations')
            .doc(conversationId)
            .update(<String, Object?>{'e2eeKeyEpoch': nextEpoch});
        try {
          await ChatSystemEventFactories.epochRotated(
            firestore: firestore,
            conversationId: conversationId,
            epoch: nextEpoch,
            actorUserId: userId,
          );
        } catch (_) {
          // best-effort timeline marker
        }
        rotated += 1;
        final progress = DeviceHandoverProgress(
          conversationId: conversationId,
          stage: 'rotated',
          newEpoch: nextEpoch,
        );
        entries.add(progress);
        onProgress?.call(progress, i + 1, targets.length);
      } else if (!didRewrap) {
        final progress = DeviceHandoverProgress(
          conversationId: conversationId,
          stage: 'skipped',
          reason: 'no current wrap and rotateEpoch=false',
        );
        entries.add(progress);
        onProgress?.call(progress, i + 1, targets.length);
      }
    } catch (e) {
      failed += 1;
      final progress = DeviceHandoverProgress(
        conversationId: conversationId,
        stage: 'failed',
        reason: e.toString(),
      );
      entries.add(progress);
      onProgress?.call(progress, i + 1, targets.length);
    }
  }

  return DeviceHandoverResult(
    rewrapped: rewrapped,
    rotated: rotated,
    failed: failed,
    entries: entries,
  );
}
