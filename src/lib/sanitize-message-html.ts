'use client';

import DOMPurify from 'dompurify';

/**
 * Санитизация HTML сообщений чата (TipTap) перед выводом через dangerouslySetInnerHTML.
 * Снижает риск XSS при вредоносном содержимом в Firestore.
 *
 * [audit H-010] На сервере (Next.js SSR/RSC) DOMPurify не работает (нет
 * window/DOM), поэтому раньше функция возвращала **сырой** HTML — footgun:
 * любой SSR-кэш мог отправить непроверенное user-supplied содержимое в
 * браузер ДО hydration. Теперь на сервере отдаём пустую строку — UI
 * мигнёт пустотой и сразу гидрируется с очищенным HTML на клиенте.
 * Чат-сообщения требуют auth и не SSR-рендерятся фактически, но
 * гарантия корректнее в коде, чем в комментарии.
 */
export function sanitizeMessageHtml(html: string | undefined | null): string {
  if (html == null || !html.trim()) return '';
  if (typeof window === 'undefined') return '';
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
    ALLOWED_ATTR: [
      'href',
      'title',
      'target',
      'rel',
      'class',
      'data-chat-mention',
      'data-user-id',
      'data-chat-custom-emoji',
      'data-emoji-id',
      'data-emoji-src',
      // Animated text effects (Phase 6 mobile/desktop). Web в этой
      // итерации ещё не рендерит анимацию — текст показывается
      // статически, но атрибут сохраняется для round-trip.
      'data-anim',
    ],
    ALLOW_DATA_ATTR: false,
  });
}
