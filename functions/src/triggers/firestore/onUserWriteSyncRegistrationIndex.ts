import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  registrationEntriesForProfile,
  type RegistrationIndexField,
} from "../../lib/registrationIndexKeys";

const db = admin.firestore();

function buildProfileQrLink(userId: string): string {
  return `https://lighchat.online/dashboard/contacts/${encodeURIComponent(userId)}`;
}

type IndexField = RegistrationIndexField;

async function deleteIndexIfOwned(
  docId: string,
  userId: string,
): Promise<void> {
  const ref = db.collection("registrationIndex").doc(docId);
  try {
    const snap = await ref.get();
    if (!snap.exists) return;
    if (snap.get("uid") !== userId) {
      logger.warn("registrationIndex: skip delete — другой uid", {
        docId,
        userId,
        owner: snap.get("uid"),
      });
      return;
    }
    await ref.delete();
  } catch (e) {
    logger.error("registrationIndex: delete failed", { docId, userId, e });
  }
}

async function upsertIndex(
  docId: string,
  userId: string,
  field: IndexField,
): Promise<void> {
  const ref = db.collection("registrationIndex").doc(docId);
  try {
    await db.runTransaction(async (t) => {
      const snap = await t.get(ref);
      if (snap.exists) {
        const existing = snap.get("uid") as string | undefined;
        if (existing && existing !== userId) {
          logger.error("registrationIndex: конфликт uid (дубликат поля у двух профилей)", {
            docId,
            field,
            existingUid: existing,
            newUid: userId,
          });
          return;
        }
      }
      t.set(ref, { uid: userId, field, updatedAt: new Date().toISOString() });
    });
  } catch (e) {
    logger.error("registrationIndex: upsert failed", { docId, userId, field, e });
  }
}

async function autoAttachMatchingOwnersByLookup({
  lookupId,
  userId,
}: {
  lookupId: string;
  userId: string;
}): Promise<void> {
  try {
    const snap = await db
      .collectionGroup("deviceLookup")
      .where("key", "==", lookupId)
      .get();
    if (snap.empty) return;

    const owners = new Set<string>();
    for (const d of snap.docs) {
      // Path: userContacts/{ownerId}/deviceLookup/{lookupId}
      const ownerRef = d.ref.parent.parent;
      const ownerId = ownerRef?.id ?? "";
      if (!ownerId || ownerId === userId) continue;
      owners.add(ownerId);
    }

    const nowIso = new Date().toISOString();
    for (const ownerId of owners) {
      await db.collection("userContacts").doc(ownerId).set(
        {
          contactIds: admin.firestore.FieldValue.arrayUnion(userId),
          lastDeviceSyncMatchAt: nowIso,
        },
        {merge: true},
      );
    }
  } catch (e) {
    logger.error("deviceLookup auto-attach failed", {lookupId, userId, e});
  }
}

/**
 * Поддерживает `registrationIndex/*` в соответствии с `users/{uid}` (телефон, email, логин).
 * Нужен для проверки уникальности до входа (правила не дают читать `users` без auth).
 */
export const onuserwritesyncregistrationindex = onDocumentWritten(
  { document: "users/{userId}", region: "us-central1" },
  async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before;
    const after = event.data?.after;

    let beforeList: ReturnType<typeof registrationEntriesForProfile> = [];
    if (before?.exists) {
      beforeList = registrationEntriesForProfile(before.data() ?? null);
    }
    let afterList: ReturnType<typeof registrationEntriesForProfile> = [];
    if (after?.exists) {
      afterList = registrationEntriesForProfile(after.data() ?? null);
    }

    const afterIds = new Set(afterList.map((e) => e.id));

    for (const e of beforeList) {
      if (!afterIds.has(e.id)) {
        await deleteIndexIfOwned(e.id, userId);
      }
    }

    for (const e of afterList) {
      await upsertIndex(e.id, userId, e.field);
    }

    for (const e of afterList) {
      if (e.field !== "phone" && e.field !== "email") continue;
      await autoAttachMatchingOwnersByLookup({
        lookupId: e.id,
        userId,
      });
    }

    if (after?.exists) {
      const afterData = after.data() ?? {};
      const currentQr =
        typeof afterData.profileQrLink === "string" ?
          afterData.profileQrLink.trim() :
          "";
      const desiredQr = buildProfileQrLink(userId);
      if (currentQr !== desiredQr) {
        try {
          await db.collection("users").doc(userId).set(
            { profileQrLink: desiredQr },
            { merge: true },
          );
        } catch (e) {
          logger.error("users.profileQrLink sync failed", { userId, e });
        }
      }
    }
  },
);
