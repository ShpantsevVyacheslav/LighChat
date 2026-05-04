import { describe, expect, it } from 'vitest';

import {
  buildQrLoginPayload,
  parseQrLoginPayload,
  QR_LOGIN_PROTOCOL_VERSION,
  type QrLoginPayload,
} from '@/lib/qr-login/protocol';

function makePayload(overrides: Partial<QrLoginPayload> = {}): QrLoginPayload {
  return {
    v: QR_LOGIN_PROTOCOL_VERSION,
    sessionId: 'abc-session-id-1234567890',
    nonce: 'nonce-token-very-secret-zzz',
    ...overrides,
  };
}

describe('qr-login protocol', () => {
  describe('buildQrLoginPayload + parseQrLoginPayload (round-trip)', () => {
    it('encodes and decodes a valid payload', () => {
      const original = makePayload();
      const encoded = buildQrLoginPayload(original);
      const decoded = parseQrLoginPayload(encoded);
      expect(decoded).toEqual(original);
    });

    it('produces base64url (no +, /, = characters)', () => {
      const encoded = buildQrLoginPayload(makePayload());
      expect(encoded).not.toMatch(/[+/=]/);
    });

    it('keeps payload reasonably small (≤ 200 chars for typical sessionId/nonce)', () => {
      // Cloud Function returns ~32-char base64url for sessionId/nonce, the
      // QR rendered at ECC level M needs ≤ ~250 bytes for compact code.
      const encoded = buildQrLoginPayload(makePayload());
      expect(encoded.length).toBeLessThanOrEqual(200);
    });

    it('decodes payloads with sessionId/nonce containing url-safe chars', () => {
      const original = makePayload({
        sessionId: 'abcd-EFGH_1234',
        nonce: 'AAAA_BBBB-CCCC',
      });
      const decoded = parseQrLoginPayload(buildQrLoginPayload(original));
      expect(decoded).toEqual(original);
    });
  });

  describe('parseQrLoginPayload — invalid payloads', () => {
    it('returns null for an empty string', () => {
      expect(parseQrLoginPayload('')).toBeNull();
    });

    it('returns null for non-base64 garbage', () => {
      expect(parseQrLoginPayload('not_a_qr_!!!!')).toBeNull();
    });

    it('returns null for a different namespace (E2EE pairing v2-pairing-1)', () => {
      // v2-pairing-1 payloads have a different `v` field — the login parser
      // must reject them so the scanner UI can fall back to the pairing flow.
      const pairingJson = JSON.stringify({
        v: 'v2-pairing-1',
        uid: 'user-1',
        sessionId: 'sess-1',
        initiatorEphPub: 'AAAA',
      });
      const b64url = Buffer.from(pairingJson, 'utf8')
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
      expect(parseQrLoginPayload(b64url)).toBeNull();
    });

    it('returns null when sessionId is missing', () => {
      const json = JSON.stringify({
        v: QR_LOGIN_PROTOCOL_VERSION,
        nonce: 'abc',
      });
      const b64 = Buffer.from(json, 'utf8')
        .toString('base64')
        .replace(/=+$/, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      expect(parseQrLoginPayload(b64)).toBeNull();
    });

    it('returns null when nonce is missing', () => {
      const json = JSON.stringify({
        v: QR_LOGIN_PROTOCOL_VERSION,
        sessionId: 'abc',
      });
      const b64 = Buffer.from(json, 'utf8')
        .toString('base64')
        .replace(/=+$/, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      expect(parseQrLoginPayload(b64)).toBeNull();
    });

    it('returns null when sessionId/nonce are not strings', () => {
      const json = JSON.stringify({
        v: QR_LOGIN_PROTOCOL_VERSION,
        sessionId: 42,
        nonce: { a: 1 },
      });
      const b64 = Buffer.from(json, 'utf8')
        .toString('base64')
        .replace(/=+$/, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      expect(parseQrLoginPayload(b64)).toBeNull();
    });

    it('returns null for valid base64 of a non-JSON string', () => {
      const b64 = Buffer.from('plain text not json', 'utf8')
        .toString('base64')
        .replace(/=+$/, '');
      expect(parseQrLoginPayload(b64)).toBeNull();
    });
  });

  describe('protocol version', () => {
    it('exports the expected protocol version constant', () => {
      expect(QR_LOGIN_PROTOCOL_VERSION).toBe('lighchat-login-v1');
    });
  });
});
