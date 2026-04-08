
'use client';

import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import type { PinnedMessage } from '@/lib/types';
import { Pin, X, FileIcon, Film, Sticker, PlayCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

export function PinnedMessageBar({
  pinnedMessage,
  totalPins,
  onUnpin,
  onNavigate,
}: {
  pinnedMessage: PinnedMessage;
  /** Нужно только для заголовка: одно vs несколько закрепов (без счётчика «k из n»). */
  totalPins: number;
  onUnpin: () => void;
  onNavigate: () => void;
}) {
  const getMediaIcon = () => {
    switch (pinnedMessage.mediaType) {
      case 'video': return <Film className="h-3 w-3 text-white/70" />;
      case 'video-circle': return <PlayCircle className="h-3 w-3 text-white/70" />;
      case 'sticker': return <Sticker className="h-3 w-3 text-white/70" />;
      case 'file': return <FileIcon className="h-3 w-3 text-white/70" />;
      default: return null;
    }
  };

  return (
    <div
      className={cn(
        'flex shrink-0 items-center justify-between gap-2 rounded-t-xl border-b px-2 py-1.5',
        'animate-in slide-in-from-top-2 duration-300',
        /* Почти непрозрачная панель + лёгкий blur: читаемый текст на любых обоях (сильный blur даёт «ореол») */
        'border-border/70 bg-card/96 text-card-foreground shadow-none backdrop-blur-sm backdrop-saturate-100',
        'dark:border-border/50 dark:bg-card/94',
        '[&_p]:[text-shadow:none] [&_span]:[text-shadow:none]'
      )}
    >
      <button
        onClick={onNavigate}
        className="flex min-w-0 flex-1 items-center gap-3 rounded-xl px-2 py-1.5 text-left transition-colors hover:bg-muted/60 active:scale-[0.99]"
      >
        <Pin className="h-4 w-4 shrink-0 rotate-45 text-primary" strokeWidth={2} />
        
        {pinnedMessage.mediaPreviewUrl && (
            <div
              className={cn(
                'relative h-[18px] w-[18px] shrink-0 overflow-hidden rounded-md border border-border/80 group/pinned-media dark:border-white/15',
                pinnedMessage.mediaType === 'sticker'
                  ? 'bg-transparent'
                  : 'bg-muted dark:bg-black/40',
              )}
            >
                {pinnedMessage.mediaType === 'video' || pinnedMessage.mediaType === 'video-circle' ? (
                    <video 
                        src={pinnedMessage.mediaPreviewUrl} 
                        className="h-full w-full object-cover" 
                        muted 
                        playsInline
                    />
                ) : (
                    <img 
                        src={pinnedMessage.mediaPreviewUrl} 
                        className={cn(
                            "h-full w-full",
                            pinnedMessage.mediaType === 'sticker' ? "object-contain p-px" : "object-cover"
                        )} 
                        alt="" 
                    />
                )}
                <div className={cn(
                  "absolute inset-0 flex items-center justify-center opacity-0 group-hover/pinned-media:opacity-100 transition-opacity",
                  pinnedMessage.mediaType === 'sticker' ? "bg-black/10" : "bg-black/20"
                )}>
                    {getMediaIcon()}
                </div>
            </div>
        )}

        <div className="min-w-0 flex-1 antialiased">
          <p className="text-[10px] font-semibold uppercase leading-snug tracking-[0.08em] text-primary">
            {totalPins > 1 ? 'Закреплённые сообщения' : 'Закреплённое сообщение'}
          </p>
          <p className="mt-1 truncate text-sm leading-snug text-card-foreground">
            <span className="font-semibold text-foreground">{pinnedMessage.senderName}:</span>{' '}
            <span className="font-normal text-muted-foreground">{pinnedMessage.text}</span>
          </p>
        </div>
      </button>
      
      <TooltipProvider delayDuration={300}>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 shrink-0 rounded-full text-muted-foreground hover:bg-destructive/15 hover:text-destructive"
              onClick={onUnpin}
            >
              <X className="h-4 w-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="left">
            <p>Открепить это сообщение</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </div>
  );
}
