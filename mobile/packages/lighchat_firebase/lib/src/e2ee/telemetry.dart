/// Phase 9 — лёгкая клиентская телеметрия для mobile E2EE v2.
///
/// Зеркало `src/lib/e2ee/v2/telemetry.ts`. Стратегия идентична: единая точка
/// лога через `debugPrint` с префиксом `[e2ee/v2]` + опциональный sink для
/// подключения Firebase Analytics/Sentry в будущем, без изменения вызовов.
///
/// Безопасность: логируем только безобидные идентификаторы (conversationId,
/// userId, deviceId, errorCode до 80 символов). НИКОГДА — plaintext или ключи.

library;

import 'package:flutter/foundation.dart';

enum E2eeTelemetryEventType {
  enableSuccess('e2ee.v2.enable.success'),
  enableFailure('e2ee.v2.enable.failure'),
  rotateSuccess('e2ee.v2.rotate.success'),
  rotateFailure('e2ee.v2.rotate.failure'),
  devicePublished('e2ee.v2.device.published'),
  deviceRevoked('e2ee.v2.device.revoked'),
  decryptFailure('e2ee.v2.decrypt.failure'),
  mediaEncryptFailure('e2ee.v2.media.encrypt.failure'),
  mediaDecryptFailure('e2ee.v2.media.decrypt.failure'),
  backupCreateSuccess('e2ee.v2.backup.create.success'),
  backupCreateFailure('e2ee.v2.backup.create.failure'),
  backupRestoreSuccess('e2ee.v2.backup.restore.success'),
  backupRestoreFailure('e2ee.v2.backup.restore.failure'),
  pairingInitiated('e2ee.v2.pairing.initiated'),
  pairingCompleted('e2ee.v2.pairing.completed'),
  pairingRejected('e2ee.v2.pairing.rejected');

  const E2eeTelemetryEventType(this.wire);
  final String wire;
}

class E2eeTelemetryPayload {
  const E2eeTelemetryPayload({
    this.userId,
    this.conversationId,
    this.deviceId,
    this.errorCode,
    this.metrics,
  });

  final String? userId;
  final String? conversationId;
  final String? deviceId;
  final String? errorCode;
  final Map<String, num>? metrics;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'userId': ?userId,
      'conversationId': ?conversationId,
      'deviceId': ?deviceId,
      'errorCode': ?errorCode,
      'metrics': ?metrics,
    };
  }
}

typedef E2eeTelemetrySink =
    void Function(E2eeTelemetryEventType type, E2eeTelemetryPayload payload);

E2eeTelemetrySink? _activeSink;

void setE2eeTelemetrySink(E2eeTelemetrySink? sink) {
  _activeSink = sink;
}

/// Никогда не бросает исключения — sink изолирован try/catch'ем, чтобы
/// сломанная аналитика не валила E2EE-поток.
void logE2eeEvent(
  E2eeTelemetryEventType type, [
  E2eeTelemetryPayload payload = const E2eeTelemetryPayload(),
]) {
  try {
    if (kDebugMode) {
      debugPrint('[e2ee/v2] ${type.wire} ${payload.toMap()}');
    }
    final sink = _activeSink;
    if (sink != null) sink(type, payload);
  } catch (_) {
    // Намеренно молча — telemetry не должна ломать крипто-поток.
  }
}

String normalizeErrorCode(Object err) {
  final s = err is Error ? err.toString() : err.toString();
  return s.length > 80 ? s.substring(0, 80) : s;
}
