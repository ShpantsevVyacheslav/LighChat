import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * One-shot admin-only migration:
 *   move lastLogin{At,Ip,City,Country} from the world-readable
 *   `users/{uid}/e2eeDevices/{deviceId}` into the private
 *   `users/{uid}/devices/{deviceId}` (rule allows read only to the owner).
 *
 * Why: e2eeDevices is intentionally world-readable so any signed-in user can
 * fetch a peer's public keys and wrap chat-keys for them. Storing IP / city /
 * country there leaked every user's last-known location to every other user
 * (a real stalker primitive). New writes (confirmQrLogin /
 * updateDeviceLastLocation) already target `devices/`, but historical docs
 * still expose the data. This function copies + scrubs.
 *
 * Idempotent: running it twice is safe — already-scrubbed docs have nothing
 * to copy and the FieldValue.delete() is a no-op the second time.
 *
 * Pagination: `cursor` is the document path of the last doc processed. Pass
 * back what the previous call returned in `nextCursor`.
 */
const PAGE_SIZE = 200;

type Result = {
  scanned: number;
  migrated: number;
  scrubbed: number;
  nextCursor: string | null;
  done: boolean;
};

export const migrateDeviceLocationToPrivate = onCall(
  { region: "us-central1", timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<{ cursor?: string | null }>): Promise<Result> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    }
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "ADMIN_REQUIRED");
    }

    const cursor = typeof request.data?.cursor === "string" ? request.data.cursor : null;

    let q = db
      .collectionGroup("e2eeDevices")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (cursor) {
      // collectionGroup queries paginated by document path use a startAfter
      // with a DocumentReference, not a string. Resolve it.
      const cursorRef = db.doc(cursor);
      q = q.startAfter(await cursorRef.get());
    }

    const snap = await q.get();
    let scanned = 0;
    let migrated = 0;
    let scrubbed = 0;
    let lastDocPath: string | null = null;

    for (const doc of snap.docs) {
      scanned++;
      lastDocPath = doc.ref.path;
      const data = doc.data() ?? {};
      const country = typeof data.lastLoginCountry === "string" ? data.lastLoginCountry : "";
      const city = typeof data.lastLoginCity === "string" ? data.lastLoginCity : "";
      const ip = typeof data.lastLoginIp === "string" ? data.lastLoginIp : "";
      const at = typeof data.lastLoginAt === "string" ? data.lastLoginAt : "";

      if (!country && !city && !ip && !at) continue;

      const ownerUid = doc.ref.parent.parent?.id;
      const deviceId = doc.id;
      if (!ownerUid || !deviceId) continue;

      try {
        const targetRef = db.doc(`users/${ownerUid}/devices/${deviceId}`);
        await targetRef.set(
          {
            ...(at ? { lastLoginAt: at } : {}),
            ...(country ? { lastLoginCountry: country } : {}),
            ...(city ? { lastLoginCity: city } : {}),
            ...(ip ? { lastLoginIp: ip } : {}),
          },
          { merge: true }
        );
        migrated++;
      } catch (e) {
        logger.warn("[migrateDeviceLocation] copy failed", {
          ownerUid,
          deviceId,
          error: String(e),
        });
        continue;
      }

      try {
        await doc.ref.update({
          lastLoginAt: admin.firestore.FieldValue.delete(),
          lastLoginCountry: admin.firestore.FieldValue.delete(),
          lastLoginCity: admin.firestore.FieldValue.delete(),
          lastLoginIp: admin.firestore.FieldValue.delete(),
        });
        scrubbed++;
      } catch (e) {
        logger.warn("[migrateDeviceLocation] scrub failed", {
          ownerUid,
          deviceId,
          error: String(e),
        });
      }
    }

    return {
      scanned,
      migrated,
      scrubbed,
      nextCursor: snap.size === PAGE_SIZE ? lastDocPath : null,
      done: snap.size < PAGE_SIZE,
    };
  }
);
