// SECURITY: encrypt the Firebase customToken handed off via QR login so that
// reading the world-readable qrLoginSessions/{sessionId} document is no longer
// enough to hijack the sign-in. Without this, anyone who learned a session id
// + enough timing to hit the 60-second window (logs, proxy headers, scrolled
// browser history) could read the plaintext customToken straight from
// Firestore and call signInWithCustomToken on someone else's account.
//
// Construction (matches the v2 ECDH wrap used elsewhere in the codebase, see
// src/lib/e2ee/v2/webcrypto-v2.ts — same primitives, same parameters):
//   - Recipient: a STATIC ECDH P-256 public key the client published in
//     `requestQrLogin.ephemeralPubKeySpki` (it really is the device's
//     long-term identity public key, not single-use; safe because the device
//     also holds the matching private key in secure storage).
//   - Sender: an ephemeral ECDH P-256 keypair generated per encryption.
//   - Z = ECDH(eph_priv, recipient_pub)
//   - wrapKey = HKDF-SHA256(Z, salt=sessionId, info='lighchat/qr-login/v1', 32)
//   - AES-256-GCM(wrapKey, iv, customToken, AAD=sessionId)
// AAD binds the ciphertext to its session, so an attacker who somehow swaps
// ciphertexts between sessions just gets a GCM auth-tag failure.

import * as crypto from "node:crypto";

const HKDF_INFO = "lighchat/qr-login/v1";
const ALG_LABEL = "ecdh-p256-hkdf-aesgcm-v1";

export type EncryptedCustomToken = {
  alg: typeof ALG_LABEL;
  ephPub: string; // SPKI base64
  iv: string; // 12-byte AES-GCM nonce, base64
  ct: string; // ciphertext || GCM tag (16 bytes), base64
};

export class QrTokenEncryptError extends Error {
  readonly code: string;
  constructor(code: string, message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = "QrTokenEncryptError";
  }
}

/**
 * Encrypt `customToken` for the device that owns `recipientPublicSpkiB64`.
 * Only the holder of the matching ECDH P-256 private key can decrypt.
 */
export function encryptCustomTokenForRecipient(
  customToken: string,
  recipientPublicSpkiB64: string,
  sessionId: string,
): EncryptedCustomToken {
  if (!customToken || customToken.length === 0) {
    throw new QrTokenEncryptError("BAD_INPUT", "empty customToken");
  }
  if (!sessionId || sessionId.length < 16) {
    throw new QrTokenEncryptError("BAD_INPUT", "bad sessionId");
  }
  if (!recipientPublicSpkiB64 || recipientPublicSpkiB64.length === 0) {
    throw new QrTokenEncryptError("BAD_INPUT", "no recipient key");
  }

  let recipientPub: crypto.KeyObject;
  try {
    recipientPub = crypto.createPublicKey({
      key: Buffer.from(recipientPublicSpkiB64, "base64"),
      format: "der",
      type: "spki",
    });
  } catch (e) {
    throw new QrTokenEncryptError("BAD_RECIPIENT_KEY", String(e));
  }

  // Refuse anything that isn't P-256 — protects against confusion attacks
  // where an attacker tricks the server into using a curve they control.
  // KeyObject.asymmetricKeyDetails is available on Node ≥16.5.
  const details = (recipientPub as unknown as { asymmetricKeyDetails?: { namedCurve?: string } })
    .asymmetricKeyDetails;
  const curve = details?.namedCurve;
  if (curve !== "prime256v1" && curve !== "P-256") {
    throw new QrTokenEncryptError("BAD_RECIPIENT_CURVE", String(curve));
  }

  const ephemeral = crypto.generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const z = crypto.diffieHellman({
    privateKey: ephemeral.privateKey,
    publicKey: recipientPub,
  });

  // HKDF-SHA256 → 32-byte AES-256-GCM key. salt = sessionId binds the wrap to
  // this specific QR session so a leaked customTokenCipher from one session
  // can't be replayed into another. info is a domain separator vs. the chat-
  // key wrapping flow that uses the same primitives.
  const salt = Buffer.from(sessionId, "utf8");
  const info = Buffer.from(HKDF_INFO, "utf8");
  const wrapKey = Buffer.from(crypto.hkdfSync("sha256", z, salt, info, 32));

  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", wrapKey, iv, {
    authTagLength: 16,
  });
  // AAD = sessionId — bind ciphertext to its session ID. A cross-session
  // copy of (ephPub, iv, ct) decrypts to a GCM auth failure.
  cipher.setAAD(Buffer.from(sessionId, "utf8"));
  const ctBody = Buffer.concat([
    cipher.update(Buffer.from(customToken, "utf8")),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  const ctWithTag = Buffer.concat([ctBody, tag]);

  const ephPubSpki = ephemeral.publicKey.export({ format: "der", type: "spki" });

  return {
    alg: ALG_LABEL,
    ephPub: Buffer.from(ephPubSpki).toString("base64"),
    iv: iv.toString("base64"),
    ct: ctWithTag.toString("base64"),
  };
}
