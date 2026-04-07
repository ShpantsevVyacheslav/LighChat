
'use client';

import React, { useEffect, useRef } from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import type { Editor } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import Link from '@tiptap/extension-link';
import Underline from '@tiptap/extension-underline';
import { Mark, mergeAttributes } from '@tiptap/core';
import { cn } from '@/lib/utils';
import { resolveMentionQueryFromAfterAt } from '@/lib/mention-editor-query';

/** Обычный @ (ASCII) и полноширинный ＠ (U+FF20), который иногда даёт раскладка/IME. */
const AT_SIGN_PATTERN = '@|＠';

const Spoiler = Mark.create({
  name: 'spoiler',
  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { class: 'spoiler-text' }), 0];
  },
  parseHTML() {
    return [{ tag: 'span.spoiler-text' }];
  },
});

/** Подсветка вставленного @упоминания в поле ввода. `data-user-id` — для открытия профиля по клику в ленте. */
const ChatMentionMark = Mark.create({
  name: 'chatMention',
  // Иначе ProseMirror «продлевает» mark на весь текст, набранный после упоминания.
  inclusive: false,
  addAttributes() {
    return {
      userId: {
        default: null,
        parseHTML: (element) => (element as HTMLElement).getAttribute('data-user-id'),
        renderHTML: (attributes) => {
          if (!attributes.userId) return {};
          return { 'data-user-id': attributes.userId as string };
        },
      },
    };
  },
  parseHTML() {
    return [
      {
        tag: 'span[data-chat-mention]',
        getAttrs: (element) => {
          const uid = (element as HTMLElement).getAttribute('data-user-id');
          return uid ? { userId: uid } : {};
        },
      },
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'span',
      mergeAttributes(HTMLAttributes, {
        'data-chat-mention': '',
        class: cn(
          'text-sky-600 dark:text-sky-400 font-semibold cursor-pointer underline-offset-2 hover:underline',
          HTMLAttributes.class
        ),
      }),
      0,
    ];
  },
});

/** Активное @-упоминание: null — подсказку не показывать (обычный текст). */
export function getMentionQueryAtCursor(editor: Editor, boundaryNames?: string[]): string | null {
  const { $from } = editor.state.selection;
  const blockStart = $from.start();
  const pos = $from.pos;
  const slice = editor.state.doc.textBetween(blockStart, pos, '\n', '\ufffc');
  const m = slice.match(new RegExp(`(?:${AT_SIGN_PATTERN})([\\w\\u0400-\\u04FF.\\- ]*)$`, 'u'));
  if (!m) return null;
  const afterAt = m[1] ?? '';
  if (boundaryNames && boundaryNames.length > 0) {
    return resolveMentionQueryFromAfterAt(afterAt, boundaryNames);
  }
  return afterAt.trimEnd();
}

/** Удаляет от «@» до курсора и вставляет `@Имя ` с подсветкой (mark) и `data-user-id`. */
export function replaceActiveMentionWithLabel(editor: Editor, displayLabel: string, userId: string): boolean {
  const { $from } = editor.state.selection;
  const blockStart = $from.start();
  const pos = $from.pos;
  const slice = editor.state.doc.textBetween(blockStart, pos, '\n', '\ufffc');
  const atAscii = slice.lastIndexOf('@');
  const atFull = slice.lastIndexOf('＠');
  const atIndex = Math.max(atAscii, atFull);
  if (atIndex < 0) return false;
  const from = blockStart + atIndex;
  const safe = displayLabel.replace(/</g, '').replace(/>/g, '');
  const text = `@${safe} `;
  editor
    .chain()
    .focus()
    .deleteRange({ from, to: pos })
    .insertContent({
      type: 'text',
      text,
      marks: [{ type: 'chatMention', attrs: { userId } }],
    })
    .run();
  return true;
}

