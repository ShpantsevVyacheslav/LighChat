/// Lazy self-heal E2EE sessions на мобайле.
///
/// Зеркало `src/lib/e2ee/v2/heal-session.ts`, назначение — закрыть те же
/// регрессии:
///  1. Новое устройство появилось в `users/{uid}/e2eeDevices`, но текущая
///     session-doc (до ротации) не содержит для него wrap — ничего не
///     расшифровывается.
///  2. Session-doc с неподдерживаемым `protocolVersion` (legacy v1 или
///     неизвестной — мы такие просто переротируем в v2).
///  3. Участник чата не виден в session.wraps (например, добавили новое
///     устройство после создания эпохи).
///
/// Heal идемпотентный: параллельные вызовы в пределах одного процесса
/// дедуплицируются in-memory, а Firestore transaction защищает от двойной
/// ротации между разными клиентами.
///
/// Модуль не тянет Riverpod / UI слой — только `cloud_firestore` и наши
/// существующие e2ee-примитивы. Его можно вызывать из `MobileE2eeRuntime`
/// (mobile/app), из фоновых задач или из тестов.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_identity.dart';
import 'session_firestore.dart';
import 'system_events.dart';
import 'telemetry.dart';

/// Почему потребовался heal. Возвращается в `HealResult`, логируется в
/// телеметрии — удобно дебажить.
enum MobileHealReason {
  noSessionDoc,
  sessionUnsupported,
  myDeviceMissing,
  otherDeviceMissing,
}

class MobileHealResult {
  const MobileHealResult._({
    required this.healed,
    required this.newEpoch,
    this.reason,
  });

  factory MobileHealResult.noop() =>
      const MobileHealResult._(healed: false, newEpoch: 0);

  factory MobileHealResult.rotated({
    required MobileHealReason reason,
    required int newEpoch,
  }) =>
      MobileHealResult._(healed: true, newEpoch: newEpoch, reason: reason);

  final bool healed;
  final int newEpoch;
  final MobileHealReason? reason;
}

/// Диагностика без побочных эффектов. Если нет current epoch (ещё не включали
/// E2EE) — возвращает `noop`: это не heal-кейс, а enable-кейс.
Future<MobileHealResult> diagnoseMobileSessionCoverage({
  required FirebaseFirestore firestore,
  required String conversationId,
  required int currentEpoch,
  required List<String> participantIds,
  required String currentUserId,
  required MobileDeviceIdentityV2 identity,
}) async {
  if (currentEpoch < 1) return MobileHealResult.noop();

  final fetched = await fetchE2eeSessionAny(
    firestore: firestore,
    conversationId: conversationId,
    epoch: currentEpoch,
  );
  if (fetched == null) {
    return MobileHealResult.rotated(
      reason: MobileHealReason.noSessionDoc,
      newEpoch: currentEpoch + 1,
    );
  }
  if (!fetched.isV2) {
    // Session неподдерживаемого формата (legacy v1 / unknown). Ротируем в v2.
    return MobileHealResult.rotated(
      reason: MobileHealReason.sessionUnsupported,
      newEpoch: currentEpoch + 1,
    );
  }
  final session = fetched.v2!;
  final perUser = session.wraps[currentUserId] ?? const {};
  if (!perUser.containsKey(identity.deviceId)) {
    return MobileHealResult.rotated(
      reason: MobileHealReason.myDeviceMissing,
      newEpoch: currentEpoch + 1,
    );
  }
  try {
    final bundles = await collectParticipantDevices(
      firestore: firestore,
      participantIds: participantIds,
    );
    for (final entry in bundles.entries) {
      final wrapped = (session.wraps[entry.key] ?? const {}).keys.toSet();
      for (final dev in entry.value) {
        if (!wrapped.contains(dev.deviceId)) {
          return MobileHealResult.rotated(
            reason: MobileHealReason.otherDeviceMissing,
            newEpoch: currentEpoch + 1,
          );
        }
      }
    }
  } on E2eeSessionException {
    // Нет устройства у кого-то из участников — не heal-кейс.
    return MobileHealResult.noop();
  }
  return MobileHealResult.noop();
}

