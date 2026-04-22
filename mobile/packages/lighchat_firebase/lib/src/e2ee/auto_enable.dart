/// Auto-enable E2EE for новых личных чатов (Phase 4).
///
/// Паритет `src/lib/e2ee/v2/enable-conversation-v2.ts::tryAutoEnableE2eeV2NewDirectChat`
/// на Dart. Делает ровно то же: при желании пользователя (или платформенном
/// дефолте) создаёт эпоху 1 + v2 session-doc + обновляет conversation-doc.
/// После Phase 10 cleanup v1 полностью удалён — единственный путь.
///
/// Не читает сам платформенные/пользовательские настройки — решает вызывающий
/// код (UI-слой), чтобы не дублировать политику в двух местах и сохранить
/// `lighchat_firebase` пакет независимым от Riverpod/хранилища настроек.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'device_firestore.dart';
import 'device_identity.dart';
import 'session_firestore.dart';
import 'system_events.dart';
import 'telemetry.dart';

/// Опции для вызывающего кода. Смысловые правила:
///  - Хотя бы одно из `userWants` / `platformWants` = true → пробуем включить.
///  - Только для 1:1 (`isGroup == false`) — группы обрабатываются вручную.
///  - Если у собеседника нет ни одного опубликованного ключа, бросается
///    [E2eeSessionException] с кодом `E2EE_NO_DEVICE` (см. session_firestore).
class AutoEnableE2eeOptions {
  const AutoEnableE2eeOptions({
    required this.userWants,
    required this.platformWants,
  });

  final bool userWants;
  final bool platformWants;

  bool get shouldTry => userWants || platformWants;
}

/// Проверяет, стоит ли включать E2EE, и делает это. Гарантирует идемпотентность:
/// если чат уже `e2eeEnabled && e2eeKeyEpoch > 0` — ничего не делает.
///
/// Возвращает `true`, если включил E2EE в этом вызове.
Future<bool> tryAutoEnableE2eeNewDirectChatMobile({
  required FirebaseFirestore firestore,
  required String conversationId,
  required String currentUserId,
  required MobileDeviceIdentityV2 identity,
  required AutoEnableE2eeOptions options,
}) async {
  if (!options.shouldTry) return false;
  final convRef = firestore.collection('conversations').doc(conversationId);
  final snap = await convRef.get();
  if (!snap.exists) return false;
  final data = snap.data();
  if (data == null) return false;
  if (data['isGroup'] == true) return false;
  // Уже включено и эпоха > 0 — не перегенерируем.
  final alreadyEnabled = data['e2eeEnabled'] == true;
  final rawEpoch = data['e2eeKeyEpoch'];
  final currentEpoch = rawEpoch is int
      ? rawEpoch
      : (rawEpoch is num ? rawEpoch.toInt() : 0);
  if (alreadyEnabled && currentEpoch > 0) return false;

  final participantIdsRaw = data['participantIds'];
  final participantIds = (participantIdsRaw is List
          ? participantIdsRaw
          : const <Object?>[])
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);
  if (participantIds.length < 2) return false;

  await ensureMobileDevicePublished(
    firestore: firestore,
    userId: currentUserId,
    identity: identity,
  );

  final Map<String, List<E2eeDeviceDoc>> participantDevices;
  try {
    participantDevices = await collectParticipantDevices(
      firestore: firestore,
      participantIds: participantIds,
    );
  } on E2eeSessionException {
    // У кого-то нет ключа — нельзя включить. Ретроим молча (паритет web
    // логики `console.warn`), а не фатально: пользователь увидит обычный
    // plaintext-чат и может включить шифрование позже вручную.
    rethrow;
  }

  final nextEpoch = currentEpoch + 1;
  await createE2eeSessionDocV2(
    firestore: firestore,
    conversationId: conversationId,
    epoch: nextEpoch,
    currentIdentity: identity,
    currentUserId: currentUserId,
    participantDevices: participantDevices,
  );

  await convRef.update(<String, Object?>{
    'e2eeEnabled': true,
    'e2eeKeyEpoch': nextEpoch,
    'e2eeEnabledAt': DateTime.now().toUtc().toIso8601String(),
  });

  // Phase 9: telemetry — успешное включение. Для новых DM всегда
  // `previousEpoch == 0`, поэтому пишем enable.success.
  logE2eeEvent(
    E2eeTelemetryEventType.enableSuccess,
    E2eeTelemetryPayload(
      userId: currentUserId,
      conversationId: conversationId,
      deviceId: identity.deviceId,
      metrics: {'epoch': nextEpoch},
    ),
  );

  // Phase 8: timeline-маркер о включении E2EE. Best-effort.
  try {
    await ChatSystemEventFactories.e2eeEnabled(
      firestore: firestore,
      conversationId: conversationId,
      epoch: nextEpoch,
      actorUserId: currentUserId,
    );
  } catch (_) {
    // Не ломаем включение шифрования из-за UX-маркера.
  }
  return true;
}
