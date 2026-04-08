'use client';

import React, { useMemo, useState } from 'react';
import { Smile } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { CHAT_INPUT_EMOJI_PALETTE } from '@/lib/chat-emoji-palette';
import { CHAT_LARGE_EMOJI_PALETTE } from '@/lib/chat-large-emoji-palette';

type EditorLike = {
  chain: () => {
    focus: () => { insertContent: (s: string) => { run: () => boolean } };
  };
};

interface MessageInputEmojiPickerProps {
  editorRef: React.MutableRefObject<EditorLike | null | undefined>;
  disabled?: boolean;
}

function mergeEmojiPalettes(a: string[], b: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const e of a) {
    if (!seen.has(e)) {
      seen.add(e);
      out.push(e);
    }
  }
  for (const e of b) {
    if (!seen.has(e)) {
      seen.add(e);
      out.push(e);
    }
  }
  return out;
}

/**
 * Кнопка у поля ввода: единая сетка всех эмодзи (основной набор + дополнения из «крупного» списка).
 */
export function MessageInputEmojiPicker({ editorRef, disabled }: MessageInputEmojiPickerProps) {
  const [open, setOpen] = useState(false);

  const allEmojis = useMemo(
    () => mergeEmojiPalettes(CHAT_INPUT_EMOJI_PALETTE, CHAT_LARGE_EMOJI_PALETTE),
    []
  );

  const insert = (emoji: string) => {
    const ed = editorRef.current;
    if (!ed) return;
    ed.chain().focus().insertContent(emoji).run();
    setOpen(false);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-9 w-9 shrink-0"
          disabled={disabled}
          aria-label="Эмодзи"
          aria-haspopup="dialog"
        >
          <Smile className="h-4 w-4" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        className="w-[min(100vw-2rem,300px)] p-2 rounded-2xl shadow-2xl border-none bg-popover/95"
        side="top"
        align="start"
        sideOffset={4}
      >
        <ScrollArea className="h-56 pr-2">
          <div
            className="grid grid-cols-8 gap-0.5"
            role="listbox"
            aria-label="Выбор эмодзи"
            style={{
              fontFamily:
                'system-ui, "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", "EmojiSymbols", sans-serif',
            }}
          >
            {allEmojis.map((emoji) => (
              <button
                key={emoji}
                type="button"
                role="option"
                className="flex h-9 w-9 items-center justify-center rounded-lg text-lg leading-none hover:bg-muted transition-colors"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => insert(emoji)}
              >
                {emoji}
              </button>
            ))}
          </div>
        </ScrollArea>
      </PopoverContent>
    </Popover>
  );
}
