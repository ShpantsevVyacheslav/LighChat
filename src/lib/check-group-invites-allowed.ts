"use client";

import { getFunctions, httpsCallable } from "firebase/functions";
import type { FirebaseApp } from "firebase/app";

export type GroupInviteDeniedReason = "none" | "not_contact";

export interface CheckGroupInvitesResult {
  ok: boolean;
  denied: { uid: string; reason: GroupInviteDeniedReason }[];
}

/**
 * Серверная проверка privacySettings.groupInvitePolicy и userContacts целевых пользователей.
 * Администратор проекта пропускается без проверок.
 */
export async function checkGroupInvitesAllowed(
  firebaseApp: FirebaseApp,
  targetUserIds: string[]
): Promise<CheckGroupInvitesResult> {
  const fn = httpsCallable<{ targetUserIds: string[] }, CheckGroupInvitesResult>(
    getFunctions(firebaseApp, "us-central1"),
    "checkGroupInvitesAllowed"
  );
  const res = await fn({ targetUserIds });
  return res.data;
}
