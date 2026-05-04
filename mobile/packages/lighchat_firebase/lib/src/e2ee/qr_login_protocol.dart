/// QR-login (Telegram-style) — mobile parity с web `src/lib/qr-login/protocol.ts`.
///
/// Парсер только; HTTPS-callable вызовы реализуются в приложении напрямую через
/// `cloud_functions/cloud_functions.dart`.
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
