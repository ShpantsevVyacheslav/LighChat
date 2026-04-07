'use client';

import React, { useCallback, useRef, useState } from 'react';
import { Copy, ImagePlus, Loader2, Plus, Trash2 } from 'lucide-react';

import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { ScrollArea, ScrollBar } from '@/components/ui/scroll-area';
import { useToast } from '@/hooks/use-toast';
import { useUserStickerPacks } from '@/hooks/use-user-sticker-packs';
import type { ChatAttachment } from '@/lib/types';
import { USER_STICKER_MAX_FILE_BYTES, userStickerItemToAttachment } from '@/lib/user-sticker-packs';
import { cn } from '@/lib/utils';

type UserStickersTabProps = {
  userId: string;
  onPickSticker: (attachment: ChatAttachment) => void;
  className?: string;
};

/**
 * Вкладка «Стикеры»: свои паки в Firestore, файлы в Storage, дублирование пака, загрузка с устройства.
 */
export function UserStickersTab({ userId, onPickSticker, className }: UserStickersTabProps) {
  const { toast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [newPackOpen, setNewPackOpen] = useState(false);
  const [newPackName, setNewPackName] = useState('');
  const [busy, setBusy] = useState(false);

  const {
    firestore,
    storage,
    packs,
    items,
    packsLoading,
    itemsLoading,
    packsError,
    itemsError,
    selectedPackId,
    setSelectedPackId,
    selectedPack,
    createPack,
    duplicateCurrentPack,
    addFilesToPack,
    deleteItem,
  } = useUserStickerPacks(userId);

  const handleCreatePack = useCallback(async () => {
    setBusy(true);
    try {
      const id = await createPack(newPackName);
      if (id) {
        setSelectedPackId(id);
        setNewPackOpen(false);
        setNewPackName('');
        toast({ title: 'Стикерпак создан' });
      } else {
        toast({ title: 'Не удалось создать пак', variant: 'destructive' });
      }
    } catch (e) {
      console.warn('[LighChat:stickers] createPack', e);
      toast({ title: 'Ошибка при создании пака', variant: 'destructive' });
    } finally {
      setBusy(false);
    }
  }, [createPack, newPackName, setSelectedPackId, toast]);

  const handleDuplicatePack = useCallback(async () => {
    if (!selectedPack || !items) return;
    setBusy(true);
    try {
      await duplicateCurrentPack(selectedPack, items);
      toast({ title: 'Пак скопирован', description: 'Новый пак с теми же стикерами.' });
    } catch (e) {
      console.warn('[LighChat:stickers] duplicate', e);
      toast({ title: 'Не удалось скопировать пак', variant: 'destructive' });
    } finally {
      setBusy(false);
    }
  }, [duplicateCurrentPack, items, selectedPack, toast]);

  const onFilesChosen = useCallback(
    async (list: FileList | null) => {
      if (!list?.length || !selectedPackId || !firestore || !storage) return;
      setBusy(true);
      try {
        const files = Array.from(list);
        const res = await addFilesToPack(selectedPackId, files, firestore, storage);
        if (res.ok > 0) {
          toast({ title: `Добавлено стикеров: ${res.ok}` });
        }
        if (res.errors.includes('file_too_large')) {
          toast({
            title: 'Файл слишком большой',
            description: `Максимум ${Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024))} МБ на изображение.`,
            variant: 'destructive',
          });
        }
        if (res.ok === 0 && res.skipped > 0 && !res.errors.length) {
          toast({ title: 'Нет подходящих изображений', variant: 'destructive' });
        }
      } finally {
        setBusy(false);
        if (fileInputRef.current) fileInputRef.current.value = '';
      }
    },
    [addFilesToPack, firestore, selectedPackId, storage, toast]
  );

  const errMsg = packsError?.message || itemsError?.message;

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      {errMsg ? (
        <p className="text-[10px] text-destructive px-0.5" role="alert">
          Нет доступа к стикерам. Проверьте правила Firestore и войдите снова.
        </p>
      ) : null}

      <div className="flex flex-wrap items-center gap-1.5">
        <ScrollArea className="max-w-full whitespace-nowrap">
          <div className="flex gap-1 pb-1">
            {packs?.map((p) => (
              <Button
                key={p.id}
                type="button"
                size="sm"
                variant={p.id === selectedPackId ? 'default' : 'outline'}
                className="shrink-0 rounded-lg text-[10px] font-semibold uppercase tracking-wide h-8 px-2.5"
                onClick={() => setSelectedPackId(p.id)}
              >
                {p.name}
              </Button>
            ))}
            {packsLoading && (
              <span className="inline-flex h-8 items-center px-2">
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              </span>
            )}
          </div>
          <ScrollBar orientation="horizontal" />
        </ScrollArea>
        <Button
          type="button"
          size="icon"
          variant="outline"
          className="h-8 w-8 shrink-0 rounded-lg"
          disabled={busy}
          onClick={() => setNewPackOpen(true)}
          title="Новый стикерпак"
        >
          <Plus className="h-4 w-4" />
        </Button>
      </div>

      <div className="flex flex-wrap gap-1.5">
        <Button
          type="button"
          size="sm"
          variant="secondary"
          className="h-8 rounded-lg text-[10px] font-bold uppercase tracking-wide"
          disabled={busy || !selectedPackId}
          onClick={() => fileInputRef.current?.click()}
        >
          <ImagePlus className="mr-1.5 h-3.5 w-3.5" />
          С устройства
        </Button>
        <Button
          type="button"
          size="sm"
          variant="secondary"
          className="h-8 rounded-lg text-[10px] font-bold uppercase tracking-wide"
          disabled={busy || !selectedPack}
          onClick={() => void handleDuplicatePack()}
          title="Копия текущего пака (те же файлы в новом паке)"
        >
          <Copy className="mr-1.5 h-3.5 w-3.5" />
          Дублировать пак
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          multiple
          className="hidden"
          onChange={(e) => void onFilesChosen(e.target.files)}
        />
      </div>

      {!packsLoading && (!packs || packs.length === 0) ? (
        <p className="text-center text-xs text-muted-foreground py-4 px-1">
          Нет стикерпаков. Нажмите «+», создайте пак и добавьте картинки с устройства.
        </p>
      ) : (
        <ScrollArea className="h-56 pr-2">
          {itemsLoading ? (
            <div className="flex h-32 items-center justify-center">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : !items?.length ? (
            <p className="py-6 text-center text-xs text-muted-foreground">
              В этом паке пока пусто — загрузите изображения.
            </p>
          ) : (
            <div className="grid grid-cols-4 gap-2 p-1">
              {items.map((st) => (
                <div key={st.id} className="group relative">
                  <button
                    type="button"
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => onPickSticker(userStickerItemToAttachment(st))}
                    className="relative w-full rounded-xl p-1 transition-transform hover:scale-105 active:scale-95 hover:bg-muted/80"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={st.downloadUrl}
                      alt=""
                      className="mx-auto h-14 w-14 object-contain"
                      loading="lazy"
                    />
                  </button>
                  <button
                    type="button"
                    title="Удалить из пака"
                    className="absolute -right-0.5 -top-0.5 flex h-6 w-6 items-center justify-center rounded-full bg-background/90 text-muted-foreground opacity-0 shadow-sm ring-1 ring-border transition-opacity group-hover:opacity-100 hover:text-destructive"
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => selectedPackId && deleteItem(selectedPackId, st.id)}
                  >
                    <Trash2 className="h-3 w-3" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </ScrollArea>
      )}

      <Dialog open={newPackOpen} onOpenChange={setNewPackOpen}>
        <DialogContent className="rounded-2xl sm:max-w-sm" onMouseDown={(e) => e.stopPropagation()}>
          <DialogHeader>
            <DialogTitle>Новый стикерпак</DialogTitle>
          </DialogHeader>
          <Input
            value={newPackName}
            onChange={(e) => setNewPackName(e.target.value)}
            placeholder="Название"
            className="rounded-xl"
            maxLength={80}
            onKeyDown={(e) => e.key === 'Enter' && void handleCreatePack()}
          />
          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="outline" className="rounded-xl" onClick={() => setNewPackOpen(false)}>
              Отмена
            </Button>
            <Button type="button" className="rounded-xl" disabled={busy} onClick={() => void handleCreatePack()}>
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Создать'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
