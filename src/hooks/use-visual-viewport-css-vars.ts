'use client';

import { useEffect } from 'react';

const VH_VAR = '--lc-visual-vh';
const OFFSET_VAR = '--lc-vv-offset-top';

/** Поле ввода с экранной клавиатурой — тогда ориентируемся на visualViewport, а не на innerHeight. */
function isLikelyEditableFocused(): boolean {
  const el = document.activeElement;
  if (!el || el === document.body) return false;
  if (el instanceof HTMLTextAreaElement) return true;
  if (el instanceof HTMLInputElement) {
    const t = el.type;
    if (
      t === 'hidden' ||
      t === 'button' ||
      t === 'submit' ||
      t === 'checkbox' ||
      t === 'radio' ||
      t === 'file' ||
      t === 'range' ||
      t === 'color'
    ) {
      return false;
    }
    return true;
  }
  if (el instanceof HTMLElement && el.isContentEditable) return true;
  return false;
}

/**
 * iOS Safari / PWA: при клавиатуре layout должен слушать visualViewport.
 * После выхода из свёрнутого состояния `visualViewport.height` иногда кратко (или долго) отстаёт
 * от `window.innerHeight` — оболочка с `--lc-visual-vh` становится ниже экрана, нижняя навигация «плывёт» вверх.
 * Вне режима клавиатуры берём max(vv, innerHeight); при открытой клавиатуре — высоту и offset из vv.
 */
export function useVisualViewportCssVars(enabled: boolean): void {
  useEffect(() => {
    if (!enabled || typeof window === 'undefined') return;
    const vv = window.visualViewport;
    const root = document.documentElement;
    if (!vv) return;

    const apply = () => {
      const innerH = window.innerHeight;
      const vvH = vv.height;
      const focusedTyping = isLikelyEditableFocused();
      const vvClearlyShrunk = vvH < innerH * 0.92;

      let shellH: number;
      let offsetTop: number;
      if (focusedTyping && vvClearlyShrunk) {
        shellH = vvH;
        offsetTop = vv.offsetTop;
      } else {
        shellH = Math.max(vvH, innerH);
        offsetTop = 0;
      }

      root.style.setProperty(VH_VAR, `${shellH}px`);
      root.style.setProperty(OFFSET_VAR, `${offsetTop}px`);
      if (window.scrollY !== 0) window.scrollTo(0, 0);
    };

    const onResume = () => {
      requestAnimationFrame(() => apply());
      window.setTimeout(apply, 0);
      window.setTimeout(apply, 120);
      window.setTimeout(apply, 320);
    };

    const onVisibility = () => {
      if (document.visibilityState === 'visible') onResume();
    };

    const onPageShow = (e: PageTransitionEvent) => {
      apply();
      if (e.persisted) onResume();
    };

    apply();
    vv.addEventListener('resize', apply);
    vv.addEventListener('scroll', apply);
    window.addEventListener('resize', apply);
    document.addEventListener('visibilitychange', onVisibility);
    window.addEventListener('pageshow', onPageShow);

    return () => {
      vv.removeEventListener('resize', apply);
      vv.removeEventListener('scroll', apply);
      window.removeEventListener('resize', apply);
      document.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('pageshow', onPageShow);
      root.style.removeProperty(VH_VAR);
      root.style.removeProperty(OFFSET_VAR);
    };
  }, [enabled]);
}
