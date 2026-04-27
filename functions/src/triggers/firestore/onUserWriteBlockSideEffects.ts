import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  blockedIdsList,
  reconcileOutgoingBlocksForUser,
} from "../../lib/sync-user-outgoing-blocks";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function buildDirectChatId(left: string, right: string): string {
  const ids = [left.trim(), right.trim()].sort();
  const part = (v: string) => `${v.length}:${v}`;
  return `dm_${part(ids[0])}_${part(ids[1])}`;
}

/**
 * При изменении `users/{blockerId}.blockedUserIds`:
 * — синхронизируем `users/{blockerId}/outgoingBlocks/*` (для правил Firestore `userBlocks`);
 * — при добавлении uid: у заблокированного убираем блокирующего из `userContacts` и из `userChats` (личный dm).
 * — при удалении uid (разблокировке): возвращаем dm в `userChats` у ранее заблокированного,
 *   чтобы чат снова появился (контакты при этом не восстанавливаем автоматически).
 */
export const onuserwriteblocksideeffects = onDocumentWritten(
  { document: "users/{userId}", region: "us-central1" },
  async (event) => {
    const data = event.data;
    if (!data) return;
    const blockerId = event.params.userId;
    const afterSnap = data.after;
    if (!afterSnap.exists) return;

    const before = blockedIdsList(data.before?.data());
    const after = blockedIdsList(afterSnap.data());
    const beforeKey = before.join("\u0001");
    const afterKey = after.join("\u0001");

    if (beforeKey !== afterKey) {
      try {
        await reconcileOutgoingBlocksForUser(blockerId, afterSnap.data());
      } catch (e) {
        logger.error("reconcileOutgoingBlocksForUser failed", { blockerId, e });
      }
    }

    const beforeSet = new Set(before);
    const added = after.filter((id) => !beforeSet.has(id));
    const afterSet = new Set(after);
    const removed = before.filter((id) => !afterSet.has(id));

    for (const blockedId of added) {
      if (blockedId === blockerId) continue;
      try {
        const dmId = buildDirectChatId(blockerId, blockedId);
        const contactsRef = db.collection("userContacts").doc(blockedId);
        await contactsRef.set(
          { contactIds: FieldValue.arrayRemove(blockerId) },
          { merge: true },
        );
        await contactsRef
          .update({
            [`contactProfiles.${blockerId}`]: FieldValue.delete(),
          })
          .catch(() => undefined);

        await db
          .collection("userChats")
          .doc(blockedId)
          .set({ conversationIds: FieldValue.arrayRemove(dmId) }, { merge: true });
      } catch (e) {
        logger.error("onUserWriteBlockSideEffects failed", { blockerId, blockedId, e });
      }
    }

    for (const unblockedId of removed) {
      if (unblockedId === blockerId) continue;
      try {
        const dmId = buildDirectChatId(blockerId, unblockedId);
        const dmSnap = await db.collection("conversations").doc(dmId).get();
        if (!dmSnap.exists) continue;
        await db
          .collection("userChats")
          .doc(unblockedId)
          .set({ conversationIds: FieldValue.arrayUnion(dmId) }, { merge: true });
      } catch (e) {
        logger.error("onUserWriteBlockSideEffects restore failed", {
          blockerId,
          unblockedId,
          e,
        });
      }
    }
  },
);
