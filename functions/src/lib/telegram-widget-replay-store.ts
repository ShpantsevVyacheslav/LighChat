// SECURITY: anti-replay for Telegram Login Widget signatures.
//
// `verifyTelegramLoginWidget` only verifies that a payload was signed by our
// bot within the configured TTL. It does NOT prevent the SAME signed payload
// from being submitted twice. With a long TTL (was 24h) that gave an attacker
// who captured one payload many opportunities to reuse it; even with the
// new 10-minute TTL the cleanest defence is to remember (auth_date, hash)
// tuples server-side and reject the second use.
//
// Storage: `telegramAuthReplay/{key}` — sha256(auth_date|hash) as document id
// to keep the writeable surface predictable and the keyspace bounded. We set
// a Firestore TTL on the `expireAt` field so old entries are auto-collected
// and the collection doesn't grow unbounded. (Operator: enable TTL on
// telegramAuthReplay.expireAt in Firebase Console — same one-time setup
// required by rateLimits.)
//
// Atomicity: we use `create()` rather than `set()`. create() fails with
// ALREADY_EXISTS on a duplicate, which is exactly the replay signal we want.

import * as admin from "firebase-admin";
import * as crypto from "crypto";

const COLLECTION = "telegramAuthReplay";
const TTL_MARGIN_SEC = 120; // keep the marker for `validForSec + margin` to cover clock skew

/** Returns true if this (auth_date, hash) tuple has NOT been seen before. */
export async function claimTelegramAuthOnce(
  db: admin.firestore.Firestore,
  authDate: number,
  hash: string,
  validForSec: number,
): Promise<{ ok: true } | { ok: false; reason: "REPLAY" | "STORE_ERROR" }> {
  if (!Number.isFinite(authDate) || !hash) {
    return { ok: false, reason: "STORE_ERROR" };
  }
  const key = crypto
    .createHash("sha256")
    .update(`${authDate}|${hash}`)
    .digest("hex");
  const ref = db.collection(COLLECTION).doc(key);
  const expireAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + (validForSec + TTL_MARGIN_SEC) * 1000,
  );
  try {
    await ref.create({
      authDate,
      // Store only a prefix of the hash for debugging — the full one is
      // already encoded in the doc id and there's no need to duplicate it.
      hashPrefix: hash.slice(0, 8),
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      expireAt,
    });
    return { ok: true };
  } catch (e: unknown) {
    // Firestore throws with code 6 (ALREADY_EXISTS) on duplicate create —
    // the canonical "we've seen this signature before" signal.
    const code = (e as { code?: number | string } | undefined)?.code;
    if (code === 6 || code === "already-exists") {
      return { ok: false, reason: "REPLAY" };
    }
    return { ok: false, reason: "STORE_ERROR" };
  }
}
