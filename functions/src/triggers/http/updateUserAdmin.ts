import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Cloud Function for administrators to update any user's profile and password.
 * This bypasses client-side security rule limitations for cross-user updates.
 */
export const updateUserAdmin = onCall({ region: "us-central1" }, async (request: CallableRequest<{ uid: string; userData: Record<string, unknown>; password?: string | null }>) => {
  // 1. Check if the caller is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  // 2. Check if the caller is an administrator
  const callerUid = request.auth.uid;
  const callerUserDoc = await db.collection("users").doc(callerUid).get();
  const callerData = callerUserDoc.data();

  if (callerData?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only administrators can update other users.");
  }

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

    return { success: true };
  } catch (error: unknown) {
    logger.error("Error updating user by admin:", error);
    const message = error instanceof Error ? error.message : "An internal error occurred during user update.";
    throw new HttpsError("internal", message);
  }
});
