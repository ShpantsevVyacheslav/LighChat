import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { isSecretConversation } from "../../lib/secret-chat-index";
import { cleanupSecretChatConversationFully } from "../../lib/secret-chat-cleanup";

const db = admin.firestore();

type Payload = { conversationId?: unknown };

/**
 * Permanently delete a secret chat for both participants (any participant may call).
 */
export const deleteSecretChat = onCall(
  { region: "us-central1", enforceAppCheck: false, timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<Payload>) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId =
      typeof request.data?.conversationId === "string" ? request.data.conversationId.trim() : "";
    if (!conversationId) throw new HttpsError("invalid-argument", "BAD_CONVERSATION_ID");

    const ref = db.doc(`conversations/${conversationId}`);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");

    const data = (snap.data() || {}) as Record<string, unknown>;
    const participantIds = Array.isArray(data.participantIds) ?
      data.participantIds.filter((x): x is string => typeof x === "string") :
      [];

    if (!participantIds.includes(uid)) {
      throw new HttpsError("permission-denied", "NOT_A_MEMBER");
    }

    if (!isSecretConversation(conversationId, data)) {
      throw new HttpsError("failed-precondition", "NOT_A_SECRET_CHAT");
    }

    try {
      await cleanupSecretChatConversationFully(conversationId, data);
      logger.info("[deleteSecretChat] removed", { conversationId, uid });
      return { ok: true as const };
    } catch (e) {
      logger.error("[deleteSecretChat] failed", { conversationId, err: String(e) });
      throw new HttpsError("internal", "DELETE_FAILED");
    }
  },
);
