import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import {
  evictMessageAttachments,
  loadStoragePolicy,
} from "../../lib/storage-quota-enforcement";

const db = admin.firestore();

/**
 * Ежедневно удаляет вложения старше `platformSettings/main.storage.mediaRetentionDays`.
 *
 *  - Если `mediaRetentionDays` не задан или `enforcementMode === 'off'` —
 *    функция ничего не делает, только логирует skip.
 *  - В режиме `dry_run` отчитывается «что бы удалили» без реальных операций.
 *  - В режиме `enforce` удаляет объекты GCS и зачищает поле `attachments`.
 *
 * Лимит за прогон: 5000 сообщений (`MAX_DOCS_PER_RUN`). Если очередь
 * больше — добьём за следующий запуск.
 */
const MAX_DOCS_PER_RUN = 5000;
const PAGE = 500;

export const mediaRetentionCleanupDaily = onSchedule(
  {
    schedule: "0 4 * * *",
    timeZone: "Europe/Moscow",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const policy = await loadStoragePolicy(db);
    const mode: "dry_run" | "enforce" | "off" =
      policy.enforcementMode ?? "off";
    if (mode === "off") {
      logger.info("[mediaRetentionCleanupDaily] skipped: enforcementMode=off");
      return;
    }
    if (policy.mediaRetentionDays == null || policy.mediaRetentionDays <= 0) {
      logger.info("[mediaRetentionCleanupDaily] skipped: no retention configured");
      return;
    }

    const cutoffMs = Date.now() - policy.mediaRetentionDays * 24 * 60 * 60 * 1000;
    const cutoffIso = new Date(cutoffMs).toISOString();
    const bucket = admin.storage().bucket();

    let scanned = 0;
    let evictedDocs = 0;
    let freedBytes = 0;

    // collectionGroup("messages") покрывает и треды (subcollection с тем же
    // именем). Старые вложения и в основном чате, и в тредах удалятся
    // одинаково.
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    while (scanned < MAX_DOCS_PER_RUN) {
      const base = db
        .collectionGroup("messages")
        .where("createdAt", "<", cutoffIso)
        .orderBy("createdAt", "asc")
        .limit(PAGE);
      const page: admin.firestore.QuerySnapshot = lastDoc ?
        await base.startAfter(lastDoc).get() :
        await base.get();
      if (page.empty) break;

      for (const doc of page.docs) {
        scanned += 1;
        // collectionGroup("messages") поймает и meetings/{mid}/messages —
        // там тоже могут быть вложения, выселяем единообразно.
        const freed = await evictMessageAttachments({
          bucket,
          messageRef: doc.ref,
          reason: "retention",
          mode: mode as "dry_run" | "enforce",
        });
        if (freed > 0) {
          evictedDocs += 1;
          freedBytes += freed;
        }
        if (scanned >= MAX_DOCS_PER_RUN) break;
      }

      if (page.docs.length < PAGE) break;
      lastDoc = page.docs[page.docs.length - 1];
    }

    logger.info("[mediaRetentionCleanupDaily] done", {
      cutoffIso,
      mode,
      scanned,
      evictedDocs,
      freedBytes,
    });
  },
);
