import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { generateUniqueUsernameAdmin } from "../../lib/generate-unique-username-admin";
import { logAdminActionCF } from "../../lib/audit-log";

const db = admin.firestore();

export const createNewUser = onCall({ region: "us-central1", enforceAppCheck: false }, async (request) => {
  // 1. Check if the caller is authenticated and an admin.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const callerUid = request.auth.uid;
  const callerUserDoc = await db.collection("users").doc(callerUid).get();
  const callerData = callerUserDoc.data();

  if (callerData?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only administrators can create users.");
  }

  // 2. Validate the incoming data.
  const { email, password, name, role, phone, avatar } = request.data;
  if (!email || !password || !name) {
    throw new HttpsError("invalid-argument", "The function must be called with 'email', 'password', and 'name' arguments.");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "Password must be at least 6 characters long.");
  }

  // 3. Create the user in Firebase Authentication.
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // 4. Generate a unique username
    const username = await generateUniqueUsernameAdmin({
      db,
      uid: userRecord.uid,
      fallbackCandidate: name,
    });

    // 5. Create the Firestore profile document immediately (on the server side)
    const newUserProfile = {
      id: userRecord.uid,
      name: name,
      username,
      email: email,
      role: role || "worker",
      avatar: avatar || "",
      phone: phone || "",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      deletedAt: null,
    };

    await db.collection("users").doc(userRecord.uid).set(newUserProfile);
    logger.log(`Successfully created Auth and Firestore profile for user: ${userRecord.uid}`);

    await logAdminActionCF({
      db,
      actorId: callerUid,
      actorName: callerData?.name ?? "Admin",
      action: "user.create",
      target: { type: "user", id: userRecord.uid, name },
      details: { email, role: role || "worker" },
    }).catch((e) => logger.warn("Audit log failed:", e));

    return { uid: userRecord.uid };
  } catch (error: unknown) {
    logger.error("Error creating new user:", error);
    if (typeof error === "object" && error !== null && "code" in error && typeof (error as { code: unknown }).code === "string") {
      const firebaseError = error as { code: string };
      if (firebaseError.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "The email address is already in use by another account.");
      }
    }
    throw new HttpsError("internal", "An internal error occurred while creating the user.");
  }
});
