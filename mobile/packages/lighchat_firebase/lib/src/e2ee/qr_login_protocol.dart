/// QR-login (Telegram-style) — mobile parity с web `src/lib/qr-login/protocol.ts`.
///
/// Содержит **протокол**: build/parse base64-url JSON payload в формате
/// `{v: 'lighchat-login-v1', sessionId, nonce}`. HTTPS-callable вызовы
/// реализуются в приложении напрямую через `cloud_functions` или через
/// `callFirebaseCallableHttp` (iOS).
library;

import 'dart:convert';

const String qrLoginProtocolVersion = 'lighchat-login-v1';

class QrLoginPayload {
  const QrLoginPayload({
    required this.sessionId,
    required this.nonce,
  });

  final String sessionId;
  final String nonce;
}

/// Сериализация payload в base64-url JSON без паддинга.
///
/// Идентична web-функции [`buildQrLoginPayload`](../../../../../../src/lib/qr-login/protocol.ts) —
/// QR, сгенерированный любым клиентом, должен парситься обоими. Тесты
/// проверяют это явно (`qr_login_protocol_test.dart`).
String buildQrLoginPayload({
  required String sessionId,
  required String nonce,
}) {
  final json = jsonEncode(<String, Object?>{
    'v': qrLoginProtocolVersion,
    'sessionId': sessionId,
    'nonce': nonce,
  });
  final b64 = base64.encode(utf8.encode(json));
  return b64
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');
}

/// Возвращает [QrLoginPayload] для login-QR или `null`, если payload — что-то
/// другое (например, E2EE pairing QR). Не бросает исключений: вызывающий
/// различает форматы простым null-check'ом.
QrLoginPayload? parseQrLoginPayload(String raw) {
  if (raw.isEmpty) return null;
  try {
    final normalized = raw.replaceAll('-', '+').replaceAll('_', '/');
    final padLen = (4 - normalized.length % 4) % 4;
    final padded = normalized + '=' * padLen;
    final decoded = utf8.decode(base64.decode(padded));
    final obj = jsonDecode(decoded);
    if (obj is! Map) return null;
    if (obj['v'] != qrLoginProtocolVersion) return null;
    final sessionId = obj['sessionId'];
    final nonce = obj['nonce'];
    if (sessionId is! String || nonce is! String) return null;
    return QrLoginPayload(sessionId: sessionId, nonce: nonce);
  } catch (_) {
    return null;
  }
}
