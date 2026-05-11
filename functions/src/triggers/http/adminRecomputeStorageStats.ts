import {
  onCall,
  HttpsError,
  type CallableRequest,
} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { assertCallerIsAdmin } from "../../lib/admin-claims";

/**
 * Пересчитывает `conversations/{cid}.storage` из `messages` коллекции:
 *   - totalBytes  — сумма attachments.fileSizeBytes
 *   - videoBytes  — где attachment.kind == 'video'
 *   - imageBytes  — 'image'
 *   - audioBytes  — 'audio' | 'voice'
 *   - fileBytes   — остальное (document/файлы)
 *
 * Вызывается из AdminStorageStatsScreen → кнопка «Пересчитать».
 *
 * Безопасность: только admin/worker роль (`assertCallerIsAdmin`).
 * Пагинация: одну страницу из `PAGE_SIZE` бесед за вызов; клиент крутит
 * call в цикле, передавая `nextCursor` из ответа, пока `done == true`.
 */

const PAGE_SIZE = 50;

type Result = {
  processed: number;
  totalBytesRecounted: number;
  nextCursor: string | null;
  done: boolean;
};

const db = admin.firestore();

export const adminRecomputeStorageStats = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (
    request: CallableRequest<{ cursor?: string | null }>,
  ): Promise<Result> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }
    await assertCallerIsAdmin(request.auth.token, db);

    const cursor = request.data?.cursor ?? null;
    let query: FirebaseFirestore.Query = db
      .collection("conversations")
      .orderBy("__name__")
      .limit(PAGE_SIZE);
    if (cursor) {
      const startRef = db.collection("conversations").doc(cursor);
      query = query.startAfter(await startRef.get());
    }

    const snap = await query.get();
    let processed = 0;
    let totalBytesRecounted = 0;

    for (const conv of snap.docs) {
      try {
        const stats = await recomputeConversation(conv.id);
        await conv.ref.set({ storage: stats }, { merge: true });
        processed += 1;
        totalBytesRecounted += stats.totalBytes;
      } catch (e) {
        logger.error("recomputeConversation failed", { id: conv.id, error: String(e) });
      }
    }

    const nextCursor = snap.docs.length === PAGE_SIZE ?
      snap.docs[snap.docs.length - 1].id :
      null;

    return {
      processed,
      totalBytesRecounted,
      nextCursor,
      done: nextCursor === null,
    };
  },
);

async function recomputeConversation(cid: string): Promise<{
  totalBytes: number;
  videoBytes: number;
  imageBytes: number;
  audioBytes: number;
  fileBytes: number;
  recountedAt: FirebaseFirestore.FieldValue;
}> {
  let total = 0;
  let video = 0;
  let image = 0;
  let audio = 0;
  let file = 0;

  // Постраничный скан message-документов: 1000 за страницу, без верхней
  // границы. Раньше стоял `limit(5000)` — в чатах с большим объёмом
  // вложений хвост сообщений не учитывался, но функция возвращала success.
  const MESSAGE_PAGE = 1000;
  const baseQuery = db
    .collection("conversations")
    .doc(cid)
    .collection("messages")
    .orderBy("__name__")
    .limit(MESSAGE_PAGE);

  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    const page: FirebaseFirestore.QuerySnapshot = lastDoc ?
      await baseQuery.startAfter(lastDoc).get() :
      await baseQuery.get();
    if (page.empty) break;

    for (const m of page.docs) {
      const data = m.data();
      const atts = (data.attachments ?? []) as Array<Record<string, unknown>>;
      for (const a of atts) {
        const size = Number(a.fileSizeBytes ?? a.size ?? 0);
        if (!Number.isFinite(size) || size <= 0) continue;
        total += size;
        const kind = String(a.kind ?? a.type ?? "").toLowerCase();
        if (kind === "video" || kind === "video_circle") {
          video += size;
        } else if (kind === "image" || kind === "photo") {
          image += size;
        } else if (kind === "audio" || kind === "voice") {
          audio += size;
        } else {
          file += size;
        }
      }
    }

    if (page.docs.length < MESSAGE_PAGE) break;
    lastDoc = page.docs[page.docs.length - 1];
  }

  return {
    totalBytes: total,
    videoBytes: video,
    imageBytes: image,
    audioBytes: audio,
    fileBytes: file,
    recountedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}
