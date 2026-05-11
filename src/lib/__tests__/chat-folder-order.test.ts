import { describe, expect, it } from 'vitest';
import { mergeSidebarFolderOrder, DEFAULT_SIDEBAR_FOLDER_IDS } from '@/lib/chat-folder-order';
import type { ChatFolder } from '@/lib/types';

/**
 * [audit M-013] Folder order merge — UX critical для sidebar чатов.
 * Регрессия → пользовательский custom order сбрасывается, или новые
 * folder'ы не показываются.
 */

/**
 * `system` папки в проекте — это конкретные variants 'all'/'personal'/'groups'
 * (не type='system'). Тестовый helper передаёт type соответствующий id.
 */
const SYSTEM = (id: 'all' | 'unread' | 'personal' | 'groups'): ChatFolder => ({
  id,
  type: id === 'all' || id === 'personal' || id === 'groups' ? id : 'all',
  name: id,
  conversationIds: [],
});
const CUSTOM = (id: string, name = id): ChatFolder => ({
  id,
  type: 'custom',
  name,
  conversationIds: [],
});

describe('DEFAULT_SIDEBAR_FOLDER_IDS', () => {
  it('фиксированный порядок системных папок', () => {
    expect(DEFAULT_SIDEBAR_FOLDER_IDS).toEqual(['all', 'unread', 'personal', 'groups']);
  });
});

describe('mergeSidebarFolderOrder', () => {
  it('пустой saved → дефолтный порядок системных + custom', () => {
    const folders = [SYSTEM('all'), SYSTEM('groups'), CUSTOM('work'), CUSTOM('travel')];
    const r = mergeSidebarFolderOrder(undefined, folders);
    expect(r.map((f) => f.id)).toEqual(['all', 'groups', 'work', 'travel']);
  });

  it('saved order сохранён, новые id добавлены в конец', () => {
    const folders = [SYSTEM('all'), SYSTEM('unread'), CUSTOM('work'), CUSTOM('new_unsaved')];
    const r = mergeSidebarFolderOrder(['unread', 'work'], folders);
    expect(r.map((f) => f.id)).toEqual(['unread', 'work', 'all', 'new_unsaved']);
  });

  it('saved id не существующих папок отфильтрован', () => {
    const folders = [SYSTEM('all'), CUSTOM('work')];
    const r = mergeSidebarFolderOrder(['ghost', 'all', 'work'], folders);
    expect(r.map((f) => f.id)).toEqual(['all', 'work']);
  });

  it('saved дубль не дублирует в результате', () => {
    const folders = [SYSTEM('all'), SYSTEM('unread')];
    const r = mergeSidebarFolderOrder(['all', 'all', 'unread'], folders);
    expect(r.map((f) => f.id)).toEqual(['all', 'unread']);
  });

  it('пустой folders → []', () => {
    expect(mergeSidebarFolderOrder(['all'], [])).toEqual([]);
  });

  it('только custom folders без system', () => {
    const folders = [CUSTOM('a'), CUSTOM('b'), CUSTOM('c')];
    const r = mergeSidebarFolderOrder(undefined, folders);
    expect(r.map((f) => f.id)).toEqual(['a', 'b', 'c']);
  });

  it('saved порядок не нарушает stability с одинаковыми id', () => {
    const folders = [SYSTEM('all'), SYSTEM('unread'), CUSTOM('work')];
    const r = mergeSidebarFolderOrder(['work', 'unread', 'all'], folders);
    expect(r.map((f) => f.id)).toEqual(['work', 'unread', 'all']);
  });
});
