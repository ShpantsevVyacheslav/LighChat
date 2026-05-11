import type { ChatAttachment, ChatMessage } from '@/lib/types';
import { isOnlyEmojis } from '@/lib/chat-utils';

const extractUrls = (text: string): string[] => {
  if (!text) return [];
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.match(urlRegex) || [];
};

export type CategorizedChatAttachments = {
  media: ChatAttachment[];
  files: ChatAttachment[];
  links: { url: string; messageId: string }[];
  audios: ChatAttachment[];
  stickers: ChatAttachment[];
  circles: (ChatAttachment & { senderId: string; createdAt: string })[];
  threadMessages: ChatMessage[];
};

/** Категории вложений и веток из загруженных сообщений чата (как в профиле участника). */
export function categorizeAttachmentsFromMessages(messages: ChatMessage[]): CategorizedChatAttachments {
  const files: ChatAttachment[] = [];
  const links: { url: string; messageId: string }[] = [];
  const audios: ChatAttachment[] = [];
  const stickers: ChatAttachment[] = [];
  const media: ChatAttachment[] = [];
  const circles: (ChatAttachment & { senderId: string; createdAt: string })[] = [];
  const threadMessages: ChatMessage[] = [];

  messages.forEach((msg) => {
    if (msg.isDeleted) return;

    if (msg.threadCount && msg.threadCount > 0) {
      threadMessages.push(msg);
    }

    if (msg.text && isOnlyEmojis(msg.text)) return;

    if (msg.attachments) {
      msg.attachments.forEach((att) => {
        // Defensive: E2EE-вложения / оптимистичные / legacy messages могут
        // прийти с `name === undefined` или `type === undefined`. Без guard
        // тут падает весь useMemo ChatParticipantProfile → /dashboard crash
        // ("Cannot read properties of undefined (reading 'startsWith')").
        const name = att.name ?? '';
        const type = att.type ?? '';
        const isSticker = name.startsWith('sticker_') || type.includes('svg');
        const isVideoCircle = name.startsWith('video-circle_');

        if (isSticker) {
          stickers.push(att);
        } else if (isVideoCircle) {
          circles.push({ ...att, senderId: msg.senderId, createdAt: msg.createdAt });
        } else if (type.startsWith('image/') || type.startsWith('video/')) {
          media.push(att);
        } else if (type.startsWith('audio/')) {
          audios.push(att);
        } else {
          files.push(att);
        }
      });
    }
    if (msg.text) {
      const foundUrls = extractUrls(msg.text);
      foundUrls.forEach((url) => links.push({ url, messageId: msg.id }));
    }
  });

  const uniqueMedia = media.filter((att, index, self) => index === self.findIndex((t) => t.url === att.url));
  const uniqueFiles = files.filter((att, index, self) => index === self.findIndex((t) => t.url === att.url));
  const uniqueLinks = links.filter((link, index, self) => index === self.findIndex((t) => t.url === link.url));
  const uniqueAudios = audios.filter((att, index, self) => index === self.findIndex((t) => t.url === att.url));
  const uniqueStickers = stickers.filter((att, index, self) => index === self.findIndex((t) => t.name === att.name));
  const uniqueCircles = circles.filter((att, index, self) => index === self.findIndex((t) => t.url === att.url));

  const parseTime = (m: ChatMessage) =>
    new Date(m.lastThreadMessageTimestamp || m.createdAt).getTime();

  return {
    media: uniqueMedia,
    files: uniqueFiles,
    links: uniqueLinks,
    audios: uniqueAudios,
    stickers: uniqueStickers,
    circles: uniqueCircles,
    threadMessages: threadMessages.sort((a, b) => parseTime(b) - parseTime(a)),
  };
}
