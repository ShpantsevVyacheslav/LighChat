import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";

type DeleteAccountResponse = {
  uid: string;
  deletedRegistrationIndexCount: number;
  deletedMeetingsCount: number;
};

async function deleteRegistrationIndexForUid(uid: string): Promise<number> {
  const db = admin.firestore();
  let deleted = 0;
  // There may be more than 500 docs; loop until empty.
  // Use `for (;;)` to satisfy eslint `no-constant-condition`.
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

async function deleteMeetingsHostedByUid(uid: string): Promise<number> {
  const db = admin.firestore();
  let deleted = 0;
  // Use `for (;;)` to satisfy eslint `no-constant-condition`.
  for (;;) {
    const snap = await db.collection("meetings").where("hostId", "==", uid).limit(25).get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      // Hosted meetings are owned by the user. Use recursive delete to remove subcollections.
      await db.recursiveDelete(doc.ref);
      deleted++;
    }
  }
  return deleted;
}

export const deleteAccount = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<Record<string, never>>): Promise<DeleteAccountResponse> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    }

    const db = admin.firestore();

    try {
      // 1) Remove registration uniqueness mappings so the same credentials can be re-registered.
      const deletedRegistrationIndexCount = await deleteRegistrationIndexForUid(uid);

      // 2) Delete hosted meetings (owned resources).
      const deletedMeetingsCount = await deleteMeetingsHostedByUid(uid);

      // 3) Delete user-scoped documents.
      // users/{uid} contains many subcollections (devices, e2ee*, prefs, notifications, stickers, etc.)
      await db.recursiveDelete(db.doc(`users/${uid}`));
      await db.recursiveDelete(db.doc(`userChats/${uid}`));
      await db.recursiveDelete(db.doc(`userContacts/${uid}`));
      await db.recursiveDelete(db.doc(`userCalls/${uid}`));
      await db.recursiveDelete(db.doc(`userMeetings/${uid}`));

      // 4) Finally delete Auth user (irreversible).
      await admin.auth().deleteUser(uid);

      logger.info("[deleteAccount] deleted", {
        uid,
        deletedRegistrationIndexCount,
        deletedMeetingsCount,
      });

      return { uid, deletedRegistrationIndexCount, deletedMeetingsCount };
    } catch (e) {
      logger.error("[deleteAccount] failed", { uid, error: String(e) });
      throw new HttpsError("internal", "DELETE_ACCOUNT_FAILED", { uid });
    }
  }
);

