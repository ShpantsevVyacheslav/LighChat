'use client';

import DOMPurify from 'dompurify';

/**
 * Санитизация HTML сообщений чата (TipTap) перед выводом через dangerouslySetInnerHTML.
 * Снижает риск XSS при вредоносном содержимом в Firestore.
 */
export function sanitizeMessageHtml(html: string | undefined | null): string {
  if (html == null || !html.trim()) return '';
  if (typeof window === 'undefined') return html;
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: [
      'p',
      'br',
      'strong',
      'b',
      'em',
      'i',
      'u',
      's',
      'strike',
      'del',
      'a',
      'ul',
      'ol',
      'li',
      'blockquote',
      'code',
      'pre',
      'span',
      'div',
      'h1',
      'h2',
      'h3',
      'h4',
    ],
    ALLOWED_ATTR: ['href', 'title', 'target', 'rel', 'class', 'data-chat-mention', 'data-user-id'],
    ALLOW_DATA_ATTR: false,
  });
}
