import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { logAdminActionCF } from "../../lib/audit-log";
import { assertCallerIsAdmin, ensureAdminClaim } from "../../lib/admin-claims";

const db = admin.firestore();

/**
 * Cloud Function for administrators to update any user's profile and password.
 * This bypasses client-side security rule limitations for cross-user updates.
 */
export const updateUserAdmin = onCall({ region: "us-central1", enforceAppCheck: false }, async (request: CallableRequest<{ uid: string; userData: Record<string, unknown>; password?: string | null }>) => {
  // 1. Check if the caller is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  // 2. SECURITY: prefer Custom Claim verification over Firestore role read.
  // assertCallerIsAdmin checks decoded.admin === true first, then falls back
  // to users/{uid}.role for backward compatibility while we migrate.
  let caller;
  try {
    caller = await assertCallerIsAdmin(request.auth.token, db);
  } catch (e) {
    const code = e instanceof Error ? e.message : "FORBIDDEN";
    throw new HttpsError(
      code === "UNAUTHENTICATED" ? "unauthenticated" : "permission-denied",
      "Only administrators can update other users.",
    );
  }
  const callerUid = caller.uid;
  const callerData = { name: caller.name } as { name: string };

  // 3. Extract and validate input data
  const { uid, userData, password } = request.data;
  if (!uid || !userData) {
    throw new HttpsError("invalid-argument", "Missing 'uid' or 'userData' in request.");
  }

  try {
    // 4. Update Auth password if provided
    if (password && password.length >= 6) {
      await admin.auth().updateUser(uid, { password });
      logger.log(`Password updated successfully for user: ${uid}`);
    }

    // 5. Update Firestore profile document
    const updatePayload = {
      ...userData,
      updatedAt: new Date().toISOString(),
    };

    await db.collection("users").doc(uid).update(updatePayload);
    logger.log(`Profile document updated successfully for user: ${uid}`);

    // SECURITY: keep the Custom Claim in sync with users/{uid}.role. If this
    // admin promotion / demotion goes through Firestore but we forget the
    // claim, the new admin can't pass assertCallerIsAdmin's claim path —
    // they fall through to the legacy Firestore check, which is exactly the
    // surface we want to retire. Mirror immediately so future calls pick the
    // claim path.
    if (Object.prototype.hasOwnProperty.call(userData, "role")) {
      const nextRole = (userData as Record<string, unknown>).role;
      try {
        const { changed } = await ensureAdminClaim(uid, nextRole === "admin");
        if (changed) logger.info("Custom claim 'admin' synced", { uid, isAdmin: nextRole === "admin" });
      } catch (e) {
        logger.warn("Failed to sync admin custom claim", { uid, error: String(e) });
      }
    }

    await logAdminActionCF({
      db,
      actorId: callerUid,
      actorName: callerData?.name ?? "Admin",
      action: "user.update",
      target: { type: "user", id: uid, name: (userData as Record<string, unknown>).name as string | undefined },
      details: { updatedFields: Object.keys(userData), passwordChanged: !!password },
    }).catch((e) => logger.warn("Audit log failed:", e));

    return { success: true };
  } catch (error: unknown) {
    logger.error("Error updating user by admin:", error);
    const message = error instanceof Error ? error.message : "An internal error occurred during user update.";
    throw new HttpsError("internal", message);
  }
});
