'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

type UseVerticalSwipeToDismissOptions = {
  /** Пока диалог открыт — обрабатываем жесты */
  enabled: boolean;
  onDismiss: () => void;
  /** Порог смещения по Y для закрытия (px); вверх и вниз симметрично */
  thresholdPx?: number;
};

/**
 * Вертикальный свайп (вверх или вниз) для закрытия полноэкранных оверлеев на мобильных.
 * Горизонтальное движение игнорируется для каруселей и т.п.
 */
export function useVerticalSwipeToDismiss({
  enabled,
  onDismiss,
  thresholdPx = 100,
}: UseVerticalSwipeToDismissOptions) {
  const [translateY, setTranslateY] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const touchStartRef = useRef<{ x: number; y: number } | null>(null);
  const swipeDirRef = useRef<'none' | 'horizontal' | 'vertical'>('none');
  const lastYRef = useRef(0);

  useEffect(() => {
    setTranslateY(0);
    setIsDragging(false);
    touchStartRef.current = null;
    swipeDirRef.current = 'none';
    lastYRef.current = 0;
  }, [enabled]);

  const onTouchStart = useCallback(
    (e: React.TouchEvent) => {
      if (!enabled || e.touches.length !== 1) return;
      const t = e.touches[0];
      touchStartRef.current = { x: t.clientX, y: t.clientY };
      swipeDirRef.current = 'none';
      setIsDragging(false);
    },
    [enabled]
  );

  const onTouchMove = useCallback(
    (e: React.TouchEvent) => {
      if (!enabled || !touchStartRef.current || e.touches.length !== 1) return;
      const t = e.touches[0];
      const dx = t.clientX - touchStartRef.current.x;
      const dy = t.clientY - touchStartRef.current.y;
      if (swipeDirRef.current === 'none') {
        if (Math.abs(dy) > Math.abs(dx) && Math.abs(dy) > 10) swipeDirRef.current = 'vertical';
        else if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 10) swipeDirRef.current = 'horizontal';
      }
      if (swipeDirRef.current === 'vertical') {
        setIsDragging(true);
        lastYRef.current = dy;
        setTranslateY(dy);
        if (e.cancelable) e.preventDefault();
      }
    },
    [enabled]
  );

  const onTouchEnd = useCallback(() => {
    if (!enabled) return;
    if (swipeDirRef.current === 'vertical' && Math.abs(lastYRef.current) > thresholdPx) {
      onDismiss();
    } else {
      setTranslateY(0);
    }
    touchStartRef.current = null;
    swipeDirRef.current = 'none';
    lastYRef.current = 0;
    setIsDragging(false);
  }, [enabled, onDismiss, thresholdPx]);

  const contentStyle: React.CSSProperties = {
    transform: `translateY(${translateY}px)`,
    opacity: 1 - Math.min(Math.abs(translateY) / 480, 0.5),
  };

  return {
    onTouchStart,
    onTouchMove,
    onTouchEnd,
    contentStyle,
    transitionClass: !isDragging ? 'transition-[transform,opacity] duration-200 ease-out' : '',
  };
}
