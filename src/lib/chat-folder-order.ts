import type { ChatFolder } from '@/lib/types';

/** Системные папки (без «Избранное» — оно отдельной кнопкой). */
export const DEFAULT_SIDEBAR_FOLDER_IDS = ['all', 'unread', 'personal', 'groups'] as const;

/**
 * Собирает список папок в порядке из Firestore, затем дополняет новыми id.
 */
export function mergeSidebarFolderOrder(
  saved: string[] | undefined,
  folders: ChatFolder[]
): ChatFolder[] {
  const byId = new Map(folders.map((f) => [f.id, f]));
  const customIds = folders.filter((f) => f.type === 'custom').map((f) => f.id);
  const fallbackTail = [
    ...DEFAULT_SIDEBAR_FOLDER_IDS.filter((id) => byId.has(id)),
    ...customIds,
  ];
  const seen = new Set<string>();
  const order: string[] = [];
  if (saved?.length) {
    for (const id of saved) {
      if (byId.has(id) && !seen.has(id)) {
        order.push(id);
        seen.add(id);
      }
    }
  }
  for (const id of fallbackTail) {
    if (!seen.has(id)) {
      order.push(id);
      seen.add(id);
    }
  }
  return order.map((id) => byId.get(id)!).filter(Boolean);
}
