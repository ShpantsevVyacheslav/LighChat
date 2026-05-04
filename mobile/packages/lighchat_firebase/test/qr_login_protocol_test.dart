import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

/// Помощник: кодирует JSON в base64-url без паддинга — точно так же, как это
/// делает web (`buildQrLoginPayload` из `src/lib/qr-login/protocol.ts`) и
/// `_encodeLoginQrPayload` в [qr_login_screen.dart](../../../app/lib/features/auth/ui/qr_login_screen.dart).
String _encodeBase64Url(Map<String, Object?> json) {
  final raw = jsonEncode(json);
  final b64 = base64.encode(utf8.encode(raw));
  return b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

void main() {
  group('parseQrLoginPayload', () {
    test('decodes a valid lighchat-login-v1 payload', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 'sess-id-123',
        'nonce': 'nonce-token-abc',
      });
      final parsed = parseQrLoginPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, 'sess-id-123');
      expect(parsed.nonce, 'nonce-token-abc');
    });

    test('returns null for an empty string', () {
      expect(parseQrLoginPayload(''), isNull);
    });

    test('returns null for non-base64 garbage', () {
      expect(parseQrLoginPayload('not_a_qr_!!!!'), isNull);
    });

    test('returns null for E2EE pairing namespace (`v2-pairing-1`)', () {
      // Sanity: сканер старого устройства должен различать форматы и при
      // pairing-QR отдавать flow в существующий E2EE-pairing parser
      // (`parseQrPayload`).
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'v2-pairing-1',
        'uid': 'user-1',
        'sessionId': 'sess-1',
        'initiatorEphPub': 'AAAA',
      });
      expect(parseQrLoginPayload(encoded), isNull);
    });

    test('returns null when sessionId is missing', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'nonce': 'abc',
      });
      expect(parseQrLoginPayload(encoded), isNull);
    });

    test('returns null when nonce is missing', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 'abc',
      });
      expect(parseQrLoginPayload(encoded), isNull);
    });

    test('returns null when sessionId is not a string', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 42,
        'nonce': 'abc',
      });
      expect(parseQrLoginPayload(encoded), isNull);
    });

    test('returns null when nonce is not a string', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 'abc',
        'nonce': <String, Object?>{},
      });
      expect(parseQrLoginPayload(encoded), isNull);
    });

    test('returns null for valid base64url of non-JSON content', () {
      final b64 = base64
          .encode(utf8.encode('plain text not json'))
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');
      expect(parseQrLoginPayload(b64), isNull);
    });

    test('exposes the expected protocol version constant', () {
      expect(qrLoginProtocolVersion, 'lighchat-login-v1');
    });
  });

  group('cross-platform compatibility', () {
    test('decodes a payload encoded by the web `buildQrLoginPayload` shape', () {
      // Воспроизводим точное поведение
      // [`buildQrLoginPayload`](../../../../src/lib/qr-login/protocol.ts):
      // base64-url без паддинга. Если этот тест падает — мобильный сканер не
      // сможет разобрать QR, сгенерированный web-устройством.
      final webPayload = jsonEncode(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 'cross-platform-session',
        'nonce': 'cross-platform-nonce',
      });
      final webEncoded = base64
          .encode(utf8.encode(webPayload))
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll(RegExp(r'=+$'), '');

      final parsed = parseQrLoginPayload(webEncoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, 'cross-platform-session');
      expect(parsed.nonce, 'cross-platform-nonce');
    });
  });
}
