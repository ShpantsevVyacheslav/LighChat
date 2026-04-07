'use client';

import React from 'react';
import { cn } from '@/lib/utils';
import { LinkPreview } from '../LinkPreview';
import type { Conversation, User } from '@/lib/types';
import { resolveMentionLabelToUserId } from '@/lib/mention-resolve';
import { sanitizeMessageHtml } from '@/lib/sanitize-message-html';

interface MessageTextProps {
  text?: string;
  isCurrentUser: boolean;
  isPureEmoji?: boolean;
  fontSizeClass?: string;
  isColoredBubble?: boolean;
  children?: React.ReactNode;
  conversation?: Conversation;
  allUsers?: User[];
  onMentionProfileOpen?: (userId: string) => void;
}

/**
 * Рендерит текст сообщения с минимальными отступами и поддержкой спойлеров.
 * Принимает дочерние элементы (например, статус), чтобы отображать их на той же строке.
 */
export function MessageText({
  text,
  isCurrentUser,
  isPureEmoji,
  fontSizeClass,
  isColoredBubble,
  children,
  conversation,
  allUsers,
  onMentionProfileOpen,
}: MessageTextProps) {
  // Если нет ни текста, ни дочерних элементов (статуса), ничего не рендерим
  if (!text && !children) return null;

  const safeHtml = text ? sanitizeMessageHtml(text) : '';

  const handleTextClick = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement;
    if (target.classList.contains('spoiler-text')) {
      target.classList.toggle('revealed');
      return;
    }
    const mentionEl = target.closest('[data-chat-mention]') as HTMLElement | null;
    if (mentionEl && onMentionProfileOpen && conversation && allUsers?.length) {
      e.preventDefault();
      e.stopPropagation();
      let uid = mentionEl.getAttribute('data-user-id');
      if (!uid) {
        const label = mentionEl.textContent || '';
        uid = resolveMentionLabelToUserId(label, conversation, allUsers) ?? '';
      }
      if (uid && conversation.participantIds.includes(uid)) {
        onMentionProfileOpen(uid);
      }
    }
  };

  return (
    <div className={cn(
      "block select-text relative message-bubble-content overflow-visible",
      isPureEmoji ? "p-0" : "px-3 py-0.5 min-w-0"
    )} onClick={handleTextClick}>
      {!isPureEmoji && (
        <div className={cn(
          "break-words overflow-visible leading-normal whitespace-pre-wrap [overflow-wrap:anywhere]",
          fontSizeClass || "text-sm"
        )}>
          {text && (
            <div 
              dangerouslySetInnerHTML={{ __html: safeHtml }} 
              className={cn(
                "inline [&_p]:inline [&_p]:m-0 [&_p]:text-inherit", 
                (isCurrentUser || isColoredBubble) ? "text-white [&_a]:text-white [&_a]:underline font-medium" : "[&_a]:text-primary [&_a]:underline"
              )} 
            />
          )}
          {children}
        </div>
      )}
      
      {isPureEmoji && text && (
        <div 
          className="text-[5rem] font-bold leading-tight" 
          dangerouslySetInnerHTML={{ __html: safeHtml }} 
        />
      )}

      {text && text.includes('http') && !isPureEmoji && (
        <div className="mt-2 space-y-1 block w-full">
          {Array.from(new Set(text.match(/https?:\/\/[^\s<"']+/g) || [])).map((url, i) => (
            <LinkPreview key={`link-${i}`} url={url.replace(/[.,!?;:)}\]]+$/, '')} />
          ))}
        </div>
      )}
    </div>
  );
}