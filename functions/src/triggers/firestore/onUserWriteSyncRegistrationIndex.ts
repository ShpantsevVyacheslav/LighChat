import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  registrationEntriesForProfile,
  type RegistrationIndexField,
} from "../../lib/registrationIndexKeys";

const db = admin.firestore();

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
  },
);
