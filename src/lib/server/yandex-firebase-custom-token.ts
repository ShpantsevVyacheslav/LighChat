import {
  type YandexLoginInfo,
  yandexDisplayName,
  yandexNumericUserId,
  yandexPhotoUrl,
  yandexPrimaryEmail,
  yandexPrimaryPhone,
} from "@/lib/server/yandex-oauth";
import { adminAuth } from "@/firebase/admin";
import { mergeProviderPhoneAndAvatarIntoUserDocAdmin } from "@/lib/server/merge-provider-profile-firestore-admin";
import { adminDb } from "@/firebase/admin";
import { generateUniqueUsernameAdmin } from "@/lib/server/generate-unique-username-admin";

function firebaseAuthErrorCode(e: unknown): string {
  if (typeof e !== "object" || e === null) return "";
  const o = e as Record<string, unknown>;
  if (typeof o.code === "string") return o.code;
  const ei = o.errorInfo;
  if (ei && typeof ei === "object" && ei !== null) {
    const c = (ei as Record<string, unknown>).code;
    if (typeof c === "string") return c;
  }
  return "";
}

async function updateYandexUserProfile(
  uid: string,
  displayName: string,
  photoURL: string | undefined
): Promise<void> {
  try {
    await adminAuth.updateUser(uid, {
      displayName,
      ...(photoURL ? { photoURL } : {}),
    });
  } catch (e: unknown) {
    if (photoURL) {
      await adminAuth.updateUser(uid, { displayName });
      return;
    }
    throw e;
  }
}

async function getOrCreateYandexAuthUser(
  uid: string,
  displayName: string,
  email: string | undefined,
  photoURL: string | undefined
): Promise<void> {
  try {
    await adminAuth.getUser(uid);
    await updateYandexUserProfile(uid, displayName, photoURL);
    return;
  } catch (e: unknown) {
    if (firebaseAuthErrorCode(e) !== "auth/user-not-found") {
      console.error("yandex auth: getUser error", e);
      throw new Error("Could not load Firebase user.");
    }
  }

  const base = { uid, displayName, ...(photoURL ? { photoURL } : {}) };
  try {
    if (email) {
      await adminAuth.createUser({ ...base, email });
    } else {
      await adminAuth.createUser(base);
    }
  } catch (e: unknown) {
    const code = firebaseAuthErrorCode(e);
    if (code === "auth/uid-already-exists") {
      await updateYandexUserProfile(uid, displayName, photoURL);
      return;
    }
    if (email && code === "auth/email-already-in-use") {
      try {
        await adminAuth.createUser(base);
        return;
      } catch (e2: unknown) {
        const c2 = firebaseAuthErrorCode(e2);
        if (c2 === "auth/uid-already-exists") {
          await updateYandexUserProfile(uid, displayName, photoURL);
          return;
        }
        console.error("yandex auth: createUser without email failed", e2);
        throw new Error("Could not create Firebase user.");
      }
    }
    if (email) {
      try {
        await adminAuth.createUser(base);
        return;
      } catch (e3: unknown) {
        const c3 = firebaseAuthErrorCode(e3);
        if (c3 === "auth/uid-already-exists") {
          await updateYandexUserProfile(uid, displayName, undefined);
          return;
        }
        console.error("yandex auth: createUser retry failed", e3);
        throw new Error("Could not create Firebase user.");
      }
    }
    console.error("yandex auth: createUser failed", e);
    throw new Error("Could not create Firebase user.");
  }
}

/**
 * UID `ya_<yandex_numeric_id>` и claim `yandex: true` — паритет с Telegram custom token.
 */
export async function issueFirebaseCustomTokenForYandexProfile(
  info: YandexLoginInfo
): Promise<{ customToken: string; uid: string }> {
  const yandexId = yandexNumericUserId(info);
  const uid = `ya_${yandexId}`;
  const displayName = yandexDisplayName(info);
  const email = yandexPrimaryEmail(info);
  const photoURL = yandexPhotoUrl(info);
  const yandexLogin =
    typeof info.login === "string" && info.login.trim().length > 0
      ? info.login.trim()
      : undefined;

  await getOrCreateYandexAuthUser(uid, displayName, email, photoURL);

  const yandexPhone = yandexPrimaryPhone(info);
  await mergeProviderPhoneAndAvatarIntoUserDocAdmin({
    uid,
    providerPhoneRaw: yandexPhone,
    providerPhotoUrl: photoURL,
  });

  try {
    const userSnap = await adminDb.doc(`users/${uid}`).get();
    const data = userSnap.exists ? userSnap.data() ?? {} : {};
    const existingUsername = String((data as Record<string, unknown>).username ?? "")
      .trim()
      .replace(/^@/, "");
    if (!existingUsername) {
      const username = await generateUniqueUsernameAdmin({
        uid,
        preferredCandidate: yandexLogin,
        fallbackCandidate: displayName,
      });
      await adminDb.doc(`users/${uid}`).set({ username }, { merge: true });
    }
  } catch (e) {
    console.warn("[yandex auth] username bootstrap skipped", e);
  }

  try {
    const customToken = await adminAuth.createCustomToken(uid, {
      yandex: true,
    });
    return { customToken, uid };
  } catch (e: unknown) {
    console.error("yandex auth: createCustomToken failed", e);
    throw new Error("Could not issue sign-in token.");
  }
}
