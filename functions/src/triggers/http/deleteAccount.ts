import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";

type DeleteAccountResponse = {
  uid: string;
  deletedRegistrationIndexCount: number;
  deletedMeetingsCount: number;
  deletedDmConversationsCount: number;
  detachedFromGroupsCount: number;
  detachedFromMeetingsCount: number;
  removedIncomingBlocksCount: number;
  /** [audit CR-004] сколько Storage-префиксов реально содержали файлы и были вычищены. */
  cleanedStoragePrefixCount: number;
  /** Сколько FCM-токенов было записано у юзера до удаления (для аудита). */
  purgedFcmTokenCount: number;
};

/**
 * [audit CR-004] best-effort удаление всех файлов в Storage по префиксу.
 * `bucket.deleteFiles({ prefix, force: true })` идёт пагинацией; force:true
 * подавляет ошибки на отдельные blob'ы (лучше удалить максимум, чем упасть
 * на одной странице из тысяч). Возвращает true если префикс был не пуст.
 */
async function deleteStorageByPrefix(prefix: string): Promise<boolean> {
  try {
    const bucket = admin.storage().bucket();
    const [head] = await bucket.getFiles({ prefix, maxResults: 1 });
    if (head.length === 0) return false;
    await bucket.deleteFiles({ prefix, force: true });
    return true;
  } catch (e) {
    logger.warn("[deleteAccount] storage cleanup failed", { prefix, error: String(e) });
    return false;
  }
}

async function deleteRegistrationIndexForUid(uid: string): Promise<number> {
  const db = admin.firestore();
  let deleted = 0;
  for (;;) {
    const snap = await db
      .collection("registrationIndex")
      .where("uid", "==", uid)
      .limit(500)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
      deleted++;
    }
    await batch.commit();
  }
  return deleted;
}

async function deleteMeetingsHostedByUid(uid: string): Promise<{
  count: number;
  meetingIds: string[];
}> {
  const db = admin.firestore();
  const meetingIds: string[] = [];
  for (;;) {
    const snap = await db.collection("meetings").where("hostId", "==", uid).limit(25).get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      meetingIds.push(doc.id);
      await db.recursiveDelete(doc.ref);
    }
  }
  return { count: meetingIds.length, meetingIds };
}

/**
 * SECURITY/GDPR: removes the leaving user from every conversation they
 * participate in. Without this, after the users/{uid} doc is deleted:
 *   - Group chats keep the dead uid in participantIds: viewers still see
 *     "X is in this group", "X read this message", and rules continue to
 *     allow that uid (if their token leaks somehow) to read the chat.
 *   - DM chats become orphan documents owned by no one, and the surviving
 *     partner has a half-broken thread referencing a tombstone profile.
 *   - blockedUserIds on third parties keep referring to the deleted uid —
 *     not a leak, but stale state.
 *
 * Strategy: walk userChats.conversationIds, then for each:
 *   - DM (1:1, !isGroup): recursive-delete the whole conversation. The other
 *     party keeps no record of the chat — matches GDPR "right to be
 *     forgotten" expectation.
 *   - Group: remove uid from participantIds + adminIds, drop the
 *     conversations/{id}/members/{uid} index doc, drop secretAccess/{uid}.
 *     The chat itself remains for the other members.
 */
