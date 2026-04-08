'use client';

import { useEffect } from 'react';

const VH_VAR = '--lc-visual-vh';
const OFFSET_VAR = '--lc-vv-offset-top';

/**
 * iOS Safari: при клавиатуре layout часто «едет», хотя шапка должна оставаться в видимой зоне.
 * Пишем высоту и смещение visual viewport в CSS-переменные на documentElement —
 * оболочка дашборда на мобильном чате использует height: var(--lc-visual-vh, 100dvh).
 */
export function useVisualViewportCssVars(enabled: boolean): void {
  useEffect(() => {
    if (!enabled || typeof window === 'undefined') return;
    const vv = window.visualViewport;
    const root = document.documentElement;
    if (!vv) return;

    const apply = () => {
      root.style.setProperty(VH_VAR, `${vv.height}px`);
      root.style.setProperty(OFFSET_VAR, `${vv.offsetTop}px`);
      // Снимаем «прокрутку окна», из-за которой уезжает весь flex-стек.
      if (window.scrollY !== 0) window.scrollTo(0, 0);
    };

    apply();
    vv.addEventListener('resize', apply);
    vv.addEventListener('scroll', apply);

    return () => {
      vv.removeEventListener('resize', apply);
      vv.removeEventListener('scroll', apply);
      root.style.removeProperty(VH_VAR);
      root.style.removeProperty(OFFSET_VAR);
    };
  }, [enabled]);
}
