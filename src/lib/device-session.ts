'use client';

import { doc, setDoc } from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';

const DEVICE_ID_STORAGE_KEY = 'lighchat_device_id_v1';

function makeDeviceId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  const r = Math.random().toString(36).slice(2);
  return `web_${Date.now().toString(36)}_${r}`;
}

export function getOrCreateWebDeviceId(): string {
  if (typeof window === 'undefined') return 'web_server';
  try {
    const existing = window.localStorage.getItem(DEVICE_ID_STORAGE_KEY);
    if (existing && existing.trim().length > 0) return existing;
    const created = makeDeviceId();
    window.localStorage.setItem(DEVICE_ID_STORAGE_KEY, created);
    return created;
  } catch {
    return makeDeviceId();
  }
}

function browserPlatformLabel(): string {
  if (typeof navigator === 'undefined') return 'web';
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ios')) return 'ios_web';
  if (ua.includes('android')) return 'android_web';
  if (ua.includes('mac os')) return 'mac_web';
  if (ua.includes('windows')) return 'windows_web';
  if (ua.includes('linux')) return 'linux_web';
  return 'web';
}

export async function writeDeviceSession({
  firestore,
  uid,
  active,
  markLogin = false,
}: {
  firestore: Firestore;
  uid: string;
  active: boolean;
  markLogin?: boolean;
}): Promise<void> {
  const deviceId = getOrCreateWebDeviceId();
  const now = new Date().toISOString();
  const ref = doc(firestore, 'users', uid, 'devices', deviceId);
  await setDoc(
    ref,
    {
      deviceId,
      platform: browserPlatformLabel(),
      app: 'web',
      isActive: active,
      lastSeenAt: now,
      ...(markLogin ? { lastLoginAt: now } : {}),
      updatedAt: now,
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
    },
    { merge: true }
  );
}
