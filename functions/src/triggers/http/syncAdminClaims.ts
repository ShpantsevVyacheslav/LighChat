import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { ensureAdminClaim, assertCallerIsAdmin } from "../../lib/admin-claims";

/**
 * One-shot admin-only migration: walk every users/{uid} doc, and for each one
 * call ensureAdminClaim(uid, role === 'admin'). After this completes, every
 * admin has the Firebase Auth Custom Claim `admin: true`, every non-admin
 * has it absent. assertCallerIsAdmin / assertAdminByIdToken can then drop
 * the Firestore fallback path.
 *
 * Idempotent: ensureAdminClaim is a no-op when the desired state already
 * matches. Safe to re-run.
 *
 * Pagination: pass back `nextCursor` from the previous call's response.
 *
 * Note: existing admin sessions need to call `getIdToken(true)` once for
 * the new claim to appear in their token. New sessions get it for free.
 */

const PAGE_SIZE = 200;

type Result = {
  scanned: number;
  promoted: number;
  demoted: number;
  unchanged: number;
  failed: number;
  nextCursor: string | null;
  done: boolean;
};

const db = admin.firestore();

export const syncAdminClaims = onCall(
  { region: "us-central1", timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<{ cursor?: string | null }>): Promise<Result> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    }
    try {
      await assertCallerIsAdmin(request.auth.token, db);
    } catch {
      throw new HttpsError("permission-denied", "ADMIN_REQUIRED");
    }

    const cursor = typeof request.data?.cursor === "string" ? request.data.cursor : null;

    let q = db.collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (cursor) q = q.startAfter(cursor);

    const snap = await q.get();
    let scanned = 0;
    let promoted = 0;
    let demoted = 0;
    let unchanged = 0;
    let failed = 0;
    let lastId: string | null = null;

    for (const doc of snap.docs) {
      scanned++;
      lastId = doc.id;
      const role = doc.data()?.role;
      const shouldBeAdmin = role === "admin";
      try {
        const { changed } = await ensureAdminClaim(doc.id, shouldBeAdmin);
        if (!changed) unchanged++;
        else if (shouldBeAdmin) promoted++;
        else demoted++;
      } catch (e) {
        failed++;
        logger.warn("[syncAdminClaims] ensureAdminClaim failed", {
          uid: doc.id,
          error: String(e),
        });
      }
    }

    return {
      scanned,
      promoted,
      demoted,
      unchanged,
      failed,
      nextCursor: snap.size === PAGE_SIZE ? lastId : null,
      done: snap.size < PAGE_SIZE,
    };
  },
);
