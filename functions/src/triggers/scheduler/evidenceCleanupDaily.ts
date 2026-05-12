import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Ежедневная очистка evidence-вложений в жалобах. Evidence — это
 * расшифрованная копия E2EE-вложений в Storage-зоне
 * `moderation-evidence/{reporterUid}/{nonce}/...`. Хранить такие
 * персональные данные дольше необходимого — GDPR/UX-риск.
 *
 * Две стратегии очистки:
 *   1. **Resolved TTL** (90 дней после `reviewedAt`) — для жалоб со
 *      статусом action_taken / dismissed.
 *   2. **Absolute TTL** (180 дней после `createdAt`) — для любых жалоб,
 *      включая pending. Защищает от случая, когда модератор «забил»
 *      на pending-жалобу: evidence не должен жить бессрочно.
 *
 * Сам документ `messageReports/{id}` остаётся для аудита; зачищаем
 * только evidence-поля + GCS-объекты.
 */

const RESOLVED_TTL_DAYS = 90;
const ABSOLUTE_TTL_DAYS = 180;
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

type ClearReason = "resolved_ttl" | "absolute_ttl";

async function clearEvidenceForDoc(
  doc: admin.firestore.QueryDocumentSnapshot,
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  reason: ClearReason,
): Promise<{ cleared: boolean; deletedObjects: number }> {
  const data = doc.data() ?? {};
  const evidence = Array.isArray(data.evidenceAttachments) ?
    data.evidenceAttachments :
    [];
  if (evidence.length === 0 && !data.evidenceNonce) {
    return { cleared: false, deletedObjects: 0 };
  }

  let deletedObjects = 0;
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
        reason,
      });
    }
  }

  await doc.ref.update({
    evidenceAttachments: admin.firestore.FieldValue.delete(),
    evidenceNonce: admin.firestore.FieldValue.delete(),
    evidenceClearedAt: admin.firestore.FieldValue.serverTimestamp(),
    evidenceClearedReason: reason,
  });
  return { cleared: true, deletedObjects };
}

async function runPass(
  filter: (doc: admin.firestore.QueryDocumentSnapshot) => boolean,
  baseQuery: admin.firestore.Query,
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  reason: ClearReason,
): Promise<{ scanned: number; cleared: number; deletedObjects: number }> {
  let scanned = 0;
  let cleared = 0;
  let deletedObjects = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    const page: admin.firestore.QuerySnapshot = lastDoc ?
      await baseQuery.startAfter(lastDoc).get() :
      await baseQuery.get();
    if (page.empty) break;
    for (const doc of page.docs) {
      scanned += 1;
      if (!filter(doc)) continue;
      const res = await clearEvidenceForDoc(doc, bucket, reason);
      if (res.cleared) {
        cleared += 1;
        deletedObjects += res.deletedObjects;
      }
    }
    if (page.docs.length < PAGE) break;
    lastDoc = page.docs[page.docs.length - 1];
  }
  return { scanned, cleared, deletedObjects };
}

export const evidenceCleanupDaily = onSchedule(
  {
    schedule: "0 5 * * *",
    timeZone: "Europe/Moscow",
    timeoutSeconds: 540,
    memory: "256MiB",
  },
  async () => {
    const now = Date.now();
    const resolvedCutoff = new Date(now - RESOLVED_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString();
    const absoluteCutoff = new Date(now - ABSOLUTE_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString();
    const bucket = admin.storage().bucket();

    // 1) Resolved TTL — для action_taken/dismissed жалоб.
    const resolvedPass = await runPass(
      (doc) => isResolvedStatus(doc.data()?.status),
      db
        .collection("messageReports")
        .where("reviewedAt", "<=", resolvedCutoff)
        .orderBy("reviewedAt", "asc")
        .limit(PAGE),
      bucket,
      "resolved_ttl",
    );

    // 2) Absolute TTL — для любого статуса. Защищает от
    //    «забытых» pending-жалоб, у которых нет reviewedAt и они
    //    не попадают в первый pass.
    const absolutePass = await runPass(
      () => true,
      db
        .collection("messageReports")
        .where("createdAt", "<=", absoluteCutoff)
        .orderBy("createdAt", "asc")
        .limit(PAGE),
      bucket,
      "absolute_ttl",
    );

    logger.info("[evidenceCleanupDaily] done", {
      resolvedCutoff,
      absoluteCutoff,
      resolvedTtlDays: RESOLVED_TTL_DAYS,
      absoluteTtlDays: ABSOLUTE_TTL_DAYS,
      resolved: resolvedPass,
      absolute: absolutePass,
    });
  },
);
