import type { ReplyContext } from '@/lib/types';

export const CHAT_MESSAGE_DRAFT_CHANGED_EVENT = 'lighchat:chatMessageDraftChanged';

const STORAGE_PREFIX = 'lighchat:chatDrafts:v1:';
const MAX_HTML_CHARS = 48_000;

export type StoredChatMessageDraft = {
  html: string;
  replyTo: ReplyContext | null;
  updatedAt: number;
};

export function chatDraftStorageKey(userId: string) {
  return `${STORAGE_PREFIX}${userId}`;
}

function keyForUser(userId: string) {
  return chatDraftStorageKey(userId);
}

function readMap(userId: string): Record<string, StoredChatMessageDraft> {
  if (typeof window === 'undefined') return {};
  try {
    const raw = localStorage.getItem(keyForUser(userId));
    if (!raw) return {};
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object') return {};
    return parsed as Record<string, StoredChatMessageDraft>;
  } catch {
    return {};
  }
}

function writeMap(userId: string, map: Record<string, StoredChatMessageDraft>) {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(keyForUser(userId), JSON.stringify(map));
  } catch (e) {
    console.warn('[LighChat] chat draft save failed', e);
  }
}

function notifyDraftChanged(scopeKey: string) {
  if (typeof window === 'undefined') return;
  const conversationId = scopeKey.startsWith('t:') ? scopeKey.split(':')[1] ?? scopeKey : scopeKey;
  window.dispatchEvent(
    new CustomEvent(CHAT_MESSAGE_DRAFT_CHANGED_EVENT, { detail: { scopeKey, conversationId } })
  );
}

/** Плоский превью для списка чатов и проверки «пусто ли». */
export function chatDraftPlainFromHtml(html: string): string {
  if (!html) return '';
  return html
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function getChatMessageDraft(userId: string, scopeKey: string): StoredChatMessageDraft | null {
  const map = readMap(userId);
  const d = map[scopeKey];
  if (!d || typeof d.html !== 'string') return null;
  return d;
}

export function saveChatMessageDraft(userId: string, scopeKey: string, draft: StoredChatMessageDraft): void {
  const map = readMap(userId);
  let html = draft.html;
  if (html.length > MAX_HTML_CHARS) html = html.slice(0, MAX_HTML_CHARS);
  map[scopeKey] = { ...draft, html };
  writeMap(userId, map);
  notifyDraftChanged(scopeKey);
}

export function clearChatMessageDraft(userId: string, scopeKey: string): void {
  const map = readMap(userId);
  if (!(scopeKey in map)) return;
  delete map[scopeKey];
  writeMap(userId, map);
  notifyDraftChanged(scopeKey);
}

/** Есть ли непустой основной черновик по беседе (без учёта треда `t:…`). */
export function getMainChatDraftForList(userId: string, conversationId: string): StoredChatMessageDraft | null {
  return getChatMessageDraft(userId, conversationId);
}
