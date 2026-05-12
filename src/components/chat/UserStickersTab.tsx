'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ImagePlus, Loader2, Plus, Trash2 } from 'lucide-react';

import { Button } from '@/components/ui/button';
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
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
import { useI18n } from '@/hooks/use-i18n';
import { usePublicStickerPacks } from '@/hooks/use-public-sticker-packs';
import { useUserStickerPacks } from '@/hooks/use-user-sticker-packs';
import type { ChatAttachment } from '@/lib/types';
import { USER_STICKER_MAX_FILE_BYTES, userStickerItemToAttachment } from '@/lib/user-sticker-packs';
import { USER_STICKER_VIDEO_MAX_UPLOAD_SEC } from '@/lib/sticker-media-normalize';
import { cn } from '@/lib/utils';
import { logger } from '@/lib/logger';

type UserStickersTabProps = {
  userId: string;
  onPickSticker: (attachment: ChatAttachment) => void;
  className?: string;
};

/**
 * Вкладка «Стикеры»: общие паки (`publicStickerPacks`) и свои паки; загрузка и удаление — только для своих.
 */
export function UserStickersTab({ userId, onPickSticker, className }: UserStickersTabProps) {
  const { toast } = useToast();
  const { t } = useI18n();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [newPackOpen, setNewPackOpen] = useState(false);
  const [newPackName, setNewPackName] = useState('');
  const [busy, setBusy] = useState(false);
  const [deletePackOpen, setDeletePackOpen] = useState(false);
  const [packIdPendingDelete, setPackIdPendingDelete] = useState<string | null>(null);
  const packLongPressTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const packLongPressFiredRef = useRef(false);

  const clearPackLongPressTimer = () => {
    if (packLongPressTimerRef.current != null) {
      clearTimeout(packLongPressTimerRef.current);
      packLongPressTimerRef.current = null;
    }
  };
  const [stickerScope, setStickerScope] = useState<'my' | 'public'>('my');

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
    createPack,
    addFilesToPack,
    deleteItem,
    deletePack,
  } = useUserStickerPacks(userId);

  const {
    packs: publicPacks,
    items: publicItems,
    packsLoading: publicPacksLoading,
    itemsLoading: publicItemsLoading,
    packsError: publicPacksError,
    itemsError: publicItemsError,
    selectedPackId: selectedPublicPackId,
    setSelectedPackId: setSelectedPublicPackId,
  } = usePublicStickerPacks();

  useEffect(() => {
    if (packsLoading || publicPacksLoading) return;
    const hasMy = packs && packs.length > 0;
    const hasPublic = publicPacks && publicPacks.length > 0;
    if (!hasMy && hasPublic) {
      setStickerScope('public');
      return;
    }
    if (stickerScope === 'public' && !hasPublic && hasMy) {
      setStickerScope('my');
    }
  }, [packs, publicPacks, packsLoading, publicPacksLoading, stickerScope]);

  const handleCreatePack = useCallback(async () => {
    setBusy(true);
    try {
      const id = await createPack(newPackName);
      if (id) {
        setStickerScope('my');
        setSelectedPackId(id);
        setNewPackOpen(false);
        setNewPackName('');
        toast({ title: t('chat.userStickers.packCreated') });
      } else {
        toast({ title: t('chat.userStickers.packCreateFailed'), variant: 'destructive' });
      }
    } catch (e) {
      logger.warn('stickers', 'createPack', e);
      toast({ title: t('chat.userStickers.packCreateError'), variant: 'destructive' });
    } finally {
      setBusy(false);
    }
  }, [createPack, newPackName, setSelectedPackId, setStickerScope, toast]);

  const packPendingDelete = packs?.find((p) => p.id === packIdPendingDelete);

  const handleDeletePack = useCallback(async () => {
    const pid = packIdPendingDelete;
    if (!pid) return;
    setBusy(true);
    try {
      const ok = await deletePack(pid);
      if (ok) {
        setDeletePackOpen(false);
        setPackIdPendingDelete(null);
        toast({ title: t('chat.userStickers.packDeleted') });
      } else {
        toast({ title: t('chat.userStickers.packDeleteFailed'), variant: 'destructive' });
      }
    } catch (e) {
      logger.warn('stickers', 'deletePack', e);
      toast({ title: t('chat.userStickers.packDeleteError'), variant: 'destructive' });
    } finally {
      setBusy(false);
    }
  }, [deletePack, packIdPendingDelete, toast]);

  const onFilesChosen = useCallback(
    async (list: FileList | null) => {
      if (!list?.length || !selectedPackId || !firestore || !storage) return;
      setBusy(true);
      try {
        const files = Array.from(list);
        const res = await addFilesToPack(selectedPackId, files, firestore, storage);
        if (res.ok > 0) {
          toast({ title: t('chat.userStickers.stickersAdded') + ': ' + res.ok });
        }
        if (res.errors.includes('file_too_large')) {
          toast({
            title: t('chat.userStickers.fileTooLarge'),
            description: t('chat.userStickers.fileTooLargeDesc') + ' ' + Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024)) + ' MB.',
            variant: 'destructive',
          });
        }
        if (res.errors.includes('video_too_long')) {
          toast({
            title: t('chat.userStickers.videoTooLong'),
            description: t('chat.userStickers.videoTooLongDesc') + ' ' + USER_STICKER_VIDEO_MAX_UPLOAD_SEC + 's.',
            variant: 'destructive',
          });
        }
        if (res.ok === 0 && res.skipped > 0 && !res.errors.length) {
          toast({ title: t('chat.userStickers.noSuitableFiles'), variant: 'destructive' });
        }
      } finally {
        setBusy(false);
        if (fileInputRef.current) fileInputRef.current.value = '';
      }
    },
    [addFilesToPack, firestore, selectedPackId, storage, toast]
  );

  const errMsg =
    packsError?.message ||
    itemsError?.message ||
    publicPacksError?.message ||
    publicItemsError?.message;

  const isPublicScope = stickerScope === 'public';
  const displayItems = isPublicScope ? publicItems : items;
  const displayItemsLoading = isPublicScope ? publicItemsLoading : itemsLoading;
  const noMyPacks = !packsLoading && (!packs || packs.length === 0);
  const noPublicPacks = !publicPacksLoading && (!publicPacks || publicPacks.length === 0);
  const noPacksAtAll = noMyPacks && noPublicPacks && !packsLoading && !publicPacksLoading;

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      {errMsg ? (
        <p className="text-[10px] text-destructive px-0.5" role="alert">
          {t('chat.userStickers.noAccess')}
        </p>
      ) : null}

      <div className="flex flex-wrap items-center gap-1.5">
        <ScrollArea className="max-w-full whitespace-nowrap">
          <div className="flex gap-1 pb-1 items-center">
            {publicPacks?.map((p) => (
              <Button
                key={`pub-${p.id}`}
                type="button"
                size="sm"
                variant={isPublicScope && p.id === selectedPublicPackId ? 'default' : 'outline'}
                className="shrink-0 rounded-lg text-[10px] font-semibold uppercase tracking-wide h-8 px-2.5 border-dashed"
                title={t('chat.userStickers.publicPackTitle')}
                onClick={() => {
                  setStickerScope('public');
                  setSelectedPublicPackId(p.id);
                }}
              >
                {p.name}
              </Button>
            ))}
            {publicPacksLoading ? (
              <span className="inline-flex h-8 items-center px-2">
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              </span>
            ) : null}
            {publicPacks && publicPacks.length > 0 && packs && packs.length > 0 ? (
              <span className="inline-block h-6 w-px shrink-0 bg-border mx-0.5" aria-hidden />
            ) : null}
            {packs?.map((p) => (
              <Button
                key={p.id}
                type="button"
                size="sm"
                variant={!isPublicScope && p.id === selectedPackId ? 'default' : 'outline'}
                className="shrink-0 rounded-lg text-[10px] font-semibold uppercase tracking-wide h-8 px-2.5"
                title={t('chat.userStickers.longPressDeleteHint')}
                onContextMenu={(e) => {
                  e.preventDefault();
                  setStickerScope('my');
                  setSelectedPackId(p.id);
                  setPackIdPendingDelete(p.id);
                  setDeletePackOpen(true);
                }}
                onTouchStart={() => {
                  clearPackLongPressTimer();
                  packLongPressFiredRef.current = false;
                  packLongPressTimerRef.current = setTimeout(() => {
                    packLongPressTimerRef.current = null;
                    packLongPressFiredRef.current = true;
                    setStickerScope('my');
                    setSelectedPackId(p.id);
                    setPackIdPendingDelete(p.id);
                    setDeletePackOpen(true);
                  }, 600);
                }}
                onTouchEnd={clearPackLongPressTimer}
                onTouchCancel={clearPackLongPressTimer}
                onClick={() => {
                  if (packLongPressFiredRef.current) {
                    packLongPressFiredRef.current = false;
                    return;
                  }
                  setStickerScope('my');
                  setSelectedPackId(p.id);
                }}
              >
                {p.name}
              </Button>
            ))}
            {packsLoading ? (
              <span className="inline-flex h-8 items-center px-2">
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              </span>
            ) : null}
          </div>
          <ScrollBar orientation="horizontal" />
        </ScrollArea>
        <Button
          type="button"
          size="icon"
          variant="outline"
          className="h-8 w-8 shrink-0 rounded-lg"
          disabled={busy}
          onClick={() => {
            setStickerScope('my');
            setNewPackOpen(true);
          }}
          title={t('chat.userStickers.newPackBtn')}
        >
          <Plus className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          size="icon"
          variant="outline"
          className="h-8 w-8 shrink-0 rounded-lg"
          disabled={busy || isPublicScope || !selectedPackId}
          onClick={() => fileInputRef.current?.click()}
          title={t('chat.userStickers.addFromDeviceBtn')}
        >
          <ImagePlus className="h-4 w-4" />
        </Button>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*,video/*"
        multiple
        className="hidden"
        onChange={(e) => void onFilesChosen(e.target.files)}
      />

      <div className="relative min-h-0 flex-1">
      {noPacksAtAll ? (
        <p className="text-center text-xs text-muted-foreground py-4 px-1">
          {t('chat.userStickers.noPacks')}
        </p>
      ) : (
        <ScrollArea className="absolute inset-0 pr-2">
          {displayItemsLoading ? (
            <div className="flex h-32 items-center justify-center">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : !displayItems?.length ? (
            <p className="py-6 text-center text-xs text-muted-foreground">
              {isPublicScope
                ? t('chat.userStickers.publicPackEmpty')
                : t('chat.userStickers.myPackEmpty')}
            </p>
          ) : (
            <div className="grid grid-cols-4 gap-2 p-1">
              {displayItems.map((st) => (
                <div key={st.id} className="group relative">
                  <button
                    type="button"
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => onPickSticker(userStickerItemToAttachment(st))}
                    className="relative w-full rounded-xl p-1 transition-transform hover:scale-105 active:scale-95 hover:bg-muted/80"
                  >
                    {st.contentType.startsWith('video/') ? (
                      <video
                        src={st.downloadUrl}
                        className="mx-auto h-14 w-14 object-cover rounded-md bg-black"
                        loop
                        muted
                        playsInline
                        autoPlay
                      />
                    ) : (
                      /* eslint-disable-next-line @next/next/no-img-element */
                      <img
                        src={st.downloadUrl}
                        alt=""
                        className="mx-auto h-14 w-14 object-contain"
                        loading="lazy"
                      />
                    )}
                  </button>
                  {!isPublicScope ? (
                    <button
                      type="button"
                      title={t('chat.userStickers.deleteFromPack')}
                      className="absolute -right-0.5 -top-0.5 flex h-6 w-6 items-center justify-center rounded-full bg-background/90 text-muted-foreground opacity-0 shadow-sm ring-1 ring-border transition-opacity group-hover:opacity-100 hover:text-destructive"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => selectedPackId && deleteItem(selectedPackId, st.id)}
                    >
                      <Trash2 className="h-3 w-3" />
                    </button>
                  ) : null}
                </div>
              ))}
            </div>
          )}
        </ScrollArea>
      )}
      </div>

      <Dialog open={newPackOpen} onOpenChange={setNewPackOpen}>
        <DialogContent className="rounded-2xl sm:max-w-sm" onMouseDown={(e) => e.stopPropagation()}>
          <DialogHeader>
            <DialogTitle>{t('chat.userStickers.newPackTitle')}</DialogTitle>
          </DialogHeader>
          <Input
            value={newPackName}
            onChange={(e) => setNewPackName(e.target.value)}
            placeholder={t('chat.userStickers.namePlaceholder')}
            className="rounded-xl"
            maxLength={80}
            onKeyDown={(e) => e.key === 'Enter' && void handleCreatePack()}
          />
          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="outline" className="rounded-xl" onClick={() => setNewPackOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button type="button" className="rounded-xl" disabled={busy} onClick={() => void handleCreatePack()}>
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : t('chat.userStickers.createBtn')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog
        open={deletePackOpen}
        onOpenChange={(o) => {
          setDeletePackOpen(o);
          if (!o) setPackIdPendingDelete(null);
        }}
      >
        <AlertDialogContent className="rounded-2xl" onMouseDown={(e) => e.stopPropagation()}>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('chat.userStickers.deletePackTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {t('chat.userStickers.deletePackDesc')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="gap-2 sm:gap-0">
            <AlertDialogCancel className="rounded-xl" disabled={busy}>
              {t('common.cancel')}
            </AlertDialogCancel>
            <Button
              type="button"
              variant="destructive"
              className="rounded-xl"
              disabled={busy}
              onClick={() => void handleDeletePack()}
            >
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : t('chat.userStickers.deleteBtn')}
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
