'use client';

import React, { useMemo } from 'react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { LinkPreview } from '../LinkPreview';
import type { Conversation, User, UserContactLocalProfile } from '@/lib/types';
import { resolveMentionLabelToUserId } from '@/lib/mention-resolve';
import { sanitizeMessageHtml } from '@/lib/sanitize-message-html';
import { resolveContactDisplayName } from '@/lib/contact-display-name';

interface MessageTextProps {
  text?: string;
  isCurrentUser: boolean;
  isPureEmoji?: boolean;
  fontSizeClass?: string;
  isColoredBubble?: boolean;
  children?: React.ReactNode;
  conversation?: Conversation;
  allUsers?: User[];
  contactProfiles?: Record<string, UserContactLocalProfile>;
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
  contactProfiles,
  onMentionProfileOpen,
}: MessageTextProps) {
  const { t } = useI18n();
  const safeHtml = useMemo(() => (text ? sanitizeMessageHtml(text) : ''), [text]);

  const displayHtml = useMemo(() => {
    if (!safeHtml || !safeHtml.includes('data-chat-mention')) return safeHtml;
    if (typeof window === 'undefined') return safeHtml;
    if (!conversation || !allUsers?.length) return safeHtml;
    try {
      const parser = new DOMParser();
      const parsed = parser.parseFromString(`<div>${safeHtml}</div>`, 'text/html');
      const root = parsed.body.firstElementChild as HTMLElement | null;
      if (!root) return safeHtml;
      root.querySelectorAll<HTMLElement>('[data-chat-mention]').forEach((el) => {
        let uid = el.getAttribute('data-user-id') || '';
        if (!uid) {
          uid = resolveMentionLabelToUserId(
            el.textContent || '',
            conversation,
            allUsers,
            contactProfiles
          ) ?? '';
        }
        if (!uid || !conversation.participantIds.includes(uid)) return;
        const liveUser = allUsers.find((u) => u.id === uid);
        const fallback =
          (liveUser?.name || conversation.participantInfo?.[uid]?.name || '').trim() ||
          el.textContent?.replace(/^[@＠]/u, '').trim() ||
          t('chat.userLabel');
        const resolved = resolveContactDisplayName(contactProfiles, uid, fallback);
        const label = `@${resolved || fallback}`;
        el.textContent = label;
        if (!el.getAttribute('data-user-id')) {
          el.setAttribute('data-user-id', uid);
        }
      });
      return root.innerHTML;
    } catch {
      return safeHtml;
    }
  }, [safeHtml, conversation, allUsers, contactProfiles]);

  // После хуков: если нечего показывать — выходим (иначе нарушается rules-of-hooks)
  if (!text && !children) return null;

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
        uid = resolveMentionLabelToUserId(label, conversation, allUsers, contactProfiles) ?? '';
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
              dangerouslySetInnerHTML={{ __html: displayHtml }} 
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
