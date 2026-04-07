'use server';

import { FieldPath } from 'firebase-admin/firestore';
import type { DocumentData, QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { interpretAdminAccessError } from '@/lib/admin-access-errors';
import type { AdminChatStorageStatsResult, AdminChatStorageStatsRow } from '@/lib/types';

const PAGE = 800;

function parseCreatedAtMs(data: DocumentData): number | null {
  const c = data?.createdAt;
  if (c == null) return null;
  if (typeof c === 'string') {
    const t = Date.parse(c);
    return Number.isFinite(t) ? t : null;
  }
  if (typeof c === 'object' && c !== null && 'toDate' in c && typeof (c as { toDate: () => Date }).toDate === 'function') {
    try {
      return (c as { toDate: () => Date }).toDate().getTime();
    } catch {
      return null;
    }
  }
  return null;
}

function sumAttachmentsBytes(data: DocumentData): { bytes: number; missingSize: number } {
  const att = data?.attachments;
  if (!Array.isArray(att)) return { bytes: 0, missingSize: 0 };
  let bytes = 0;
  let missingSize = 0;
  for (const a of att) {
    if (!a || typeof a !== 'object') continue;
    const s = (a as { size?: unknown }).size;
    if (typeof s === 'number' && Number.isFinite(s) && s >= 0) bytes += s;
    else missingSize += 1;
  }
  return { bytes, missingSize };
}

function inDateRange(
  ms: number | null,
  fromMs: number | null,
  toMs: number | null,
): { ok: boolean; skipUndated: boolean } {
  if (fromMs == null && toMs == null) return { ok: true, skipUndated: false };
  if (ms == null) return { ok: false, skipUndated: true };
  if (fromMs != null && ms < fromMs) return { ok: false, skipUndated: false };
  if (toMs != null && ms > toMs) return { ok: false, skipUndated: false };
  return { ok: true, skipUndated: false };
}

async function forEachCollectionGroup(
  collectionId: string,
  visitor: (doc: QueryDocumentSnapshot) => void,
): Promise<void> {
  let last: QueryDocumentSnapshot | undefined;
  while (true) {
    let q = adminDb.collectionGroup(collectionId).orderBy(FieldPath.documentId()).limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    for (const d of snap.docs) visitor(d);
    last = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < PAGE) break;
  }
}

/**
 * Статистика объёма вложений по метаданным сообщений (поле attachments[].size).
 * Не ходит в Cloud Storage API; старые сообщения без size учитываются как «без размера».
 */
