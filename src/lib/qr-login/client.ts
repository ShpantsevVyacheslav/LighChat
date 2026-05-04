'use client';

/**
 * Web-клиент QR-login протокола (новое устройство).
 *
 * Шаги new-device flow:
 *  1. `getOrCreateDeviceIdentityV2()` — нужно, чтобы передать `ephemeralPubKeySpki`
 *     серверу. Этот же deviceId/keypair станет постоянным после успешного входа
 *     (новых ключей не генерируем — это и есть «собственный ключ нового устройства»).
 *  2. `httpsCallable('requestQrLogin')` → получаем `{ sessionId, nonce, expiresAt }`.
 *  3. Подписываемся на `qrLoginSessions/{sessionId}` через `onSnapshot`.
 *     При `state == 'approved'` — забираем `customToken`, делаем
 *     `signInWithCustomToken`, удаляем документ (best-effort).
 *  4. Перед TTL (≈55с) повторяем шаг 2 — обновляем QR.
 */

import {
  doc,
  onSnapshot,
  deleteDoc,
  type Firestore,
  type Unsubscribe,
} from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import type { FirebaseApp } from 'firebase/app';
import {
  buildQrLoginPayload,
  type QrLoginPayload,
  QR_LOGIN_PROTOCOL_VERSION,
} from './protocol';

export type RequestQrLoginResponse = {
  sessionId: string;
  nonce: string;
  expiresAt: string;
  ttlSec: number;
};

export type QrLoginSessionDoc = {
  sessionId: string;
  state: 'awaiting_scan' | 'approved' | 'rejected';
  expiresAt: string;
  scannerUid?: string;
  customToken?: string;
  approvedAt?: string;
  rejectedAt?: string;
  ephemeralPubKeySpki?: string;
};

/** Запрашивает у сервера новую QR-login сессию для текущего устройства. */
export async function requestQrLoginSession(params: {
  firebaseApp: FirebaseApp;
  ephemeralPubKeySpki: string;
  devicePlatform: 'web' | 'ios' | 'android';
  deviceLabel: string;
  deviceId: string;
}): Promise<RequestQrLoginResponse> {
  const functions = getFunctions(params.firebaseApp, 'us-central1');
  const fn = httpsCallable<
    {
      ephemeralPubKeySpki: string;
      devicePlatform: string;
      deviceLabel: string;
      deviceId: string;
    },
    RequestQrLoginResponse
  >(functions, 'requestQrLogin');
  const res = await fn({
    ephemeralPubKeySpki: params.ephemeralPubKeySpki,
    devicePlatform: params.devicePlatform,
    deviceLabel: params.deviceLabel,
    deviceId: params.deviceId,
  });
  if (
    !res.data ||
    typeof res.data.sessionId !== 'string' ||
    typeof res.data.nonce !== 'string'
  ) {
    throw new Error('QR_LOGIN_BAD_RESPONSE');
  }
  return res.data;
}

/** Конвертирует sessionId+nonce в готовую к рендеру base64url-строку для QR. */
export function buildLoginQrEncodedPayload(
  res: RequestQrLoginResponse
): string {
  const payload: QrLoginPayload = {
    v: QR_LOGIN_PROTOCOL_VERSION,
    sessionId: res.sessionId,
    nonce: res.nonce,
  };
  return buildQrLoginPayload(payload);
}

/**
 * Подписка на изменения сессии. UI получает обновления state и доступ к
 * customToken при approved.
 */
export function watchQrLoginSession(
  firestore: Firestore,
  sessionId: string,
  onUpdate: (data: QrLoginSessionDoc | null) => void
): Unsubscribe {
  return onSnapshot(doc(firestore, 'qrLoginSessions', sessionId), (snap) => {
    if (!snap.exists()) {
      onUpdate(null);
      return;
    }
    onUpdate(snap.data() as QrLoginSessionDoc);
  });
}

/** Удаление сессии после успешного использования customToken. Best-effort. */
export async function deleteQrLoginSession(
  firestore: Firestore,
  sessionId: string
): Promise<void> {
  try {
    await deleteDoc(doc(firestore, 'qrLoginSessions', sessionId));
  } catch {
    // Cleanup-функция доберётся до неё через 5 минут.
  }
}

/* -------------------------------------------------------------------------- */
/*                          Сторона старого устройства                         */
/* -------------------------------------------------------------------------- */

export type ConfirmQrLoginResponseApproved = {
  state: 'approved';
  uid: string;
  ephemeralPubKeySpki: string;
  devicePlatform: 'web' | 'ios' | 'android';
  deviceLabel: string;
  deviceId: string;
};

export type ConfirmQrLoginResponseRejected = {
  state: 'rejected';
};

export type ConfirmQrLoginResponse =
  | ConfirmQrLoginResponseApproved
  | ConfirmQrLoginResponseRejected;

/**
 * Вызывается на ЗАЛОГИНЕННОМ устройстве после сканирования QR. Сервер выдаст
 * customToken и поместит его в документ; новое устройство возьмёт его сам.
 */
export async function confirmQrLoginFromScanner(params: {
  firebaseApp: FirebaseApp;
  sessionId: string;
  nonce: string;
  allow: boolean;
}): Promise<ConfirmQrLoginResponse> {
  const functions = getFunctions(params.firebaseApp, 'us-central1');
  const fn = httpsCallable<
    { sessionId: string; nonce: string; allow: boolean },
    ConfirmQrLoginResponse
  >(functions, 'confirmQrLogin');
  const res = await fn({
    sessionId: params.sessionId,
    nonce: params.nonce,
    allow: params.allow,
  });
  if (!res.data || (res.data.state !== 'approved' && res.data.state !== 'rejected')) {
    throw new Error('QR_LOGIN_BAD_CONFIRM_RESPONSE');
  }
  return res.data;
}
