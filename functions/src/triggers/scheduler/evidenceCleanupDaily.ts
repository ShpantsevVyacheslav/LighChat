import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Ежедневно удаляет evidence-вложения у resolved-жалоб старше 90 дней
 * после `reviewedAt`. Evidence-копии живут в Storage по пути
 * `moderation-evidence/{reporterUid}/{nonce}/...` и хранят
 * расшифрованную копию E2EE-вложений; их нужно стирать, чтобы не
 * накапливать персональные данные после разрешения жалобы.
 *
 * Не трогаем сам документ `messageReports/{id}` — лог жалоб остаётся
 * для аудита; зачищаем поля `evidenceAttachments` и `evidenceNonce` +
 * Storage-объекты.
 */

const TTL_DAYS = 90;
const PAGE = 200;

const db = admin.firestore();

function isResolvedStatus(s: unknown): s is "action_taken" | "dismissed" {
  return s === "action_taken" || s === "dismissed";
}

function parseObjectPathFromDownloadUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (!u.hostname.endsWith("firebasestorage.googleapis.com")) return null;
    const segs = u.pathname.split("/").filter(Boolean);
    const oIdx = segs.indexOf("o");
    if (oIdx < 0 || oIdx >= segs.length - 1) return null;
    const objectPath = decodeURIComponent(segs.slice(oIdx + 1).join("/"));
    if (!objectPath.startsWith("moderation-evidence/")) return null;
    return objectPath;
  } catch {
    return null;
  }
}

export const evidenceCleanupDaily = onSchedule(
  {
    schedule: "0 5 * * *",
    timeZone: "Europe/Moscow",
    timeoutSeconds: 540,
    memory: "256MiB",
  },
  async () => {
    const cutoffMs = Date.now() - TTL_DAYS * 24 * 60 * 60 * 1000;
    const cutoffIso = new Date(cutoffMs).toISOString();
    const bucket = admin.storage().bucket();

    let scanned = 0;
    let cleared = 0;
    let deletedObjects = 0;
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

    for (;;) {
      const base = db
        .collection("messageReports")
        .where("reviewedAt", "<=", cutoffIso)
        .orderBy("reviewedAt", "asc")
        .limit(PAGE);
      const page: admin.firestore.QuerySnapshot = lastDoc ?
        await base.startAfter(lastDoc).get() :
        await base.get();
      if (page.empty) break;

      for (const doc of page.docs) {
        scanned += 1;
        const data = doc.data() ?? {};
        if (!isResolvedStatus(data.status)) continue;
        const evidence = Array.isArray(data.evidenceAttachments) ?
          data.evidenceAttachments :
          [];
        if (evidence.length === 0 && !data.evidenceNonce) continue;

        // Удаляем каждый Storage-объект, прежде чем чистить поля.
        for (const att of evidence) {
          if (!att || typeof att !== "object") continue;
          const url = (att as { url?: unknown }).url;
          if (typeof url !== "string") continue;
          const objectPath = parseObjectPathFromDownloadUrl(url);
          if (!objectPath) continue;
          try {
            await bucket.file(objectPath).delete({ ignoreNotFound: true });
            deletedObjects += 1;
          } catch (e) {
            logger.warn("[evidenceCleanupDaily] failed to delete evidence object", {
              objectPath,
              error: String(e),
            });
          }
        }

        await doc.ref.update({
          evidenceAttachments: admin.firestore.FieldValue.delete(),
          evidenceNonce: admin.firestore.FieldValue.delete(),
          evidenceClearedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        cleared += 1;
      }

      if (page.docs.length < PAGE) break;
      lastDoc = page.docs[page.docs.length - 1];
    }

    logger.info("[evidenceCleanupDaily] done", {
      cutoffIso,
      ttlDays: TTL_DAYS,
      scanned,
      cleared,
      deletedObjects,
    });
  },
);
