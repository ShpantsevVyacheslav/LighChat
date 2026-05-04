'use client';

/**
 * QR-login протокол. Отдельный namespace, не путать с E2EE-pairing
 * (`v: 'v2-pairing-1'`). Сканер должен различать оба формата по полю `v`.
 *
 * Что в QR:
 *  - `v`: 'lighchat-login-v1';
 *  - `sessionId`: Firestore doc id в `qrLoginSessions/{sessionId}`;
 *  - `nonce`: одноразовый секрет, сервер хранит SHA-256 от `sessionId|nonce`,
 *    подтверждение со старого устройства передаёт сырой nonce.
 *
 * Размер payload в base64url ≈ 110–130 байт — комфортно для QR ECC level M.
 */

import { fromBase64, toBase64 } from '@/lib/e2ee/b64';

export const QR_LOGIN_PROTOCOL_VERSION = 'lighchat-login-v1' as const;

export type QrLoginPayload = {
  v: typeof QR_LOGIN_PROTOCOL_VERSION;
  sessionId: string;
  nonce: string;
};

export function buildQrLoginPayload(payload: QrLoginPayload): string {
  return toBase64(new TextEncoder().encode(JSON.stringify(payload)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

export function parseQrLoginPayload(raw: string): QrLoginPayload | null {
  try {
    const normalized = raw.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
    const decoded = new TextDecoder().decode(fromBase64(padded));
    const parsed = JSON.parse(decoded) as Partial<QrLoginPayload>;
    if (
      parsed.v !== QR_LOGIN_PROTOCOL_VERSION ||
      typeof parsed.sessionId !== 'string' ||
      typeof parsed.nonce !== 'string'
    ) {
      return null;
    }
    return parsed as QrLoginPayload;
  } catch {
    return null;
  }
}
