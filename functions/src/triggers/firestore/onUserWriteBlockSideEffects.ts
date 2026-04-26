import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function buildDirectChatId(left: string, right: string): string {
  const ids = [left.trim(), right.trim()].sort();
  const part = (v: string) => `${v.length}:${v}`;
  return `dm_${part(ids[0])}_${part(ids[1])}`;
}

function blockedIdsList(data: admin.firestore.DocumentData | undefined): string[] {
  const raw = data?.blockedUserIds;
  if (!Array.isArray(raw)) return [];
  return [...new Set(raw.filter((x): x is string => typeof x === "string" && x.length > 0))];
}

/**
 * При добавлении uid в `users/{blockerId}.blockedUserIds`:
 * — у заблокированного убираем блокирующего из `userContacts` и из `userChats` (личный dm).
 * Разблокировка не восстанавливает контакты/чат автоматически.
 */
export const onuserwriteblocksideeffects = onDocumentUpdated(
  { document: "users/{userId}", region: "us-central1" },
  async (event) => {
    const blockerId = event.params.userId;
    const before = blockedIdsList(event.data?.before.data());
    const after = blockedIdsList(event.data?.after.data());
    const beforeSet = new Set(before);
    const added = after.filter((id) => !beforeSet.has(id));

    for (const blockedId of added) {
      if (blockedId === blockerId) continue;
      try {
        const dmId = buildDirectChatId(blockerId, blockedId);
        const contactsRef = db.collection("userContacts").doc(blockedId);
        await contactsRef.set(
          { contactIds: FieldValue.arrayRemove(blockerId) },
          { merge: true },
        );
        await contactsRef.update({
          [`contactProfiles.${blockerId}`]: FieldValue.delete(),
        }).catch(() => undefined);

        await db
          .collection("userChats")
          .doc(blockedId)
          .set({ conversationIds: FieldValue.arrayRemove(dmId) }, { merge: true });
      } catch (e) {
        logger.error("onUserWriteBlockSideEffects failed", { blockerId, blockedId, e });
      }
    }
  },
);
