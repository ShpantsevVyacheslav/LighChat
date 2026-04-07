'use client';

import React from 'react';
import { cn } from '@/lib/utils';
import { Reply } from 'lucide-react';
import type { ReplyContext } from '@/lib/types';

interface MessageReplyProps {
  replyTo: ReplyContext;
  isCurrentUser: boolean;
  onClick: () => void;
}

export function MessageReply({ replyTo, isCurrentUser, onClick }: MessageReplyProps) {
  return (
    <div 
      onClick={(e) => { e.stopPropagation(); onClick(); }} 
      className={cn(
        'p-2 mb-1 rounded-xl border-l-4 mx-2 mt-1 transition-colors flex items-center justify-between gap-3 cursor-pointer overflow-hidden min-h-[44px]', 
        isCurrentUser ? 'bg-white/10 border-white/40 hover:bg-white/20' : 'bg-black/5 border-primary/40 hover:bg-black/10'
      )}
    >
      <div className="min-w-0 flex-1">
        <div className={cn("font-bold text-xs", isCurrentUser ? "text-white" : "text-primary")}>
          {replyTo.senderName}
        </div>
        <div className={cn("text-xs line-clamp-1", isCurrentUser ? "text-white/80" : "text-muted-foreground")}>
          {replyTo.text}
        </div>
      </div>
      {replyTo.mediaPreviewUrl && (
        <div className="h-9 w-9 rounded-lg overflow-hidden shrink-0 border border-black/5 bg-black/20">
          {replyTo.mediaType === 'video' || replyTo.mediaType === 'video-circle' ? (
            <video src={replyTo.mediaPreviewUrl} className="h-full w-full object-cover" muted />
          ) : (
            <img src={replyTo.mediaPreviewUrl} className="h-full w-full object-cover" alt="" />
          )}
        </div>
      )}
    </div>
  );
}
