'use client';

import React, { useCallback, useLayoutEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import type { User } from '@/lib/types';
import { GroupMentionSuggestions } from '@/components/chat/GroupMentionSuggestions';

const PANEL_MAX_W = 300;
const VIEWPORT_PAD = 8;
const GAP_PX = 6;

/** Выше типичных модалок и слоёв чата (Virtuoso, sticky). */
const Z_MENTION = 2147483000;

interface GroupMentionSuggestionsPortalProps {
  open: boolean;
  anchorRef: React.RefObject<HTMLElement | null>;
  participants: User[];
  onPick: (user: User) => void;
}

/**
 * Рендерит @-подсказку в document.body (fixed + z-index), чтобы панель была поверх ленты
 * сообщений и получала клики, а не пряталась под stacking context родителя.
 */
export function GroupMentionSuggestionsPortal({
  open,
  anchorRef,
  participants,
  onPick,
}: GroupMentionSuggestionsPortalProps) {
  const [pos, setPos] = useState<{ left: number; top: number } | null>(null);

  const updatePosition = useCallback(() => {
    if (!open || typeof window === 'undefined') return;
    const el = anchorRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const maxW = Math.min(PANEL_MAX_W, window.innerWidth - 2 * VIEWPORT_PAD);
    let left = rect.left;
    if (left + maxW > window.innerWidth - VIEWPORT_PAD) {
      left = window.innerWidth - VIEWPORT_PAD - maxW;
    }
    if (left < VIEWPORT_PAD) left = VIEWPORT_PAD;
    setPos({
      left,
      top: rect.top - GAP_PX,
    });
  }, [open, anchorRef]);

  useLayoutEffect(() => {
    if (!open) {
      setPos(null);
      return;
    }
    const run = () => updatePosition();
    run();
    const raf = window.requestAnimationFrame(run);
    window.addEventListener('resize', run);
    document.addEventListener('scroll', run, true);
    return () => {
      window.cancelAnimationFrame(raf);
      window.removeEventListener('resize', run);
      document.removeEventListener('scroll', run, true);
    };
  }, [open, participants.length, updatePosition]);

  if (!open || typeof document === 'undefined' || pos === null) return null;

  return createPortal(
    <div
      className="pointer-events-auto"
      style={{
        position: 'fixed',
        left: pos.left,
        top: pos.top,
        transform: 'translateY(-100%)',
        maxWidth: PANEL_MAX_W,
        zIndex: Z_MENTION,
      }}
      role="presentation"
    >
      <GroupMentionSuggestions participants={participants} onPick={onPick} className="!mb-0 shadow-2xl" />
    </div>,
    document.body
  );
}
