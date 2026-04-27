import * as admin from "firebase-admin";

const db = admin.firestore();

export function blockedIdsList(data: admin.firestore.DocumentData | undefined): string[] {
  const raw = data?.blockedUserIds;
  if (!Array.isArray(raw)) return [];
  return [...new Set(raw.filter((x): x is string => typeof x === "string" && x.length > 0))];
}

/**
 * Держит `users/{blockerId}/outgoingBlocks/{blockedUid}` в соответствии с `blockedUserIds`
 * (пустые документы-маркеры). Нужно для правил Firestore: `userBlocks` проверяет `exists`
 * на этом пути, чтобы заблокированный мог выполнить `exists/get` в правилах без чтения
 * полного профиля блокирующего (которое запрещено правилом users/*).
 */
export async function reconcileOutgoingBlocksForUser(
  blockerId: string,
  userData: admin.firestore.DocumentData | undefined,
): Promise<void> {
  const desired = blockedIdsList(userData);
  const desiredSet = new Set(desired);
  const base = db.collection("users").doc(blockerId).collection("outgoingBlocks");
  const snap = await base.get();

  let batch = db.batch();
  let ops = 0;
  const flush = async () => {
    if (ops === 0) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const d of snap.docs) {
    if (!desiredSet.has(d.id)) {
      batch.delete(d.ref);
      ops++;
      if (ops >= 450) await flush();
    }
  }

  const existing = new Set(snap.docs.map((d) => d.id));
  for (const id of desired) {
    if (!existing.has(id)) {
      batch.set(base.doc(id), { v: 1 }, { merge: true });
      ops++;
      if (ops >= 450) await flush();
    }
  }

  await flush();
}
