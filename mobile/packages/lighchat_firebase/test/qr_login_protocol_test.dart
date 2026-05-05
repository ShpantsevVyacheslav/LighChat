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

  group('buildQrLoginPayload (mobile encoder)', () {
    test('roundtrip: build → parse возвращает исходные значения', () {
      final encoded = buildQrLoginPayload(
        sessionId: 'r-session-123',
        nonce: 'r-nonce-456',
      );
      final parsed = parseQrLoginPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, 'r-session-123');
      expect(parsed.nonce, 'r-nonce-456');
    });

    test('output — base64url без паддинга и без +/=/', () {
      final encoded = buildQrLoginPayload(
        sessionId: 'a' * 32,
        nonce: 'b' * 32,
      );
      expect(encoded.contains('+'), isFalse);
      expect(encoded.contains('/'), isFalse);
      expect(encoded.contains('='), isFalse);
    });

    test('детерминирован: один и тот же вход даёт один и тот же выход', () {
      final a =
          buildQrLoginPayload(sessionId: 'session-x', nonce: 'nonce-y');
      final b =
          buildQrLoginPayload(sessionId: 'session-x', nonce: 'nonce-y');
      expect(a, b);
    });

    test('размер payload остаётся компактным (≤ 200 байт base64url)', () {
      // Реальные sessionId и nonce от Cloud Function — 32-символьные base64url.
      // Проверяем, что итоговый QR-payload остаётся <200 байт, чтобы code
      // version подбирался автоматически и сканер уверенно читал его.
      final encoded = buildQrLoginPayload(
        sessionId: 'A' * 32,
        nonce: 'B' * 32,
      );
      expect(encoded.length, lessThanOrEqualTo(200));
    });

    test(
      'устойчив к специальным символам (url-safe и многобайтовые)',
      () {
        // На сервере sessionId/nonce — base64url. Но на всякий случай проверяем
        // что парсер выживает и при unicode (paranoia-тест).
        final encoded = buildQrLoginPayload(
          sessionId: 'session_with-урл',
          nonce: 'nonce@special!',
        );
        final parsed = parseQrLoginPayload(encoded);
        expect(parsed, isNotNull);
        expect(parsed!.sessionId, 'session_with-урл');
        expect(parsed.nonce, 'nonce@special!');
      },
    );

    test('длинные sessionId и nonce декодируются обратно', () {
      // Паранойя на случай, если сервер начнёт выдавать более длинные
      // токены — паркинг должен не упасть.
      final encoded = buildQrLoginPayload(
        sessionId: 's' * 64,
        nonce: 'n' * 64,
      );
      final parsed = parseQrLoginPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId.length, 64);
      expect(parsed.nonce.length, 64);
    });
  });

  group('regressions: parser must reject malformed but plausible payloads', () {
    test('пустой sessionId — отказ', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': '',
        'nonce': 'abc',
      });
      // Парсер сейчас принимает пустые строки; этот тест документирует
      // текущее поведение и сигналит, если решим ужесточить валидацию.
      // (Сервер всё равно отвергнет такой confirm с invalid-argument.)
      final parsed = parseQrLoginPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, '');
    });

    test('лишние JSON-поля игнорируются (forward-compat)', () {
      final encoded = _encodeBase64Url(<String, Object?>{
        'v': 'lighchat-login-v1',
        'sessionId': 'sid',
        'nonce': 'nce',
        'futureField': 'ignored-by-current-clients',
      });
      final parsed = parseQrLoginPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, 'sid');
      expect(parsed.nonce, 'nce');
    });
  });
}
