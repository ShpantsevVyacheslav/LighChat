'use client';

import { doc, runTransaction, updateDoc, increment, writeBatch, type Firestore } from 'firebase/firestore';
import type { ChatAttachment, ChatMessage, User, ReplyContext } from '@/lib/types';
import { isAttachmentLikelyIosStickerCutout } from '@/lib/ios-sticker-detect';
import { isGridGalleryAttachment, isGridGalleryVideo } from '@/components/chat/attachment-visual';

// Track messages currently being marked as read to prevent double-decrementing counters.
// We no longer clear this with setTimeout to prevent race conditions on slow connections.
const inFlightReadIds = new Set<string>();

/**
 * Checks if a string consists only of emojis.
 */
export const isOnlyEmojis = (text: string) => {
    if (!text) return false;
    const cleaned = text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    if (!cleaned) return false;
    const emojiRegex = /^(\p{Extended_Pictographic}|\p{Emoji_Component}|\u200d|\ufe0f|\s)+$/u;
    return emojiRegex.test(cleaned);
};

/**
 * Generates a preview object for replies or pinned messages.
 * @param decryptedPlaintextByMessageId — расшифрованный HTML для E2E-сообщений (ключ — id сообщения).
 */
export const getReplyPreview = (
    message: ChatMessage,
    allUsers: User[],
    decryptedPlaintextByMessageId?: Record<string, string>
): ReplyContext => {
    const sender = allUsers.find(u => u.id === message.senderId);
    const senderName = sender?.name || 'Участник';
    
    let text = '';
    let mediaPreviewUrl = null;
    let mediaType: ReplyContext['mediaType'] = null;

    const decryptedHtml = decryptedPlaintextByMessageId?.[message.id];
    if (message.e2ee?.ciphertext && decryptedHtml) {
        text = decryptedHtml.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    } else if (message.text) {
        text = message.text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    }

    if (message.attachments && message.attachments.length > 0) {
        const att = message.attachments[0];
        const isSticker =
            att.name.startsWith('sticker_') || att.type === 'image/svg+xml' || isAttachmentLikelyIosStickerCutout(att);
        const isGifInline = att.name.startsWith('gif_');
        const isVideoCircle = att.name.startsWith('video-circle_');
        const isVideo = att.type.startsWith('video/');
        const isImage = att.type.startsWith('image/');

        if (!text) {
            if (isSticker) text = "Стикер";
            else if (isGifInline) text = "GIF";
            else if (isVideoCircle) text = "Кружок";
            else if (isVideo) text = "Видео";
            else if (isImage) text = "Фотография";
            else text = "Файл";
        }

        mediaPreviewUrl = att.url;
        if (isSticker) mediaType = 'sticker';
        else if (isGifInline) mediaType = 'image';
        else if (isVideoCircle) mediaType = 'video-circle';
        else if (isVideo) mediaType = 'video';
        else if (isImage) mediaType = 'image';
        else mediaType = 'file';
    }

    if (!text) text = "Сообщение";

    return {
        messageId: message.id,
        senderName,
        text,
        mediaPreviewUrl,
        mediaType
    };
};

/**
 * Generates an update object for unread counts for all participants except the sender.
 */
export const getUnreadIncrementUpdate = (participantIds: string[], senderId: string, value: number = 1) => {
    const updates: Record<string, any> = {};
    participantIds.forEach(id => {
        if (id !== senderId) {
            updates[`unreadCounts.${id}`] = increment(value);
        }
    });
    return updates;
};

/**
 * Marks specific messages as read and decrements the conversation counter.
 * Uses strict in-flight tracking to prevent negative counters from race conditions.
 */
export async function markMessagesAsRead(
    firestore: Firestore,
    conversationId: string,
    userId: string,
    messageIds: string[],
    isThread: boolean = false,
    threadParentId?: string
) {
    if (!firestore || !conversationId || !userId || messageIds.length === 0) return;

    // Filter out IDs that are already being processed in THIS session
    const filteredIds = messageIds.filter(id => !inFlightReadIds.has(id));
    if (filteredIds.length === 0) return;

    // Mark these IDs as in-flight IMMEDIATELY
    filteredIds.forEach(id => inFlightReadIds.add(id));

    const convRef = doc(firestore, 'conversations', conversationId);
    const now = new Date().toISOString();
    
    try {
        const batch = writeBatch(firestore);
        
        filteredIds.forEach(id => {
            const path = isThread && threadParentId
                ? `conversations/${conversationId}/messages/${threadParentId}/thread/${id}`
                : `conversations/${conversationId}/messages/${id}`;
            const msgRef = doc(firestore, path);
            batch.update(msgRef, { readAt: now });
        });

        const counterField = isThread ? `unreadThreadCounts.${userId}` : `unreadCounts.${userId}`;
        
        // Safety: ensure we are decrementing based on filtered IDs
        batch.update(convRef, {
            [counterField]: increment(-filteredIds.length)
        });

        if (isThread && threadParentId) {
            const parentRef = doc(firestore, `conversations/${conversationId}/messages`, threadParentId);
            batch.update(parentRef, {
                [`unreadThreadCounts.${userId}`]: increment(-filteredIds.length)
            });
        }

        await batch.commit();
        // We keep IDs in inFlightReadIds until page refresh to be 100% sure we don't re-read them
        // if onSnapshot is slow to update local state.
    } catch (e) {
        console.error("[ChatUtils] Failed to mark messages as read:", e);
        filteredIds.forEach(id => inFlightReadIds.delete(id));
        throw e;
    }
}

