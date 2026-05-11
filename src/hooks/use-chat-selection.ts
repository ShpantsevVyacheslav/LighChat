'use client';

/**
 * [audit M-009] Извлечён из `ChatWindow.tsx`. Состояние multi-select для
 * bulk-операций (delete, forward).
 *
 * Что было inline:
 *  - 2 useState (`selection: { active, ids }`, `isBulkProcessing`)
 *  - useMemo для `canDeleteBulk`
 *  - 12-строчный `handleBulkDelete` callback
 *  - toggle-логика как inline closure в JSX (тяжёлая)
 *  - cancel как inline `() => setSelection({ active: false, ids: new Set() })`
 *
 * Хук возвращает `selection.active`, `selectedIds`, `isBusy`, `canDelete`,
 * `toggle(id)`, `cancel()`, `bulkDelete()`. Все мутации внутри хука
 * атомарны (раньше cancel был в JSX как inline, что создавало новый
 * Set каждый раз и могло race'ить с активной toggle).
 *
 * Note: `bulkDelete` принимает `deleteMessage` callback извне — это
 * единственная зависимость от логики чата (где она лежит в ChatWindow
 * как `handleDeleteMessage`). Хук остаётся pure: не знает про Firestore.
 */

import { useCallback, useMemo, useState } from 'react';
import type { ChatMessage } from '@/lib/types';

type ToastFn = (opts: {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;
type TFn = (key: string, params?: Record<string, string | number>) => string;

export type ChatSelection = {
  /** Включён ли режим выбора (показывает SelectionHeader). */
  active: boolean;
  /** Выбранные message id. */
  selectedIds: ReadonlySet<string>;
  /** Идёт ли bulk-операция (блокирует кнопки в SelectionHeader). */
  isBusy: boolean;
  /** Можно ли удалять — все выбранные принадлежат текущему юзеру и не deleted. */
  canDelete: boolean;
  /** Toggle сообщения в selection (auto-activates режим). */
  toggle: (messageId: string) => void;
  /** Очистить selection (выходим из режима). */
  cancel: () => void;
  /** Async bulk-delete всех выбранных через переданный `deleteMessage`. */
  bulkDelete: () => Promise<void>;
};

export function useChatSelection(opts: {
  allMessages: ChatMessage[];
  currentUserId: string;
  /** Делегат удаления — `handleDeleteMessage(id)` из ChatWindow. */
  deleteMessage: (id: string) => Promise<void> | void;
  toast: ToastFn;
  t: TFn;
}): ChatSelection {
  const { allMessages, currentUserId, deleteMessage, toast, t } = opts;

  const [active, setActive] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());
  const [isBusy, setIsBusy] = useState(false);

  const toggle = useCallback((messageId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(messageId)) next.delete(messageId);
      else next.add(messageId);
      return next;
    });
    setActive(true);
  }, []);

  const cancel = useCallback(() => {
    setActive(false);
    setSelectedIds(new Set());
  }, []);

  const canDelete = useMemo(() => {
    if (selectedIds.size === 0) return false;
    return Array.from(selectedIds).every((id) => {
      const m = allMessages.find((msg) => msg.id === id);
      return m && m.senderId === currentUserId && !m.isDeleted;
    });
  }, [selectedIds, allMessages, currentUserId]);

  const bulkDelete = useCallback(async () => {
    if (selectedIds.size === 0) return;
    setIsBusy(true);
    try {
      for (const id of Array.from(selectedIds)) {
        await deleteMessage(id);
      }
      setActive(false);
      setSelectedIds(new Set());
      toast({ title: t('chat.messagesDeleted') });
    } catch {
      toast({ variant: 'destructive', title: t('chat.deleteError') });
    } finally {
      setIsBusy(false);
    }
  }, [selectedIds, deleteMessage, toast, t]);

  return {
    active,
    selectedIds,
    isBusy,
    canDelete,
    toggle,
    cancel,
    bulkDelete,
  };
}
