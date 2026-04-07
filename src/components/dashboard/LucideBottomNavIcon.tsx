'use client';

import * as React from 'react';
import { DynamicIcon, type IconName } from 'lucide-react/dynamic';
import type { LucideIcon } from 'lucide-react';

type LucideBottomNavIconProps = {
  name: IconName;
  /** Статическая иконка из NAV_LINKS до загрузки динамического модуля. */
  fallbackIcon: LucideIcon;
  className?: string;
  strokeWidth?: number;
  style?: React.CSSProperties;
};

/**
 * Иконка нижнего меню по имени Lucide (kebab-case); подгружает чанк через DynamicIcon.
 */
export function LucideBottomNavIcon({
  name,
  fallbackIcon: Fallback,
  className,
  strokeWidth,
  style,
}: LucideBottomNavIconProps) {
  return (
    <DynamicIcon
      name={name}
      fallback={() => (
        <Fallback className={className} strokeWidth={strokeWidth} style={style} aria-hidden />
      )}
      className={className}
      strokeWidth={strokeWidth}
      style={style}
      aria-hidden
    />
  );
}
