import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

export type GroupInviteDenied = { uid: string; reason: "none" | "not_contact" };

export type CheckGroupInvitesResponse = {
  ok: boolean;
  denied: GroupInviteDenied[];
};

/**
 * Проверяет, может ли текущий пользователь добавить указанных людей в группу
 * с учётом privacySettings.groupInvitePolicy и userContacts (только Admin SDK).
 */
export const checkGroupInvitesAllowed = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<{ targetUserIds: string[] }>): Promise<CheckGroupInvitesResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Требуется вход.");
    }

    const inviterUid = request.auth.uid;
    const raw = request.data?.targetUserIds;
    if (!Array.isArray(raw)) {
      throw new HttpsError("invalid-argument", "Нужен массив targetUserIds.");
    }

    const targetUserIds = [
      ...new Set(
        raw.filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    ];

    const denied: GroupInviteDenied[] = [];

    try {
      const inviterDoc = await db.collection("users").doc(inviterUid).get();
      const inviterIsAdmin = inviterDoc.data()?.role === "admin";

      if (inviterIsAdmin) {
        return { ok: true, denied: [] };
      }

      for (const targetId of targetUserIds) {
        if (targetId === inviterUid) continue;

        const userDoc = await db.collection("users").doc(targetId).get();
        if (!userDoc.exists) {
          continue;
        }

        const targetBlocked = userDoc.data()?.blockedUserIds;
        const targetBlockedList = Array.isArray(targetBlocked) ? (targetBlocked as string[]) : [];
        if (targetBlockedList.includes(inviterUid)) {
          denied.push({ uid: targetId, reason: "none" });
          continue;
        }

        const inviterBlocked = inviterDoc.data()?.blockedUserIds;
        const inviterBlockedList = Array.isArray(inviterBlocked) ? (inviterBlocked as string[]) : [];
        if (inviterBlockedList.includes(targetId)) {
          denied.push({ uid: targetId, reason: "none" });
          continue;
        }

        const policy = userDoc.data()?.privacySettings?.groupInvitePolicy as
          | string
          | undefined;

        if (policy === "none") {
          denied.push({ uid: targetId, reason: "none" });
          continue;
        }

        if (policy === "contacts") {
          const contactsSnap = await db.collection("userContacts").doc(targetId).get();
          const contactIds: unknown = contactsSnap.data()?.contactIds;
          const list = Array.isArray(contactIds) ? (contactIds as string[]) : [];
          if (!list.includes(inviterUid)) {
            denied.push({ uid: targetId, reason: "not_contact" });
          }
        }
      }

      return { ok: denied.length === 0, denied };
    } catch (e) {
      logger.error("checkGroupInvitesAllowed", e);
      throw new HttpsError("internal", "Не удалось проверить ограничения приглашений.");
    }
  },
);
