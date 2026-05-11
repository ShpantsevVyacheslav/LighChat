
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Guest calls this to request access to a private meeting.
 */
export const requestMeetingAccess = onCall({ region: "us-central1", enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Вы должны быть авторизованы.");
  }

  const { meetingId, name, avatar, requestId } = request.data;
  if (!meetingId || !name) {
    throw new HttpsError("invalid-argument", "Не указаны meetingId или имя.");
  }

  const meetingDoc = await db.doc(`meetings/${meetingId}`).get();
  if (!meetingDoc.exists) {
    throw new HttpsError("not-found", "Встреча не найдена.");
  }

  const requestRef = db.doc(`meetings/${meetingId}/requests/${request.auth.uid}`);
  await requestRef.set({
    userId: request.auth.uid,
    name,
    avatar: avatar || "",
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSeen: new Date().toISOString(),
    requestId: requestId || null,
  });

  return { success: true };
});

/**
 * Host calls this to approve or deny a request.
 */
export const respondToMeetingRequest = onCall({ region: "us-central1", enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Вы должны быть авторизованы.");
  }

  const { meetingId, userId, approve } = request.data;
  if (!meetingId || !userId) {
    throw new HttpsError("invalid-argument", "Не указаны meetingId или userId.");
  }

  const meetingDoc = await db.doc(`meetings/${meetingId}`).get();
  if (!meetingDoc.exists) {
    throw new HttpsError("not-found", "Встреча не найдена.");
  }

  if (meetingDoc.data()?.hostId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Только организатор может управлять доступом.");
  }

  const requestRef = db.doc(`meetings/${meetingId}/requests/${userId}`);
  if (approve) {
    await requestRef.update({ status: "approved" });
  } else {
    await requestRef.update({ status: "denied" });
  }

  return { success: true };
});
