'use client';

import React, { useState } from 'react';
import { Smile } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Sheet,
  SheetContent,
  SheetTrigger,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet';
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
 * Кнопка emoji в композере → Telegram-style боковая шторка справа
 * (Sheet side="right") c 3 вкладками: Эмодзи / Стикеры / GIF.
 *
 * Шторка не закрывается после отправки стикера/GIF — можно отправить
 * подряд несколько; закрытие — клик вне или Esc.
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
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-9 w-9 shrink-0"
          disabled={disabled}
          aria-label="Эмодзи, стикеры и GIF"
        >
          <Smile className="h-4 w-4" />
        </Button>
      </SheetTrigger>
      <SheetContent
        side="right"
        className="flex w-full flex-col gap-0 p-0 sm:w-[400px] sm:max-w-[400px]"
      >
        <SheetHeader className="border-b border-border/40 px-4 py-3">
          <SheetTitle className="text-base">Эмодзи • Стикеры • GIF</SheetTitle>
        </SheetHeader>
        <div className="flex-1 overflow-y-auto p-3">
          <ChatStickerGifPanel
            userId={userId}
            onPickStickerAttachment={(att) => {
              onPickStickerAttachment(att);
              // Не закрываем — даём отправить подряд несколько.
            }}
            onPickGifAttachment={(att) => {
              onPickGifAttachment(att);
            }}
            onPickEmoji={insertEmoji}
          />
        </div>
      </SheetContent>
    </Sheet>
  );
}
