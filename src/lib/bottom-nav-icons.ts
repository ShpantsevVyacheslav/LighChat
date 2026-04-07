import { iconNames } from 'lucide-react/dynamic';
import type { IconName } from 'lucide-react/dynamic';

/** Дефолтные иконки пунктов нижнего меню (имена Lucide в kebab-case). */
export const DEFAULT_BOTTOM_NAV_LUCIDE_NAMES: Record<string, string> = {
  '/dashboard/chat': 'messages-square',
  '/dashboard/contacts': 'contact',
  '/dashboard/meetings': 'video',
  '/dashboard/calls': 'phone-call',
};

const ICON_SET = new Set<string>(iconNames);

/** Популярные иконки при пустом поиске в picker (только существующие в текущей версии Lucide). */
export const BOTTOM_NAV_ICON_PICKER_SHORTLIST: string[] = [
  'message-circle',
  'message-square',
  'messages-square',
  'mail',
  'inbox',
  'phone',
  'smartphone',
  'contact',
  'user',
  'users',
  'user-plus',
  'video',
  'mic',
  'mic-2',
  'phone-call',
  'camera',
  'calendar',
  'bell',
  'home',
  'settings',
  'shield',
  'shield-check',
  'star',
  'heart',
  'bookmark',
  'folder',
  'image',
  'music',
  'map-pin',
  'layout-grid',
  'compass',
  'briefcase',
  'building',
  'building-2',
  'graduation-cap',
  'search',
  'hash',
  'at-sign',
  'paperclip',
  'send',
  'smile',
  'wifi',
  'coffee',
  'gift',
  'trophy',
  'flag',
  'rocket',
  'globe',
  'link',
  'sparkles',
  'zap',
  'crown',
].filter((n) => ICON_SET.has(n));

export function isValidLucideDynamicIconName(name: string): boolean {
  return ICON_SET.has(name);
}

export function resolveBottomNavLucideIconName(
  href: string,
  overrides: Partial<Record<string, string>> | null | undefined
): IconName {
  const raw = overrides?.[href]?.trim().toLowerCase();
  if (raw && ICON_SET.has(raw)) {
    return raw as IconName;
  }
  const fallback = DEFAULT_BOTTOM_NAV_LUCIDE_NAMES[href];
  if (fallback && ICON_SET.has(fallback)) {
    return fallback as IconName;
  }
  return 'circle' as IconName;
}

export function filterLucideIconNamesForPicker(query: string, maxResults: number): string[] {
  const q = query.trim().toLowerCase();
  if (!q) {
    return [...BOTTOM_NAV_ICON_PICKER_SHORTLIST];
  }
  const out: string[] = [];
  for (const n of iconNames) {
    if (n.includes(q)) {
      out.push(n);
      if (out.length >= maxResults) break;
    }
  }
  return out;
}
