
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

  /**
   * Регистрация по email в клиенте делает `setDoc` с полным профилем сразу после
   * `createUserWithEmailAndPassword`. Старый вариант с `set(..., { merge: true })` и пустыми
   * полями при отложенном срабатывании триггера затирал username/phone/name.
   *
   * Транзакция: создаём дефолтный профиль только если документа ещё нет; если клиент
   * успел записать профиль между попытками — повторное чтение увидит `exists` и выйдет.
   */
  /** Custom-token пользователи Telegram/Яндекс: в Auth нет email/phone, но это не гость Firebase. */
  const isOAuthBridgeUid =
    typeof user.uid === "string" &&
    (user.uid.startsWith("tg_") || user.uid.startsWith("ya_"));
  const isAnonymous = !isOAuthBridgeUid && !user.email && !user.phoneNumber;

  const profileQrLink = `https://lighchat.online/dashboard/contacts/${encodeURIComponent(user.uid)}`;

  const userProfile = {
    id: user.uid,
    name: user.displayName || (isAnonymous ? "Гость" : "Новый пользователь"),
    username: "",
    email: user.email || (isAnonymous ? `guest_${user.uid}@anonymous.com` : ""),
    phone: user.phoneNumber || "",
    avatar: user.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}`,
    profileQrLink,
    role: isAnonymous ? null : "worker",
    bio: "",
    dateOfBirth: null,
    createdAt: new Date().toISOString(),
    deletedAt: null,
    online: false,
    lastSeen: new Date().toISOString(),
  };

  try {
    let wroteDefaults = false;
    let backfilledPrivileged = false;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) {
        tx.set(userRef, userProfile);
        wroteDefaults = true;
        return;
      }
      // SECURITY: Firestore rules now forbid the client from setting `role`,
      // `accountBlock`, `deletedAt`, `storageQuotaBytes` on create (CVE: an
      // attacker could otherwise self-promote to admin by racing this trigger).
      // If the client wrote the profile first, those privileged fields will be
      // missing — backfill them here from the trusted server-side defaults.
      const data = snap.data() ?? {};
      const merge: Record<string, unknown> = {};
      if (!Object.prototype.hasOwnProperty.call(data, "role")) {
        merge.role = isAnonymous ? null : "worker";
      }
      if (!Object.prototype.hasOwnProperty.call(data, "deletedAt")) {
        merge.deletedAt = null;
      }
      if (Object.keys(merge).length > 0) {
        tx.set(userRef, merge, { merge: true });
        backfilledPrivileged = true;
      }
    });
    if (wroteDefaults) {
      logger.log(`Created default profile for user: ${user.uid} (Anonymous: ${isAnonymous})`);
    } else if (backfilledPrivileged) {
      logger.log(`users/${user.uid} existed; backfilled privileged defaults.`);
    } else {
      logger.log(`users/${user.uid} already had profile; onUserCreated skipped write.`);
    }
  } catch (error) {
    logger.error(`Error creating user profile for ${user.uid}:`, error);
  }
});
