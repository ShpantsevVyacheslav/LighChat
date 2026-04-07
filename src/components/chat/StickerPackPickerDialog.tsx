'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { collection, orderBy, query } from 'firebase/firestore';
import { Loader2 } from 'lucide-react';

import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { UserStickerPackDoc } from '@/lib/user-sticker-packs';
import { cn } from '@/lib/utils';

type StickerPackPickerDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string;
  title: string;
  description?: string;
  busy?: boolean;
  /** Выполняется после выбора пака; по успеху диалог закрывает вызывающий код. */
  onConfirmPack: (packId: string) => Promise<void>;
  createPack: (name: string) => Promise<string | null>;
};

/**
 * Выбор стикерпака для сохранения файла или вложения из чата.
 */
export function StickerPackPickerDialog({
  open,
  onOpenChange,
  userId,
  title,
  description,
  busy = false,
  onConfirmPack,
  createPack,
}: StickerPackPickerDialogProps) {
  const firestore = useFirestore();
  const packsQuery = useMemoFirebase(() => {
    if (!firestore || !userId) return null;
    return query(collection(firestore, 'users', userId, 'stickerPacks'), orderBy('updatedAt', 'desc'));
  }, [firestore, userId]);

  const { data: packs, isLoading } = useCollection<UserStickerPackDoc>(packsQuery);
  const [newPackOpen, setNewPackOpen] = useState(false);
  const [newName, setNewName] = useState('');
  const [innerBusy, setInnerBusy] = useState(false);

  const combinedBusy = busy || innerBusy;

  useEffect(() => {
    if (!open) {
      setNewPackOpen(false);
      setNewName('');
    }
  }, [open]);

  const handlePick = useCallback(
    async (packId: string) => {
      setInnerBusy(true);
      try {
        await onConfirmPack(packId);
      } finally {
        setInnerBusy(false);
      }
    },
    [onConfirmPack]
  );

  const handleCreate = useCallback(async () => {
    setInnerBusy(true);
    try {
      const id = await createPack(newName);
      if (id) {
        setNewPackOpen(false);
        setNewName('');
        await onConfirmPack(id);
      }
    } finally {
      setInnerBusy(false);
    }
  }, [createPack, newName, onConfirmPack]);

  return (
    <>
      <Dialog open={open && !newPackOpen} onOpenChange={onOpenChange}>
        <DialogContent
          className="max-h-[min(90vh,420px)] rounded-2xl sm:max-w-sm"
          onMouseDown={(e) => e.stopPropagation()}
        >
          <DialogHeader>
            <DialogTitle className="text-base">{title}</DialogTitle>
            {description ? <p className="text-xs text-muted-foreground">{description}</p> : null}
          </DialogHeader>
          <div className="flex justify-end pb-1">
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="rounded-lg text-xs"
              disabled={combinedBusy}
              onClick={() => setNewPackOpen(true)}
            >
              Новый пак
            </Button>
          </div>
          <ScrollArea className="max-h-[220px] pr-2">
            {isLoading ? (
              <div className="flex justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : !packs?.length ? (
              <p className="py-6 text-center text-xs text-muted-foreground">
                Нет паков. Создайте первый кнопкой «Новый пак».
              </p>
            ) : (
              <div className="flex flex-col gap-1">
                {packs.map((p) => (
                  <Button
                    key={p.id}
                    type="button"
                    variant="secondary"
                    className="h-auto justify-start rounded-xl py-2.5 text-left font-semibold"
                    disabled={combinedBusy}
                    onClick={() => void handlePick(p.id)}
                  >
                    {combinedBusy ? <Loader2 className="mr-2 h-4 w-4 shrink-0 animate-spin" /> : null}
                    <span className="truncate">{p.name}</span>
                  </Button>
                ))}
              </div>
            )}
          </ScrollArea>
          <DialogFooter>
            <Button type="button" variant="ghost" className="rounded-xl" disabled={combinedBusy} onClick={() => onOpenChange(false)}>
              Отмена
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={newPackOpen} onOpenChange={setNewPackOpen}>
        <DialogContent className="rounded-2xl sm:max-w-sm" onMouseDown={(e) => e.stopPropagation()}>
          <DialogHeader>
            <DialogTitle>Новый стикерпак</DialogTitle>
          </DialogHeader>
          <Input
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            placeholder="Название"
            className="rounded-xl"
            maxLength={80}
            onKeyDown={(e) => e.key === 'Enter' && void handleCreate()}
          />
          <DialogFooter className="gap-2">
            <Button type="button" variant="outline" className="rounded-xl" onClick={() => setNewPackOpen(false)}>
              Назад
            </Button>
            <Button type="button" className="rounded-xl" disabled={combinedBusy} onClick={() => void handleCreate()}>
              {combinedBusy ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Создать и сохранить'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
