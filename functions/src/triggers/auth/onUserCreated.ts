
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v1";

/**
 * Automatically creates a user profile document in Firestore when a new user
 * is created in Firebase Authentication. This includes both email/password
 * users and anonymous guests.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  
  const userRef = db.doc(`users/${user.uid}`);
  
  // Check if it's an anonymous user
  const isAnonymous = !user.email && !user.phoneNumber;
  
  const userProfile = {
    id: user.uid,
    name: user.displayName || (isAnonymous ? "Гость" : "Новый пользователь"),
    username: "",
    email: user.email || (isAnonymous ? `guest_${user.uid}@anonymous.com` : ""),
    phone: user.phoneNumber || "",
    avatar: user.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}`,
    role: isAnonymous ? null : "worker",
    bio: "",
    dateOfBirth: null,
    createdAt: new Date().toISOString(),
    deletedAt: null,
    online: false,
    lastSeen: new Date().toISOString(),
  };

  try {
    await userRef.set(userProfile, { merge: true });
    logger.log(`Successfully created profile for user: ${user.uid} (Anonymous: ${isAnonymous})`);
  } catch (error) {
    logger.error(`Error creating user profile for ${user.uid}:`, error);
  }
});
