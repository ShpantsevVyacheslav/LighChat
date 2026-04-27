import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Извлекает путь объекта в бакете из типичного Firebase download URL
 * (`firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}`).
 */
export function storageObjectPathFromDownloadUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (!u.hostname.includes("firebasestorage.googleapis.com")) return null;
    const idx = u.pathname.indexOf("/o/");
    if (idx === -1) return null;
    const encoded = u.pathname.slice(idx + 3).split("/").filter(Boolean).join("/");
    if (!encoded) return null;
    return decodeURIComponent(encoded.replace(/\+/g, " "));
  } catch {
    return null;
  }
}

function isAllowedChatStoragePath(conversationId: string, objectPath: string): boolean {
  const p = objectPath.replace(/^\/+/, "");
  return (
    p.startsWith(`chat-attachments/${conversationId}/`) ||
    p.startsWith(`chat-attachments-enc/${conversationId}/`)
  );
}

function collectPlaintextAttachmentPaths(
  conversationId: string,
  data: Record<string, unknown>
): string[] {
  const out = new Set<string>();
  const attachments = data.attachments;
  if (!Array.isArray(attachments)) return [];
  for (const raw of attachments) {
    if (!raw || typeof raw !== "object") continue;
    const url = (raw as Record<string, unknown>).url;
    if (typeof url !== "string" || !url.trim()) continue;
    const path = storageObjectPathFromDownloadUrl(url.trim());
    if (path && isAllowedChatStoragePath(conversationId, path)) {
      out.add(path);
    }
  }
  return [...out];
}

function collectE2eeEncPrefixes(
  conversationId: string,
  messageDocId: string,
  data: Record<string, unknown>
): string[] {
  const e2ee = data.e2ee;
  if (!e2ee || typeof e2ee !== "object") return [];
  const version = (e2ee as Record<string, unknown>).protocolVersion;
  if (typeof version !== "string" || !version.startsWith("v2-")) return [];
  const att = (e2ee as Record<string, unknown>).attachments;
  if (!Array.isArray(att)) return [];
  const prefixes: string[] = [];
  for (const item of att) {
    if (!item || typeof item !== "object") continue;
    const fileId = (item as Record<string, unknown>).fileId;
    if (typeof fileId !== "string" || !fileId.trim()) continue;
    const fid = fileId.trim();
    prefixes.push(`chat-attachments-enc/${conversationId}/${messageDocId}/${fid}/`);
  }
  return prefixes;
}

/**
 * Удаляет файлы вложений сообщения из Storage после удаления документа Firestore (TTL и т.д.).
 * Только пути `chat-attachments/{cid}/…` и `chat-attachments-enc/{cid}/…`.
 */
export async function deleteChatMessageStorageObjects(opts: {
  conversationId: string;
  /** id удалённого документа сообщения (основной ленты или thread). */
  messageDocId: string;
  messageData: Record<string, unknown>;
}): Promise<void> {
  const { conversationId, messageDocId, messageData } = opts;
  const bucket = admin.storage().bucket();
  const normPrefix = `chat-attachments/${conversationId}/norm/${messageDocId}/`;

  try {
    await bucket.deleteFiles({ prefix: normPrefix });
    logger.log("[chat-delete-storage] removed norm prefix", { prefix: normPrefix });
  } catch (e) {
    logger.warn("[chat-delete-storage] norm prefix delete", { prefix: normPrefix, err: String(e) });
  }

  const paths = collectPlaintextAttachmentPaths(conversationId, messageData);
  for (const p of paths) {
    try {
      await bucket.file(p).delete({ ignoreNotFound: true });
    } catch (e) {
      logger.warn("[chat-delete-storage] attachment file", { path: p, err: String(e) });
    }
  }

  const encPrefixes = collectE2eeEncPrefixes(conversationId, messageDocId, messageData);
  for (const prefix of encPrefixes) {
    try {
      await bucket.deleteFiles({ prefix });
      logger.log("[chat-delete-storage] removed e2ee prefix", { prefix });
    } catch (e) {
      logger.warn("[chat-delete-storage] e2ee prefix", { prefix, err: String(e) });
    }
  }
}