interface MessageEditorProps {
  /** hasMeaningfulContent — по тексту документа (устойчивее, чем getText() при IME/составлении) */
  onUpdate: (html: string, text: string, hasMeaningfulContent: boolean, mentionQuery: string | null) => void;
  /** Только курсор/выделение: обновить @-подсказку без «печатает» и прочих побочных эффектов onUpdate. */
  onMentionQueryCursor?: (mentionQuery: string | null) => void;
  onEnter: () => void;
  editorRef: React.MutableRefObject<any>;
  onPasteFiles?: (files: File[]) => void;
  /** true — не отправлять по Enter (например, открыт список @-упоминаний). */
  shouldBlockEnter?: () => boolean;
  /** Имена/username участников (длинные первыми) — граница «упоминание закончилось». */
  mentionBoundaryNames?: string[];
}

export function MessageEditor({
  onUpdate,
  onMentionQueryCursor,
  onEnter,
  editorRef,
  onPasteFiles,
  shouldBlockEnter,
  mentionBoundaryNames = [],
}: MessageEditorProps) {
  const blockEnterRef = useRef(shouldBlockEnter);
  blockEnterRef.current = shouldBlockEnter;
  const mentionCursorRef = useRef(onMentionQueryCursor);
  mentionCursorRef.current = onMentionQueryCursor;
  const boundaryRef = useRef(mentionBoundaryNames);
  boundaryRef.current = mentionBoundaryNames;

  const editor = useEditor({
    immediatelyRender: false,
    extensions: [
      StarterKit.configure({
        heading: false,
      }),
      Underline,
      Spoiler,
      ChatMentionMark,
      Link.configure({
        autolink: true,
        openOnClick: false,
        HTMLAttributes: {
          class: 'text-primary underline cursor-pointer',
        },
      }),
      Placeholder.configure({
        placeholder: 'Сообщение',
      }),
    ],
    onUpdate: ({ editor }) => {
      const docText = (editor.state.doc.textContent ?? "").trim();
      const hasMeaningfulContent = docText.length > 0;
      const names = boundaryRef.current;
      const mentionQuery = getMentionQueryAtCursor(editor, names.length ? names : undefined);
      onUpdate(editor.getHTML(), editor.getText(), hasMeaningfulContent, mentionQuery);
    },
    onSelectionUpdate: ({ editor }) => {
      const names = boundaryRef.current;
      mentionCursorRef.current?.(getMentionQueryAtCursor(editor, names.length ? names : undefined));
    },
    editorProps: {
      attributes: {
        class: cn(
          'flex-1 min-h-[36px] max-h-40 rounded-2xl px-2.5 py-1.5 focus:outline-none text-sm overflow-y-auto',
          'w-full break-all [overflow-wrap:anywhere] [word-break:break-word] whitespace-pre-wrap',
          '[&_p]:m-0'
        ),
        enterkeyhint: 'enter',
      },
      handleKeyDown: (view, event) => {
        if (event.key === 'Enter' && !event.shiftKey) {
          const isMobile = window.matchMedia("(max-width: 768px)").matches ||
                           window.matchMedia("(pointer: coarse)").matches;

          if (!isMobile) {
            if (blockEnterRef.current?.()) {
              event.preventDefault();
              return true;
            }
            event.preventDefault();
            onEnter();
            return true;
          }
        }
        return false;
      },
      handlePaste: (view, event) => {
        const { clipboardData } = event;
        if (!clipboardData) return false;

        const files: File[] = [];
        const items = Array.from(clipboardData.items);
        
        items.forEach(item => {
          if (item.kind === 'file') {
            const file = item.getAsFile();
            if (file) files.push(file);
          }
        });

        if (files.length > 0) {
          onPasteFiles?.(files);
          const hasPlainText = items.some(
            (i) => i.kind === 'string' && (i.type === 'text/plain' || i.type === 'text/html')
          );
          if (!hasPlainText) {
            event.preventDefault();
            return true;
          }
        }
        return false;
      }
    },
  });

  useEffect(() => {
    if (editor) {
      editorRef.current = editor;
    }
  }, [editor, editorRef]);

  return (
    <div className="flex-1 min-w-0 overflow-hidden w-full max-w-full">
      <EditorContent editor={editor} className="w-full" />
    </div>
  );
}