async function detachFromConversations(uid: string): Promise<{
  deletedDmConversationsCount: number;
  detachedFromGroupsCount: number;
  /** [audit CR-004] DM-id'шники для последующей чистки `chat-attachments/{id}/`. */
  deletedDmConversationIds: string[];
}> {
  const db = admin.firestore();
  const userChatsSnap = await db.doc(`userChats/${uid}`).get();
  const conversationIds: string[] = (() => {
    if (!userChatsSnap.exists) return [];
    const raw = userChatsSnap.data()?.conversationIds;
    return Array.isArray(raw) ? raw.filter((s) => typeof s === "string") : [];
  })();

  // Also pull secret-chat ids (kept in a separate index document to hide
  // their existence from non-owners).
  const userSecretChatsSnap = await db.doc(`userSecretChats/${uid}`).get();
  if (userSecretChatsSnap.exists) {
    const raw = userSecretChatsSnap.data()?.conversationIds;
    if (Array.isArray(raw)) {
      for (const s of raw) {
        if (typeof s === "string" && !conversationIds.includes(s)) conversationIds.push(s);
      }
    }
  }

  let deletedDmConversationsCount = 0;
  let detachedFromGroupsCount = 0;
  const deletedDmConversationIds: string[] = [];

  for (const convId of conversationIds) {
    if (typeof convId !== "string" || convId.length === 0) continue;
    const convRef = db.doc(`conversations/${convId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) continue;
    const conv = convSnap.data() ?? {};
    const isGroup = conv.isGroup === true;

    try {
      if (!isGroup) {
        // DM (or saved-messages with size 1): drop the whole document and its
        // subcollections (messages, members, e2eeSessions, secretAccess, ...)
        await db.recursiveDelete(convRef);
        deletedDmConversationsCount++;
        deletedDmConversationIds.push(convId);
      } else {
        // Group: surgically detach.
        await convRef.update({
          participantIds: admin.firestore.FieldValue.arrayRemove(uid),
          adminIds: admin.firestore.FieldValue.arrayRemove(uid),
        });
        // Best-effort cleanup of indexes/grants tied to this uid in the chat.
        await db.doc(`conversations/${convId}/members/${uid}`).delete().catch((_e) => {/* best-effort*/});
        await db.doc(`conversations/${convId}/secretAccess/${uid}`).delete().catch((_e) => {/* best-effort*/});
        detachedFromGroupsCount++;
      }
    } catch (e) {
      logger.warn("[deleteAccount] detach failed for conversation", {
        uid,
        convId,
        isGroup,
        error: String(e),
      });
    }
  }

  return { deletedDmConversationsCount, detachedFromGroupsCount, deletedDmConversationIds };
}

/** Remove uid from every blockedUserIds list and drop the mirror docs. */
async function removeIncomingBlocksAgainst(uid: string): Promise<number> {
  const db = admin.firestore();
  // collectionGroup query on outgoingBlocks where blockedUserId == uid finds
  // every "X blocked uid" mirror doc anywhere in the tree.
  let removed = 0;
  for (;;) {
    const snap = await db
      .collectionGroup("outgoingBlocks")
      .where("blockedUserId", "==", uid)
      .limit(500)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
      removed++;
      // Also pull uid from the parent's blockedUserIds list (best effort —
      // some parents may already be deleted).
      const blockerUid = doc.ref.parent.parent?.id;
      if (blockerUid) {
        const userRef = db.doc(`users/${blockerUid}`);
        batch.update(userRef, {
          blockedUserIds: admin.firestore.FieldValue.arrayRemove(uid),
        });
      }
    }
    try {
      await batch.commit();
    } catch (e) {
      logger.warn("[deleteAccount] removeIncomingBlocks batch failed", {
        uid,
        error: String(e),
      });
      // If the parent users/{uid} doc no longer exists, the update fails the
      // whole batch. Fall back to per-doc deletes without the array update.
      for (const doc of snap.docs) {
        try {
          await doc.ref.delete();
        } catch {
          /* ignore */
        }
      }
    }
  }
  return removed;
}

/** Drop our membership in every meeting we joined as a guest/participant. */
async function detachFromMeetings(uid: string): Promise<number> {
  const db = admin.firestore();
  let detached = 0;
  for (;;) {
    const snap = await db
      .collectionGroup("participants")
      .where("userId", "==", uid)
      .limit(500)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
      detached++;
    }
    await batch.commit();
  }
  return detached;
}

export const deleteAccount = onCall(
  // [audit CR-004] Storage cleanup для юзеров с большим объёмом медиа
  // занимает заметное время. Ставим 540s (HTTP-callable hard-limit Cloud
  // Functions v2). Если пользователь успел залить тысячи файлов и timeout
  // всё равно ловится — следующий повторный вызов / админ-cleanup доберёт.
  { region: "us-central1", enforceAppCheck: false, timeoutSeconds: 540 },
  async (request: CallableRequest<Record<string, never>>): Promise<DeleteAccountResponse> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    }

    const db = admin.firestore();

    try {
      // 1) Free up email/phone/username for re-registration.
      const deletedRegistrationIndexCount = await deleteRegistrationIndexForUid(uid);

      // 2) GDPR: detach from all chats BEFORE we delete users/{uid}, so
      //    other members don't end up with stale references to a phantom uid.
      const { deletedDmConversationsCount, detachedFromGroupsCount, deletedDmConversationIds } =
        await detachFromConversations(uid);

      // 3) Drop membership in meetings we joined (collectionGroup).
      const detachedFromMeetingsCount = await detachFromMeetings(uid);

      // 4) Remove "X blocked me" mirror documents and pull uid from blocker's
      //    blockedUserIds. Otherwise stale block-references survive forever.
      const removedIncomingBlocksCount = await removeIncomingBlocksAgainst(uid);

      // 5) Recursively delete meetings owned by us.
      const { count: deletedMeetingsCount, meetingIds: deletedMeetingIds } =
        await deleteMeetingsHostedByUid(uid);

      // 6) [audit CR-004] FCM bookkeeping: считаем сколько token-записей было,
      //    чтобы залогировать (для аудита GDPR-удаления). Сами токены
      //    очистятся вместе с users/{uid} рекурсивным delete ниже. Серверной
      //    инвалидации FCM-токена нет — только устройство может сделать
      //    `deleteToken()`. Когда мы пошлём push на orphan-токен после
      //    удаления, FCM сам ответит NotRegistered и наш отправитель
      //    почистит его в своих списках.
      let purgedFcmTokenCount = 0;
      try {
        const userSnap = await db.doc(`users/${uid}`).get();
        const tokens = userSnap.data()?.fcmTokens;
        if (Array.isArray(tokens)) purgedFcmTokenCount = tokens.length;
      } catch (e) {
        logger.warn("[deleteAccount] fcmTokens read failed", { uid, error: String(e) });
      }

      // 7) Recursively delete user-scoped documents.
      // users/{uid} contains many subcollections (devices, e2ee*, prefs,
      // notifications, stickers, secretChatLock, e2eeDevices, ...).
      await db.recursiveDelete(db.doc(`users/${uid}`));
      await db.recursiveDelete(db.doc(`userChats/${uid}`));
      await db.recursiveDelete(db.doc(`userSecretChats/${uid}`));
      await db.recursiveDelete(db.doc(`userContacts/${uid}`));
      await db.recursiveDelete(db.doc(`userCalls/${uid}`));
      await db.recursiveDelete(db.doc(`userMeetings/${uid}`));

      // 8) [audit CR-004] Cloud Storage cleanup. Без этого медиа-файлы юзера
      //    остаются в bucket'е навсегда — нарушение GDPR + бесконечный счёт
      //    за хранение. Префиксы:
      //      - avatars/{uid}/                      — основной аватар, превью
      //      - wallpapers/{uid}/                   — фоны чатов
      //      - users/{uid}/sticker-packs/          — собственные стикеры
      //      - users/{uid}/backgrounds/            — фоны для митингов
      //      - chat-attachments/{convId}/          — вложения в DM, удалённых выше
      //      - chat-attachments-enc/{convId}/      — E2EE-вложения, то же
      //      - meeting-attachments/{meetingId}/    — вложения митингов hosted by uid
      //
      //    `users/{uid}/` верхний префикс покрывает sticker-packs и backgrounds
      //    (а заодно ловит любые будущие подпапки, которые добавим под uid).
      let cleanedStoragePrefixCount = 0;
      const userOwnedPrefixes = [
        `avatars/${uid}/`,
        `wallpapers/${uid}/`,
        `users/${uid}/`,
      ];
      for (const prefix of userOwnedPrefixes) {
        if (await deleteStorageByPrefix(prefix)) cleanedStoragePrefixCount++;
      }
      for (const convId of deletedDmConversationIds) {
        if (await deleteStorageByPrefix(`chat-attachments/${convId}/`)) cleanedStoragePrefixCount++;
        if (await deleteStorageByPrefix(`chat-attachments-enc/${convId}/`)) cleanedStoragePrefixCount++;
      }
      for (const meetingId of deletedMeetingIds) {
        if (await deleteStorageByPrefix(`meeting-attachments/${meetingId}/`)) cleanedStoragePrefixCount++;
      }

      // 9) Finally delete Auth user (irreversible).
      await admin.auth().deleteUser(uid);

      logger.info("[deleteAccount] deleted", {
        uid,
        deletedRegistrationIndexCount,
        deletedMeetingsCount,
        deletedDmConversationsCount,
        detachedFromGroupsCount,
        detachedFromMeetingsCount,
        removedIncomingBlocksCount,
        cleanedStoragePrefixCount,
        purgedFcmTokenCount,
      });

      return {
        uid,
        deletedRegistrationIndexCount,
        deletedMeetingsCount,
        deletedDmConversationsCount,
        detachedFromGroupsCount,
        detachedFromMeetingsCount,
        removedIncomingBlocksCount,
        cleanedStoragePrefixCount,
        purgedFcmTokenCount,
      };
    } catch (e) {
      logger.error("[deleteAccount] failed", { uid, error: String(e) });
      throw new HttpsError("internal", "DELETE_ACCOUNT_FAILED", { uid });
    }
  }
);
