import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import {
  decrementConversationStorage,
  evictConversationUntilUnder,
  loadStoragePolicy,
} from "../../lib/storage-quota-enforcement";

const db = admin.firestore();

/**
 * Ежедневный enforcement квот хранилища:
 *
 *  1. Per-conversation: для каждого чата с `storageQuotaBytes` —
 *     если `storage.totalBytes > quota`, выселяем старые вложения, пока
 *     не упадём ниже квоты.
 *  2. Global: если суммарно `storage.totalBytes` по всем чатам больше
 *     `platformSettings.totalQuotaGb * GiB`, выселяем по чатам, начиная
 *     с самых «жирных».
 *
 * Per-user квота в этой версии не реализована — это требует отдельного
 * счётчика `users/{uid}.storageUsedBytes` (TODO).
 */

const GIB = 1024 ** 3;

type ConvDoc = {
  id: string;
  storageQuotaBytes: number | null;
  totalBytes: number;
};

async function loadConversationStorage(
  database: admin.firestore.Firestore,
): Promise<ConvDoc[]> {
  const out: ConvDoc[] = [];
  const PAGE = 500;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    const base = database.collection("conversations").orderBy("__name__").limit(PAGE);
    const page: admin.firestore.QuerySnapshot = lastDoc ?
      await base.startAfter(lastDoc).get() :
      await base.get();
    if (page.empty) break;
    for (const doc of page.docs) {
      const d = doc.data();
      const storage = (d.storage ?? {}) as { totalBytes?: unknown };
      const total = Number(storage.totalBytes ?? 0);
      out.push({
        id: doc.id,
        storageQuotaBytes:
          typeof d.storageQuotaBytes === "number" ? d.storageQuotaBytes : null,
        totalBytes: Number.isFinite(total) && total > 0 ? total : 0,
      });
    }
    if (page.docs.length < PAGE) break;
    lastDoc = page.docs[page.docs.length - 1];
  }
  return out;
}

export const enforceStorageQuotasDaily = onSchedule(
  {
    schedule: "30 4 * * *",
    timeZone: "Europe/Moscow",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const policy = await loadStoragePolicy(db);
    const mode: "dry_run" | "enforce" | "off" =
      policy.enforcementMode ?? "off";
    if (mode === "off") {
      logger.info("[enforceStorageQuotasDaily] skipped: enforcementMode=off");
      return;
    }

    const bucket = admin.storage().bucket();
    const conversations = await loadConversationStorage(db);

    let perConvEvicted = 0;
    let perConvFreed = 0;
    for (const conv of conversations) {
      if (conv.storageQuotaBytes == null || conv.storageQuotaBytes <= 0) continue;
      if (conv.totalBytes <= conv.storageQuotaBytes) continue;

      const result = await evictConversationUntilUnder({
        db,
        bucket,
        conversationId: conv.id,
        startBytes: conv.totalBytes,
        targetBytes: conv.storageQuotaBytes,
        mode,
        reason: "quota_conversation",
      });
      perConvEvicted += result.evictedDocs;
      perConvFreed += result.freedBytes;
      conv.totalBytes -= result.freedBytes;
      if (mode === "enforce" && result.freedBytes > 0) {
        await decrementConversationStorage({
          db,
          conversationId: conv.id,
          freedBytes: result.freedBytes,
        });
      }
    }

    // Global quota: после per-conversation passes пересчитываем суммарный
    // объём по уже скорректированным totalBytes.
    let globalEvicted = 0;
    let globalFreed = 0;
    if (policy.totalQuotaGb && policy.totalQuotaGb > 0) {
      const globalLimit = policy.totalQuotaGb * GIB;
      let globalUsed = conversations.reduce((s, c) => s + c.totalBytes, 0);
      if (globalUsed > globalLimit) {
        // Сначала бьём по «жирнякам»: сортируем десцендентно по
        // totalBytes, режем верх до тех пор, пока сумма не упадёт.
        const sorted = [...conversations].sort((a, b) => b.totalBytes - a.totalBytes);
        for (const conv of sorted) {
          if (globalUsed <= globalLimit) break;
          if (conv.totalBytes <= 0) continue;
          const overflowToTrim = Math.max(0, globalUsed - globalLimit);
          const target = Math.max(0, conv.totalBytes - overflowToTrim);
          const result = await evictConversationUntilUnder({
            db,
            bucket,
            conversationId: conv.id,
            startBytes: conv.totalBytes,
            targetBytes: target,
            mode: mode as "dry_run" | "enforce",
            reason: "quota_total",
          });
          globalEvicted += result.evictedDocs;
          globalFreed += result.freedBytes;
          globalUsed -= result.freedBytes;
          conv.totalBytes -= result.freedBytes;
          if (mode === "enforce" && result.freedBytes > 0) {
            await decrementConversationStorage({
              db,
              conversationId: conv.id,
              freedBytes: result.freedBytes,
            });
          }
        }
      }
    }

    logger.info("[enforceStorageQuotasDaily] done", {
      mode,
      perConvEvicted,
      perConvFreed,
      globalEvicted,
      globalFreed,
      totalQuotaGb: policy.totalQuotaGb,
    });
  },
);
