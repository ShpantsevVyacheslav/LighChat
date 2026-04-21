/// Revoke устройства E2EE v2 на мобайле.
///
/// Паритет [src/lib/e2ee/v2/revoke-device.ts](../../../../../../src/lib/e2ee/v2/revoke-device.ts).
///
/// Алгоритм (см. RFC §8):
///  1. `revokeMobileDevice` — пометить `users/{uid}/e2eeDevices/{deviceId}.revoked = true`.
///  2. Для каждого `conversations` с `participantIds` содержащим текущего пользователя
///     и `e2eeEnabled = true`: пересоздать session-doc под новой эпохой, где
///     revoked deviceId отсутствует в wraps. Бампнуть `conversations/{cid}.e2eeKeyEpoch`.
///  3. Идемпотентность: если current epoch уже не содержит revoked deviceId в
///     wraps — skip.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_firestore.dart';
import 'device_identity.dart';
import 'session_firestore.dart';
import 'system_events.dart';
import 'telemetry.dart';

/// Прогресс по одному чату. UI использует это для ленты "N из M обновлено".
class RevokeProgressEntry {
  const RevokeProgressEntry({
    required this.conversationId,
    required this.stage,
    this.reason,
    this.newEpoch,
  });

  final String conversationId;

  /// `'rekeyed' | 'skipped' | 'failed'`.
  final String stage;
  final String? reason;
  final int? newEpoch;
}

/// Результат revoke-операции в целом. Не бросается исключениями — даже если
/// отдельные чаты не ре-key'нулись, общий процесс считается «частичным».
class RevokeResult {
  const RevokeResult({
    required this.rekeyed,
    required this.failed,
    required this.entries,
  });

  final int rekeyed;
  final int failed;
  final List<RevokeProgressEntry> entries;
}

typedef RevokeProgressCallback = void Function(
  RevokeProgressEntry entry,
  int done,
  int total,
);

/// Переименовывает устройство (label). Проверки совпадают с web-клиентом.
Future<void> renameMobileDevice({
  required FirebaseFirestore firestore,
  required String userId,
  required String deviceId,
  required String newLabel,
}) async {
  final trimmed = newLabel.trim();
  if (trimmed.isEmpty) {
    throw StateError('E2EE_DEVICE_LABEL_EMPTY');
  }
  if (trimmed.length > 120) {
    throw StateError('E2EE_DEVICE_LABEL_TOO_LONG');
  }
  await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeDevices')
      .doc(deviceId)
      .update(<String, Object?>{'label': trimmed});
}

/// Отзывает устройство и перегенерирует эпохи во всех зашифрованных чатах
/// пользователя. Никогда не бросает — агрегирует статусы в [RevokeResult].
Future<RevokeResult> revokeDeviceAndRekeyMobile({
  required FirebaseFirestore firestore,
  required String userId,
  required MobileDeviceIdentityV2 revokerIdentity,
  required String deviceIdToRevoke,
  RevokeProgressCallback? onProgress,
}) async {
  // Шаг 1 — метка revoked. Делает один Firestore update. Даже если дальше
  // клиент упадёт — устройство уже не попадёт в listActiveMobileDevices.
  await revokeMobileDevice(
    firestore: firestore,
    userId: userId,
    deviceId: deviceIdToRevoke,
    revokedByDeviceId: revokerIdentity.deviceId,
  );
  logE2eeEvent(
    E2eeTelemetryEventType.deviceRevoked,
    E2eeTelemetryPayload(userId: userId, deviceId: deviceIdToRevoke),
  );

  final convs = await firestore
      .collection('conversations')
      .where('participantIds', arrayContains: userId)
      .get();

  final targets = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (final d in convs.docs) {
    final data = d.data();
    if (data['e2eeEnabled'] == true) targets.add(d);
  }

  final entries = <RevokeProgressEntry>[];
  var rekeyed = 0;
  var failed = 0;

  for (var i = 0; i < targets.length; i += 1) {
    final d = targets[i];
    final data = d.data();
    final conversationId = d.id;
    final currentEpoch = (data['e2eeKeyEpoch'] as num?)?.toInt() ?? 0;
    final nextEpoch = currentEpoch + 1;
    final participants = (data['participantIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        <String>[];

    try {
      if (currentEpoch > 0) {
        final current = await fetchE2eeSessionAny(
          firestore: firestore,
          conversationId: conversationId,
          epoch: currentEpoch,
        );
        if (current != null && current.isV2) {
          final perUser = current.v2!.wraps[userId] ?? const {};
          if (!perUser.containsKey(deviceIdToRevoke)) {
            final entry = RevokeProgressEntry(
              conversationId: conversationId,
              stage: 'skipped',
              reason: 'already rekeyed',
            );
            entries.add(entry);
            onProgress?.call(entry, i + 1, targets.length);
            continue;
          }
        }
      }

      final bundles = await collectParticipantDevices(
        firestore: firestore,
        participantIds: participants,
      );
      // Защита от гонки: даже если bundles вернули revoked — принудительно
      // вычёркиваем.
      final cleanedBundles = <String, List<E2eeDeviceDoc>>{};
      for (final e in bundles.entries) {
        if (e.key == userId) {
          cleanedBundles[e.key] = e.value
              .where((d) => d.deviceId != deviceIdToRevoke)
              .toList(growable: false);
        } else {
          cleanedBundles[e.key] = e.value;
        }
      }

      await createE2eeSessionDocV2(
        firestore: firestore,
        conversationId: conversationId,
        epoch: nextEpoch,
        currentIdentity: revokerIdentity,
        currentUserId: userId,
        participantDevices: cleanedBundles,
      );
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .update(<String, Object?>{'e2eeKeyEpoch': nextEpoch});

      // Phase 8: timeline-маркер о ротации эпохи. Best-effort.
      try {
        await ChatSystemEventFactories.epochRotated(
          firestore: firestore,
          conversationId: conversationId,
          epoch: nextEpoch,
          actorUserId: userId,
        );
      } catch (_) {
        // UX-маркер не должен ломать revoke.
      }

      final entry = RevokeProgressEntry(
        conversationId: conversationId,
        stage: 'rekeyed',
        newEpoch: nextEpoch,
      );
      entries.add(entry);
      onProgress?.call(entry, i + 1, targets.length);
      rekeyed += 1;
      logE2eeEvent(
        E2eeTelemetryEventType.rotateSuccess,
        E2eeTelemetryPayload(
          userId: userId,
          conversationId: conversationId,
          metrics: {'epoch': nextEpoch},
        ),
      );
    } catch (e) {
      final entry = RevokeProgressEntry(
        conversationId: conversationId,
        stage: 'failed',
        reason: e.toString(),
      );
      entries.add(entry);
      onProgress?.call(entry, i + 1, targets.length);
      failed += 1;
      logE2eeEvent(
        E2eeTelemetryEventType.rotateFailure,
        E2eeTelemetryPayload(
          userId: userId,
          conversationId: conversationId,
          errorCode: normalizeErrorCode(e),
        ),
      );
    }
  }

  return RevokeResult(rekeyed: rekeyed, failed: failed, entries: entries);
}
