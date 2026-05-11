import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";

/**
 * Secret chat settings are immutable after creation (product rule).
 */
export const updateSecretChatSettings = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<Record<string, unknown>>): Promise<{ ok: true }> => {
    if (!request.auth?.uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    throw new HttpsError("failed-precondition", "SETTINGS_IMMUTABLE");
  },
);
