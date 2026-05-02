'use client';

import React, { useState } from 'react';
import { Smile } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ChatStickerGifPanel } from '@/components/chat/ChatStickerGifPanel';
import type { ChatAttachment } from '@/lib/types';

type EditorLike = {
  chain: () => {
    focus: () => { insertContent: (s: string) => { run: () => boolean } };
  };
};

interface ComposerStickerGifPopoverProps {
  userId: string;
  editorRef: React.MutableRefObject<EditorLike | null | undefined>;
  onPickStickerAttachment: (attachment: ChatAttachment) => void;
  onPickGifAttachment: (attachment: ChatAttachment) => void;
  disabled?: boolean;
}

/**
 * Кнопка emoji в композере → Telegram-style шторка с 3 вкладками
 * (Эмодзи / Стикеры / GIF), открывается над кнопкой как Popover слева.
 *
 * Замена `MessageInputEmojiPicker` (был только эмодзи на белом фоне) и
 * дублирующего входа из меню вложений «Стикеры/GIF».
 */
export function ComposerStickerGifPopover({
  userId,
  editorRef,
  onPickStickerAttachment,
  onPickGifAttachment,
  disabled,
}: ComposerStickerGifPopoverProps) {
  const [open, setOpen] = useState(false);

  const insertEmoji = (emoji: string) => {
    const ed = editorRef.current;
    if (!ed) return;
    ed.chain().focus().insertContent(emoji).run();
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
          aria-label="Эмодзи, стикеры и GIF"
          aria-haspopup="dialog"
        >
          <Smile className="h-4 w-4" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        // Шторка слева снизу-вверх (как в Telegram desktop): прикреплена к
        // кнопке, всплывает над композером.
        side="top"
        align="start"
        sideOffset={8}
        className="w-[min(100vw-2rem,380px)] rounded-2xl border border-white/10 bg-popover/95 p-2 shadow-2xl backdrop-blur"
      >
        <ChatStickerGifPanel
          userId={userId}
          onPickStickerAttachment={(att) => {
            onPickStickerAttachment(att);
            setOpen(false);
          }}
          onPickGifAttachment={(att) => {
            onPickGifAttachment(att);
            setOpen(false);
          }}
          onPickEmoji={insertEmoji}
        />
      </PopoverContent>
    </Popover>
  );
}
