'use client';

import React, { useState } from 'react';
import { Smile } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
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

/**
 * Кнопка у поля ввода: эмодзи в редактор.
 * Вкладка «Крупные» — те же символы Unicode в крупной сетке (на Apple часть глифов анимированы системой).
 */
export function MessageInputEmojiPicker({ editorRef, disabled }: MessageInputEmojiPickerProps) {
  const [open, setOpen] = useState(false);

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
        <Tabs defaultValue="all" className="w-full">
          <TabsList className="mb-2 grid w-full grid-cols-2 rounded-xl">
            <TabsTrigger value="all" className="rounded-lg text-[10px] font-black uppercase tracking-wide">
              Все
            </TabsTrigger>
            <TabsTrigger value="large" className="rounded-lg text-[10px] font-black uppercase tracking-wide">
              Крупные
            </TabsTrigger>
          </TabsList>
          <TabsContent value="all" className="mt-0 outline-none">
            <ScrollArea className="h-56 pr-2">
              <div
                className="grid grid-cols-8 gap-0.5"
                role="listbox"
                aria-label="Выбор эмодзи"
              >
                {CHAT_INPUT_EMOJI_PALETTE.map((emoji) => (
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
          </TabsContent>
          <TabsContent value="large" className="mt-0 outline-none">
            <p className="mb-1.5 px-0.5 text-[9px] leading-tight text-muted-foreground">
              Крупная вставка; в превью сообщения одинокие эмодзи уже отображаются крупно. Анимация — там, где её даёт системный шрифт (например iOS).
            </p>
            <ScrollArea className="h-52 pr-2">
              <div
                className="grid grid-cols-5 gap-1"
                role="listbox"
                aria-label="Крупные эмодзи"
                style={{
                  fontFamily:
                    'system-ui, "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", "EmojiSymbols", sans-serif',
                }}
              >
                {CHAT_LARGE_EMOJI_PALETTE.map((emoji) => (
                  <button
                    key={emoji}
                    type="button"
                    role="option"
                    className="flex h-12 w-full items-center justify-center rounded-xl text-3xl leading-none hover:bg-muted transition-transform hover:scale-105 active:scale-95"
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => insert(emoji)}
                  >
                    {emoji}
                  </button>
                ))}
              </div>
            </ScrollArea>
          </TabsContent>
        </Tabs>
      </PopoverContent>
    </Popover>
  );
}
