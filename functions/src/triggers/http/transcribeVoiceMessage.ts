import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

type RequestData = {
  conversationId?: unknown;
  messageId?: unknown;
  languageCode?: unknown;
};

type ResponseData = {
  transcript: string;
};

const MAX_BYTES = 12 * 1024 * 1024; // 12 MB

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

function isVoiceAttachment(a: any): boolean {
  const type = typeof a?.type === "string" ? a.type.toLowerCase() : "";
  if (type.startsWith("audio/")) return true;
  const name = typeof a?.name === "string" ? a.name.toLowerCase() : "";
  return name.startsWith("audio_");
}

function voiceAttachmentUrl(a: any): string | null {
  const url = typeof a?.url === "string" ? a.url.trim() : "";
  return url ? url : null;
}

async function openAiTranscribe({
  bytes,
  filename,
  languageCode,
}: {
  bytes: Uint8Array;
  filename: string;
  languageCode: string;
}): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError("failed-precondition", "OPENAI_API_KEY_MISSING");
  }

  // Node 20 has global FormData / Blob via undici.
  const form = new FormData();
  form.append("model", "whisper-1");
  form.append("language", languageCode);
  form.append("response_format", "json");
  form.append("file", new Blob([bytes]), filename);

  const resp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
    body: form,
  });

  if (!resp.ok) {
    const body = await resp.text().catch(() => "");
    logger.error("[transcribeVoiceMessage] openai failed", {
      status: resp.status,
      body: body.slice(0, 2000),
    });
    throw new HttpsError("internal", "TRANSCRIPTION_PROVIDER_FAILED");
  }

  const json = (await resp.json()) as any;
  const text = typeof json?.text === "string" ? json.text.trim() : "";
  return text;
}

export const transcribeVoiceMessage = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const messageId = asNonEmptyString(request.data?.messageId);
    if (!conversationId || !messageId) {
      throw new HttpsError("invalid-argument", "BAD_INPUT");
    }

    const langRaw = asNonEmptyString(request.data?.languageCode) ?? "ru";
    const languageCode = ["ru", "en"].includes(langRaw.toLowerCase()) ? langRaw.toLowerCase() : "ru";

    const db = admin.firestore();
    const messageRef = db.doc(`conversations/${conversationId}/messages/${messageId}`);
    const snap = await messageRef.get();
    if (!snap.exists) throw new HttpsError("not-found", "MESSAGE_NOT_FOUND");
    const data = snap.data() || {};

    // E2EE: server cannot transcribe ciphertext.
    if (data.e2ee != null) {
      throw new HttpsError("failed-precondition", "E2EE_UNSUPPORTED");
    }

    // Membership check: rely on conversations/{id} member index if needed; minimal safe check:
    // The mobile client will only call from inside a chat; keep it defensive anyway.
    const convSnap = await db.doc(`conversations/${conversationId}`).get();
    const conv = convSnap.data() || {};
    const ids = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!ids.includes(uid)) {
      throw new HttpsError("permission-denied", "NOT_A_MEMBER");
    }
    // Prevent transcribing deleted message.
    if (data.isDeleted === true) {
      throw new HttpsError("failed-precondition", "MESSAGE_DELETED");
    }

    const existing = data.voiceTranscript;
    if (typeof existing === "string" && existing.trim().length > 0) {
      return { transcript: existing.trim() };
    }
    if (existing && typeof existing === "object" && typeof existing.text === "string" && existing.text.trim()) {
      return { transcript: existing.text.trim() };
    }

    const atts = Array.isArray(data.attachments) ? data.attachments : [];
    const voiceAtt = atts.find((a) => isVoiceAttachment(a));
    if (!voiceAtt) {
      throw new HttpsError("failed-precondition", "NOT_A_VOICE_MESSAGE");
    }
    const url = voiceAttachmentUrl(voiceAtt);
    if (!url) throw new HttpsError("failed-precondition", "VOICE_URL_MISSING");
    const size = typeof voiceAtt.size === "number" ? voiceAtt.size : null;
    if (size != null && size > MAX_BYTES) {
      throw new HttpsError("failed-precondition", "VOICE_TOO_LARGE");
    }

    const resp = await fetch(url);
    if (!resp.ok) {
      throw new HttpsError("internal", "VOICE_DOWNLOAD_FAILED");
    }
    const buf = new Uint8Array(await resp.arrayBuffer());
    if (buf.byteLength > MAX_BYTES) {
      throw new HttpsError("failed-precondition", "VOICE_TOO_LARGE");
    }

    const filename = (typeof voiceAtt.name === "string" && voiceAtt.name.trim()) ? voiceAtt.name.trim() : `voice_${messageId}.m4a`;

    const transcript = await openAiTranscribe({
      bytes: buf,
      filename,
      languageCode,
    });

    const trimmed = transcript.trim();
    await messageRef.set(
      {
        voiceTranscript: {
          text: trimmed,
          languageCode,
          provider: "openai.whisper-1",
          createdAt: new Date().toISOString(),
          requestedBy: uid,
        },
      },
      { merge: true }
    );

    return { transcript: trimmed };
  }
);