/** Пакетная отметка (несколько вызовов {@link markMessagesAsRead} по кускам, лимит операций в batch). */
export async function markManyMessagesAsRead(
    firestore: Firestore,
    conversationId: string,
    userId: string,
    messageIds: string[],
    isThread: boolean = false,
    threadParentId?: string
) {
    const CHUNK = 200;
    for (let i = 0; i < messageIds.length; i += CHUNK) {
        await markMessagesAsRead(
            firestore,
            conversationId,
            userId,
            messageIds.slice(i, i + CHUNK),
            isThread,
            threadParentId
        );
    }
}

/**
 * Resets the unread counter for a specific conversation.
 */
export async function markConversationAsRead(
    firestore: Firestore, 
    conversationId: string, 
    userId: string
) {
    if (!firestore || !conversationId || !userId) return;
    
    const convRef = doc(firestore, 'conversations', conversationId);
    try {
        await updateDoc(convRef, {
            [`unreadCounts.${userId}`]: 0,
            [`unreadThreadCounts.${userId}`]: 0
        });
    } catch (e) {
        console.error("[ChatUtils] Failed to mark as read:", e);
    }
}

/**
 * Сброс unread счётчиков ветки без проставления `readAt` (когда глобально скрыты read receipts).
 */
export async function markThreadMessagesSeenWithoutReadReceipt(
    firestore: Firestore,
    conversationId: string,
    userId: string,
    threadParentId: string,
    unreadCount: number
) {
    if (!firestore || !conversationId || !userId || !threadParentId) return;
    if (!Number.isFinite(unreadCount) || unreadCount <= 0) return;
    const normalizedCount = Math.max(0, Math.trunc(unreadCount));
    if (normalizedCount <= 0) return;

    const convRef = doc(firestore, 'conversations', conversationId);
    const parentRef = doc(firestore, `conversations/${conversationId}/messages`, threadParentId);

    await runTransaction(firestore, async (tx) => {
        const convSnap = await tx.get(convRef);
        if (convSnap.exists()) {
            const convData = convSnap.data() as { unreadThreadCounts?: Record<string, unknown> };
            const raw = convData.unreadThreadCounts?.[userId];
            const current = typeof raw === 'number' && Number.isFinite(raw) ? Math.max(0, Math.trunc(raw)) : 0;
            const dec = Math.min(current, normalizedCount);
            if (dec > 0) {
                tx.update(convRef, {
                    [`unreadThreadCounts.${userId}`]: increment(-dec),
                });
            }
        }

        const parentSnap = await tx.get(parentRef);
        if (parentSnap.exists()) {
            const parentData = parentSnap.data() as { unreadThreadCounts?: Record<string, unknown> };
            const raw = parentData.unreadThreadCounts?.[userId];
            const current = typeof raw === 'number' && Number.isFinite(raw) ? Math.max(0, Math.trunc(raw)) : 0;
            const dec = Math.min(current, normalizedCount);
            if (dec > 0) {
                tx.update(parentRef, {
                    [`unreadThreadCounts.${userId}`]: increment(-dec),
                });
            }
        }
    });
}

/** Первое вложение-стикер или GIF в сообщении (для «Сохранить в мои стикеры»). */
export function getFirstStickerOrGifAttachment(message: ChatMessage): ChatAttachment | null {
  for (const a of message.attachments || []) {
    if (a.name.startsWith('gif_')) return a;
    if (a.name.startsWith('sticker_') || isAttachmentLikelyIosStickerCutout(a)) return a;
  }
  return null;
}

/** Первое изображение из сетки галереи (не видео) — для «Создать стикер». */
export function getFirstGridGalleryImageForStickerCreation(message: ChatMessage): ChatAttachment | null {
  for (const a of message.attachments || []) {
    if (!isGridGalleryAttachment(a) || isGridGalleryVideo(a)) continue;
    return a;
  }
  return null;
}
