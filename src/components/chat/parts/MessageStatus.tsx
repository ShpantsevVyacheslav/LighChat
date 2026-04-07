'use client';

import React from 'react';
import { format, parseISO } from 'date-fns';
import { cn } from '@/lib/utils';
import { Clock, AlertTriangle, Check } from 'lucide-react';

interface MessageStatusProps {
  timestamp: any;
  isCurrentUser: boolean;
  deliveryStatus?: 'sending' | 'sent' | 'failed';
  readAt: string | null;
  className?: string;
  overlay?: boolean;
  isColoredBubble?: boolean;
  /** Время и статус без подложки (опрос и др. поверх обоев) */
  bare?: boolean;
}

const parseDateSafe = (date: any): Date => {
  if (!date) return new Date();
  if (typeof date === 'string') {
    try {
      return parseISO(date);
    } catch (e) {
      return new Date(date);
    }
  }
  if (date && typeof date.toDate === 'function') {
    return date.toDate();
  }
  if (date instanceof Date) return date;
  const d = new Date(date);
  return isNaN(d.getTime()) ? new Date() : d;
};

export function MessageStatus({ 
  timestamp, 
  isCurrentUser, 
  deliveryStatus, 
  readAt, 
  className, 
  overlay,
  isColoredBubble,
  bare,
}: MessageStatusProps) {
  const date = parseDateSafe(timestamp);
  const timeStr = format(date, 'HH:mm');

  return (
    <div className={cn(
      "inline-flex items-center gap-1 select-none whitespace-nowrap",
      bare
        ? cn(
            'text-[11px] font-medium',
            isCurrentUser
              ? 'text-white/95 [text-shadow:0_1px_2px_rgba(0,0,0,0.85)]'
              : 'text-foreground/85'
          )
        : 'text-[10px]',
      !bare &&
        (overlay
          ? 'absolute bottom-2 right-2 z-20 bg-black/50 backdrop-blur-md text-white/90 px-1.5 py-0.5 rounded-full border border-white/5'
          : cn('ml-2 relative top-[2px]', (isCurrentUser || isColoredBubble) ? 'text-white/60' : 'text-muted-foreground/60')),
      className
    )}>
      {timeStr}
      {isCurrentUser && (
        <span className={cn('flex items-center', bare ? 'ml-0.5' : 'ml-0.5')}>
          {deliveryStatus === 'sending' ? (
            <Clock className={cn('h-2.5 w-2.5', bare && 'text-white/90')} />
          ) : deliveryStatus === 'failed' ? (
            <AlertTriangle className="h-2.5 w-2.5 text-destructive" />
          ) : readAt ? (
            <div
              className={cn(
                'relative flex h-3 w-3.5 items-center',
                bare ? 'text-white' : 'text-blue-400'
              )}
            >
              <Check className="absolute left-0 h-3 w-3" />
              <Check className="absolute left-[3px] h-3 w-3" />
            </div>
          ) : (
            <Check className={cn('h-3 w-3', bare && 'text-white')} />
          )}
        </span>
      )}
    </div>
  );
}