export async function fetchChatStorageStatsAction(input: {
  idToken: string;
  conversationIds?: string[] | null;
  createdAtFromIso?: string | null;
  createdAtToIso?: string | null;
}): Promise<AdminChatStorageStatsResult> {
  try {
    await assertAdminByIdToken(input.idToken);
  } catch (e) {
    return { ok: false, error: interpretAdminAccessError(e) };
  }

  const fromMs = input.createdAtFromIso?.trim() ? Date.parse(input.createdAtFromIso) : null;
  const toMs = input.createdAtToIso?.trim() ? Date.parse(input.createdAtToIso) : null;
  const fromOk = fromMs == null || Number.isFinite(fromMs);
  const toOk = toMs == null || Number.isFinite(toMs);
  if (!fromOk || !toOk) {
    return { ok: false, error: 'Некорректный диапазон дат' };
  }

  const convFilter =
    input.conversationIds && input.conversationIds.length > 0
      ? new Set(input.conversationIds.map((id) => id.trim()).filter(Boolean))
      : null;

  const convSnap = await adminDb.collection('conversations').get();
  const convMeta = new Map<string, { isGroup: boolean; title: string }>();
  for (const d of convSnap.docs) {
    const data = d.data();
    const isGroup = Boolean(data?.isGroup);
    const title =
      (typeof data?.name === 'string' && data.name.trim()) ||
      (isGroup ? `Группа ${d.id.slice(0, 8)}…` : `Чат ${d.id.slice(0, 8)}…`);
    convMeta.set(d.id, { isGroup, title });
  }

  const perConv = new Map<string, { bytes: number; messageDocs: number }>();
  const ensureConv = (id: string) => {
    let e = perConv.get(id);
    if (!e) {
      e = { bytes: 0, messageDocs: 0 };
      perConv.set(id, e);
    }
    return e;
  };

  let groupChatsBytes = 0;
  let directChatsBytes = 0;
  let meetingsBytes = 0;
  let scannedMainMessageDocs = 0;
  let scannedThreadDocs = 0;
  let scannedMeetingMessageDocs = 0;
  let skippedUndatedInRange = 0;
  let attachmentsMissingSize = 0;

  const mainConvRe = /^conversations\/([^/]+)\/messages\/[^/]+$/;
  const meetingRe = /^meetings\/([^/]+)\/messages\/[^/]+$/;
  const threadConvRe = /^conversations\/([^/]+)\/messages\/[^/]+\/thread\/[^/]+$/;

  const processDoc = (
    doc: QueryDocumentSnapshot,
    pathRe: RegExp,
    kind: 'main' | 'thread' | 'meeting',
  ) => {
    const path = doc.ref.path;
    const m = pathRe.exec(path);
    if (!m) return;

    const data = doc.data();
    const createdMs = parseCreatedAtMs(data);
    const { ok, skipUndated } = inDateRange(createdMs, fromMs, toMs);
    if (skipUndated) skippedUndatedInRange += 1;
    if (!ok) return;

    const { bytes, missingSize } = sumAttachmentsBytes(data);
    attachmentsMissingSize += missingSize;
    const hasAttachments = Array.isArray(data?.attachments) && data.attachments.length > 0;

    if (kind === 'meeting') {
      meetingsBytes += bytes;
      scannedMeetingMessageDocs += 1;
      return;
    }

    const convId = m[1];
    if (convFilter && !convFilter.has(convId)) return;

    const entry = ensureConv(convId);
    entry.bytes += bytes;
    if (hasAttachments) entry.messageDocs += 1;

    if (kind === 'thread') scannedThreadDocs += 1;
    else scannedMainMessageDocs += 1;
  };

  await forEachCollectionGroup('messages', (doc) => {
    const path = doc.ref.path;
    if (mainConvRe.test(path)) processDoc(doc, mainConvRe, 'main');
    else if (meetingRe.test(path)) processDoc(doc, meetingRe, 'meeting');
  });

  await forEachCollectionGroup('thread', (doc) => {
    processDoc(doc, threadConvRe, 'thread');
  });

  const chatTotalBytes = Array.from(perConv.values()).reduce((s, x) => s + x.bytes, 0);
  /** meetings не входят в разрез личные/групповые */
  for (const [id, { bytes }] of perConv) {
    const meta = convMeta.get(id);
    if (meta?.isGroup) groupChatsBytes += bytes;
    else directChatsBytes += bytes;
  }

  const byConversation: AdminChatStorageStatsRow[] = Array.from(perConv.entries())
    .map(([conversationId, v]) => {
      const meta = convMeta.get(conversationId);
      return {
        conversationId,
        title: meta?.title ?? conversationId,
        isGroup: meta?.isGroup ?? false,
        bytes: v.bytes,
        messageDocs: v.messageDocs,
      };
    })
    .filter((row) => row.bytes > 0 || row.messageDocs > 0)
    .sort((a, b) => b.bytes - a.bytes);

  return {
    ok: true,
    chatTotalBytes,
    groupChatsBytes,
    directChatsBytes,
    meetingsBytes,
    scannedMainMessageDocs,
    scannedThreadDocs,
    scannedMeetingMessageDocs,
    skippedUndatedInRange,
    byConversation,
    attachmentsMissingSize,
  };
}
