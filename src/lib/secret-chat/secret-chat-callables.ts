import type { FirebaseApp } from 'firebase/app';
import { getFunctions, httpsCallable } from 'firebase/functions';

const SECRET_CHAT_REGION = 'us-central1';

export type SecretUnlockMethod = 'pin' | 'biometric';

export type UnlockSecretChatParams = {
  conversationId: string;
  pin: string;
  deviceId?: string;
  method?: SecretUnlockMethod;
};

export type UnlockSecretChatResult = {
  ok: true;
  expiresAt: string;
};

export type SecretVaultPinStatus = {
  hasPin: boolean;
};

function functionsFor(app: FirebaseApp) {
  return getFunctions(app, SECRET_CHAT_REGION);
}

export async function setSecretChatPin(app: FirebaseApp, pin: string): Promise<void> {
  const callable = httpsCallable<{ pin: string }, { ok: true; updatedAt: string }>(
    functionsFor(app),
    'setSecretChatPin'
  );
  await callable({ pin: pin.trim() });
}

export async function hasSecretVaultPin(app: FirebaseApp): Promise<SecretVaultPinStatus> {
  const callable = httpsCallable<Record<string, never>, SecretVaultPinStatus>(
    functionsFor(app),
    'hasSecretVaultPin'
  );
  const res = await callable({});
  return { hasPin: res.data?.hasPin === true };
}

export async function verifySecretVaultPin(app: FirebaseApp, pin: string): Promise<void> {
  const callable = httpsCallable<{ pin: string }, { ok: true }>(
    functionsFor(app),
    'verifySecretVaultPin'
  );
  await callable({ pin: pin.trim() });
}

export async function unlockSecretChat(
  app: FirebaseApp,
  params: UnlockSecretChatParams
): Promise<UnlockSecretChatResult> {
  const callable = httpsCallable<UnlockSecretChatParams, UnlockSecretChatResult>(
    functionsFor(app),
    'unlockSecretChat'
  );
  const res = await callable({
    conversationId: params.conversationId,
    pin: params.pin,
    method: params.method ?? 'pin',
    ...(params.deviceId ? { deviceId: params.deviceId } : {}),
  });
  return res.data;
}

export async function deleteSecretChat(app: FirebaseApp, conversationId: string): Promise<void> {
  const callable = httpsCallable<{ conversationId: string }, { ok: true }>(
    functionsFor(app),
    'deleteSecretChat'
  );
  await callable({ conversationId });
}

function normalizeCallableCode(error: unknown): string {
  const code =
    typeof error === 'object' && error && 'code' in error
      ? String((error as { code?: unknown }).code ?? '')
      : '';
  return code.replace(/^functions\//, '').trim().toLowerCase();
}

function normalizeCallableMessage(error: unknown): string {
  const message =
    typeof error === 'object' && error && 'message' in error
      ? String((error as { message?: unknown }).message ?? '')
      : '';
  return message.trim().toUpperCase();
}

export function isSecretPinNotSetError(error: unknown): boolean {
  const code = normalizeCallableCode(error);
  const msg = normalizeCallableMessage(error);
  return code === 'failed-precondition' || msg.includes('PIN_NOT_SET');
}

export function isSecretPinInvalidError(error: unknown): boolean {
  const code = normalizeCallableCode(error);
  const msg = normalizeCallableMessage(error);
  return code === 'permission-denied' || msg.includes('PIN_INVALID');
}

export function isSecretPinLockedError(error: unknown): boolean {
  const code = normalizeCallableCode(error);
  const msg = normalizeCallableMessage(error);
  return code === 'resource-exhausted' || msg.includes('PIN_LOCKED');
}
