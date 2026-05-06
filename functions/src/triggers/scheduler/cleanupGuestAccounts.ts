import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * TTL гостевого аккаунта (Firebase Anonymous Auth, заведённого на странице
 * `/meetings/[meetingId]`). По истечении срока автоматически удаляется и
 * Auth-запись, и Firestore-профиль `users/{uid}`, созданный триггером
 * `onUserCreated`.
 */
const GUEST_TTL_MS = 24 * 60 * 60 * 1000;

/** Безопасный лимит удаления Auth-пользователей за один тик планировщика. */
const MAX_DELETIONS_PER_RUN = 500;

/** Максимум `listUsers()` за вызов (Firebase Auth Admin API). */
const LIST_USERS_PAGE_SIZE = 1000;

/**
 * Auth providerData у гостя пуст; у custom-token (Telegram/Яндекс) тоже
 * пусто, но они стартуют с uid `tg_*`/`ya_*` (см. `onUserCreated.ts`).
 * Ещё одна страховка — `email` пустой/гостевой placeholder.
 */
function isGuestUser(user: admin.auth.UserRecord): boolean {
  if (user.providerData && user.providerData.length > 0) return false;
  if (user.uid.startsWith("tg_") || user.uid.startsWith("ya_")) return false;
  if (user.email && user.email.length > 0 && !user.email.endsWith("@anonymous.com")) {
    return false;
  }
  if (user.phoneNumber && user.phoneNumber.length > 0) return false;
  return true;
}

async function deleteGuestFirestoreFootprint(uid: string): Promise<void> {
  /**
   * Гость ничего не пишет в `userChats/userContacts/userCalls/userMeetings`
   * (правила это запрещают через `isMeetingGuestApproved`-only пути), но
   * `users/{uid}` гарантированно создаётся `onUserCreated`. На всякий случай
   * — recursiveDelete по тем же путям, что и `deleteAccount`, чтобы не было
   * сирот, если поведение когда-то изменится.
   */
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`userChats/${uid}`));
  await db.recursiveDelete(db.doc(`userContacts/${uid}`));
  await db.recursiveDelete(db.doc(`userCalls/${uid}`));
  await db.recursiveDelete(db.doc(`userMeetings/${uid}`));
}

export const cleanupGuestAccounts = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Europe/Moscow",
  },
  async () => {
    const cutoff = Date.now() - GUEST_TTL_MS;
    const expiredGuestUids: string[] = [];
    let pageToken: string | undefined;
    let scanned = 0;

    try {
      do {
        const page = await admin
          .auth()
          .listUsers(LIST_USERS_PAGE_SIZE, pageToken);
        for (const user of page.users) {
          scanned++;
          if (!isGuestUser(user)) continue;
          const createdAt = Date.parse(user.metadata.creationTime);
          if (!Number.isFinite(createdAt)) continue;
          if (createdAt > cutoff) continue;
          expiredGuestUids.push(user.uid);
          if (expiredGuestUids.length >= MAX_DELETIONS_PER_RUN) break;
        }
        pageToken = page.pageToken;
      } while (pageToken && expiredGuestUids.length < MAX_DELETIONS_PER_RUN);

      if (expiredGuestUids.length === 0) {
        logger.log(
          `[cleanupGuestAccounts] Scanned ${scanned} users, no guests older than 24h.`
        );
        return;
      }

      let firestoreCleaned = 0;
      let firestoreFailed = 0;
      for (const uid of expiredGuestUids) {
        try {
          await deleteGuestFirestoreFootprint(uid);
          firestoreCleaned++;
        } catch (err) {
          firestoreFailed++;
          logger.error(
            `[cleanupGuestAccounts] Firestore cleanup failed for ${uid}:`,
            err
          );
        }
      }

      /**
       * Auth API `deleteUsers` принимает максимум 1000 uid за вызов и не падает
       * целиком при ошибке для отдельной записи — возвращает список errors.
       */
      const result = await admin.auth().deleteUsers(expiredGuestUids);
      if (result.errors.length > 0) {
        for (const e of result.errors) {
          logger.error(
            `[cleanupGuestAccounts] Auth deletion failed for ${
              expiredGuestUids[e.index]
            }:`,
            e.error
          );
        }
      }

      logger.log(
        `[cleanupGuestAccounts] Removed ${result.successCount} guest auth accounts ` +
          `(failures=${result.failureCount}, firestoreCleaned=${firestoreCleaned}, ` +
          `firestoreFailed=${firestoreFailed}, scanned=${scanned}).`
      );
    } catch (err) {
      logger.error("[cleanupGuestAccounts] Cleanup failed:", err);
    }
  }
);
