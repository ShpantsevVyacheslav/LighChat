
import admin from 'firebase-admin';

if (!admin.apps.length) {
  try {
    // Initialize the Admin SDK without arguments.
    // This allows it to automatically discover the correct credentials
    // in a managed environment like Firebase App Hosting.
    admin.initializeApp();
    console.log("Firebase Admin SDK initialized with auto-discovered credentials.");
  } catch (e: unknown) {
    console.error("Firebase Admin SDK initialization failed:", e);
    // This might happen in a local dev environment if ADC are not set up.
    // However, in the deployed App Hosting environment, this should succeed.
  }
}

const adminDb = admin.firestore();
const adminMessaging = admin.messaging();
const adminAuth = admin.auth();

function getStorageBucket() {
    // By default, admin.storage().bucket() should return the default bucket for the project.
    return admin.storage().bucket();
}

export { adminDb, adminMessaging, adminAuth, getStorageBucket };
