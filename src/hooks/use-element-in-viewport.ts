'use client';

import { useEffect, useState, type RefObject } from 'react';

const DEFAULT_OBSERVER_OPTIONS: IntersectionObserverInit = {
  root: null,
  rootMargin: '0px',
  threshold: 0.01,
};

export function useElementInViewport<T extends Element>(
  targetRef: RefObject<T>,
  options: IntersectionObserverInit = DEFAULT_OBSERVER_OPTIONS
): boolean {
  const [isInViewport, setIsInViewport] = useState(false);

  useEffect(() => {
    const target = targetRef.current;
    if (!target) {
      setIsInViewport(false);
      return;
    }

    if (typeof IntersectionObserver === 'undefined') {
      setIsInViewport(true);
      return;
    }

    const observer = new IntersectionObserver((entries) => {
      const firstEntry = entries[0];
      setIsInViewport(Boolean(firstEntry?.isIntersecting));
    }, options);

    observer.observe(target);
    return () => observer.disconnect();
  }, [targetRef, options]);

  return isInViewport;
}
