import * as admin from "firebase-admin";

export const EXPIRED_DISAPPEARING_MESSAGES_BATCH_LIMIT = 200;

export function isConversationMessageDocPath(path: string): boolean {
  const parts = path.split("/");
  return parts.length === 4 && parts[0] === "conversations" && parts[2] === "messages";
}

export function isConversationThreadMessageDocPath(path: string): boolean {
  const parts = path.split("/");
  return (
    parts.length === 6 &&
    parts[0] === "conversations" &&
    parts[2] === "messages" &&
    parts[4] === "thread"
  );
}

export async function deleteExpiredDisappearingMessagesBatch(opts: {
  db: admin.firestore.Firestore;
  now: admin.firestore.Timestamp;
  collectionGroupId: "messages" | "thread";
  pathGuard: (path: string) => boolean;
  limit?: number;
}): Promise<number> {
  const snap = await opts.db
    .collectionGroup(opts.collectionGroupId)
    .where("expireAt", "<=", opts.now)
    .limit(opts.limit ?? EXPIRED_DISAPPEARING_MESSAGES_BATCH_LIMIT)
    .get();

  const docs = snap.docs.filter((d) => opts.pathGuard(d.ref.path));
  if (docs.length === 0) return 0;

  const batch = opts.db.batch();
  for (const d of docs) {
    batch.delete(d.ref);
  }
  await batch.commit();
  return docs.length;
}