/// In-memory guard для конкурентных вызовов. Ключ — `$cid:$epoch`.
final Map<String, Future<MobileHealResult>> _inflightHeal =
    <String, Future<MobileHealResult>>{};

/// Главная точка входа: убеждается, что current epoch покрывает все активные
/// устройства участников. Если нет — ротирует эпоху.
///
/// Best-effort: ошибки не пробрасываются наружу, возвращается `noop`. Это
/// отличие от `createE2eeSessionDocV2`, которая должна кидать, но heal —
/// optimistic self-heal, а не операция, которую UI должен принудительно
/// завершить.
Future<MobileHealResult> healSessionForCurrentDevices({
  required FirebaseFirestore firestore,
  required String conversationId,
  required int currentEpoch,
  required List<String> participantIds,
  required String currentUserId,
  required MobileDeviceIdentityV2 identity,
}) async {
  final cacheKey = '$conversationId:$currentEpoch';
  final existing = _inflightHeal[cacheKey];
  if (existing != null) return existing;

  final future = () async {
    try {
      // Публикуем текущее устройство до ротации — если это новый девайс /
      // пост-восстановление, без этого новая эпоха снова не покроет нас.
      await ensureMobileDevicePublished(
        firestore: firestore,
        userId: currentUserId,
        identity: identity,
      );

      final diag = await diagnoseMobileSessionCoverage(
        firestore: firestore,
        conversationId: conversationId,
        currentEpoch: currentEpoch,
        participantIds: participantIds,
        currentUserId: currentUserId,
        identity: identity,
      );
      if (!diag.healed) return MobileHealResult.noop();

      // Транзакция: атомарно читаем текущий epoch и обновляем его. Если
      // другой клиент успел раньше — откатимся к `noop` (пусть вызывающий
      // перечитает актуальный epoch из conversation).
      final convRef =
          firestore.collection('conversations').doc(conversationId);
      int nextEpoch = currentEpoch + 1;
      var conflict = false;

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(convRef);
        if (!snap.exists) {
          throw const E2eeSessionException('E2EE_CONV_NOT_FOUND');
        }
        final raw = snap.data()?['e2eeKeyEpoch'];
        final latest =
            raw is int ? raw : (raw is num ? raw.toInt() : 0);
        if (latest > currentEpoch) {
          conflict = true;
          return;
        }
        nextEpoch = latest + 1;
        tx.update(convRef, <String, Object?>{
          'e2eeKeyEpoch': nextEpoch,
          'e2eeEnabled': true,
          'e2eeEnabledAt': DateTime.now().toUtc().toIso8601String(),
        });
      });

      if (conflict) return MobileHealResult.noop();

      final bundles = await collectParticipantDevices(
        firestore: firestore,
        participantIds: participantIds,
      );
      await createE2eeSessionDocV2(
        firestore: firestore,
        conversationId: conversationId,
        epoch: nextEpoch,
        currentIdentity: identity,
        currentUserId: currentUserId,
        participantDevices: bundles,
      );

      logE2eeEvent(
        E2eeTelemetryEventType.rotateSuccess,
        E2eeTelemetryPayload(
          userId: currentUserId,
          conversationId: conversationId,
          deviceId: identity.deviceId,
          metrics: {'epoch': nextEpoch},
        ),
      );
      try {
        await ChatSystemEventFactories.epochRotated(
          firestore: firestore,
          conversationId: conversationId,
          epoch: nextEpoch,
          actorUserId: currentUserId,
        );
      } catch (_) {
        // Timeline-маркер — не критично.
      }

      return MobileHealResult.rotated(
        reason: diag.reason ?? MobileHealReason.myDeviceMissing,
        newEpoch: nextEpoch,
      );
    } catch (e) {
      logE2eeEvent(
        E2eeTelemetryEventType.rotateFailure,
        E2eeTelemetryPayload(
          userId: currentUserId,
          conversationId: conversationId,
          deviceId: identity.deviceId,
          errorCode: e.toString(),
        ),
      );
      return MobileHealResult.noop();
    } finally {
      _inflightHeal.remove(cacheKey);
    }
  }();
  _inflightHeal[cacheKey] = future;
  return future;
}
