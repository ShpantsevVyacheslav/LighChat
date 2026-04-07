import * as admin from "firebase-admin";
import type { DocumentData } from "firebase-admin/firestore";

/**
 * Нормализация participantIds из документа чата (массив строк или map ключей uid).
 */
export function participantIdsFromConversationData(
  data: DocumentData | undefined,
): string[] {
  if (!data) return [];
  const raw = data.participantIds;
  if (Array.isArray(raw)) {
    return raw.filter((x): x is string => typeof x === "string" && x.length > 0);
  }
  if (raw && typeof raw === "object") {
    return Object.keys(raw as Record<string, unknown>).filter(
      (k) => typeof k === "string" && k.length > 0,
    );
  }
  return [];
}

const BATCH_MAX = 450;

/**
 * Создаёт документы members для нового чата (идемпотентно через merge).
 */
export async function setMemberDocsForConversation(
  conversationId: string,
  participantIds: string[],
): Promise<void> {
  const db = admin.firestore();
  const ids = [...new Set(participantIds.filter(Boolean))];
  if (ids.length === 0) return;

  for (let i = 0; i < ids.length; i += BATCH_MAX) {
    const batch = db.batch();
    const slice = ids.slice(i, i + BATCH_MAX);
    for (const userId of slice) {
      const ref = db.doc(`conversations/${conversationId}/members/${userId}`);
      batch.set(
        ref,
        { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

/**
 * Приводит подколлекцию members в соответствие с participantIds (добавляет / удаляет).
 */
export async function syncMemberDocsForConversation(
  conversationId: string,
  participantIds: string[],
): Promise<void> {
  const db = admin.firestore();
  const colRef = db.collection(`conversations/${conversationId}/members`);
  const snap = await colRef.get();
  const existing = new Set(snap.docs.map((d) => d.id));
  const desired = new Set(participantIds.filter(Boolean));

  const toDelete = [...existing].filter((id) => !desired.has(id));
  const toSet = [...desired].filter((id) => !existing.has(id));

  type Op = { kind: "del" | "set"; id: string };
  const ops: Op[] = [
    ...toDelete.map((id) => ({ kind: "del" as const, id })),
    ...toSet.map((id) => ({ kind: "set" as const, id })),
  ];

  for (let i = 0; i < ops.length; i += BATCH_MAX) {
    const chunk = ops.slice(i, i + BATCH_MAX);
    const batch = db.batch();
    for (const op of chunk) {
      const ref = colRef.doc(op.id);
      if (op.kind === "del") {
        batch.delete(ref);
      } else {
        batch.set(
          ref,
          { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        );
      }
    }
    await batch.commit();
  }
}

/**
 * Удаляет всех members (при удалении чата; подколлекция не удаляется каскадно).
 */
export async function deleteAllMemberDocsForConversation(
  conversationId: string,
): Promise<void> {
  const db = admin.firestore();
  const colRef = db.collection(`conversations/${conversationId}/members`);
  const snap = await colRef.get();
  if (snap.empty) return;

  for (let i = 0; i < snap.docs.length; i += BATCH_MAX) {
    const batch = db.batch();
    snap.docs.slice(i, i + BATCH_MAX).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
}
