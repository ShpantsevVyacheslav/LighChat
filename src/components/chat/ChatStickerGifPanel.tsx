'use client';

import React, { useCallback, useEffect, useState, useRef } from 'react';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Loader2, Search, Upload, BookmarkPlus } from 'lucide-react';
import { UserStickersTab } from '@/components/chat/UserStickersTab';
import { StickerPackPickerDialog } from '@/components/chat/StickerPackPickerDialog';
import { useUserStickerPacks } from '@/hooks/use-user-sticker-packs';
import { addChatAttachmentToUserStickerPack } from '@/lib/user-sticker-packs-client';
import type { ChatAttachment } from '@/lib/types';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

type TenorResponse = {
  ok?: boolean;
  error?: string;
  items?: Array<{ id: string; url: string; width?: number; height?: number }>;
};

type PendingSave =
  | { kind: 'files'; files: File[] }
  | { kind: 'remote'; att: ChatAttachment };

type ChatStickerGifPanelProps = {
  userId: string;
  onPickStickerAttachment: (attachment: ChatAttachment) => void;
  onPickGifAttachment: (att: ChatAttachment) => void;
  className?: string;
};

/**
 * Вкладки «Стикеры» и «GIF»: свои паки, поиск Tenor (если есть ключ), загрузка GIF/картинок в пак, сохранение кадра из поиска.
 */
export function ChatStickerGifPanel({
  userId,
  onPickStickerAttachment,
  onPickGifAttachment,
  className,
}: ChatStickerGifPanelProps) {
  const { toast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [gifQuery, setGifQuery] = useState('');
  const [gifLoading, setGifLoading] = useState(false);
  const [gifItems, setGifItems] = useState<NonNullable<TenorResponse['items']>>([]);
  const [tenorMissing, setTenorMissing] = useState(false);
  const [packPickerOpen, setPackPickerOpen] = useState(false);
  const [pendingSave, setPendingSave] = useState<PendingSave | null>(null);
  const [saveBusy, setSaveBusy] = useState(false);

  const { firestore, storage, createPack, addFilesToPack } = useUserStickerPacks(userId);

  const searchGif = useCallback(async (q: string) => {
    const t = q.trim();
    if (t.length < 1) {
      setGifItems([]);
      return;
    }
    setGifLoading(true);
    try {
      const res = await fetch(`/api/giphy/search?q=${encodeURIComponent(t)}`);
      const data = (await res.json()) as TenorResponse;
      if (data.error === 'missing_key') setTenorMissing(true);
      else setTenorMissing(false);
      setGifItems(Array.isArray(data.items) ? data.items : []);
    } catch {
      setGifItems([]);
    } finally {
      setGifLoading(false);
    }
  }, []);

  useEffect(() => {
    const t = setTimeout(() => {
      void searchGif(gifQuery);
    }, 350);
    return () => clearTimeout(t);
  }, [gifQuery, searchGif]);

  const handleGifPick = (item: NonNullable<TenorResponse['items']>[0]) => {
    const att: ChatAttachment = {
      url: item.url,
      name: `gif_${item.id}.gif`,
      type: 'image/gif',
      size: 0,
      ...(item.width && item.height ? { width: item.width, height: item.height } : {}),
    };
    onPickGifAttachment(att);
  };

  const openSavePicker = useCallback((save: PendingSave) => {
    setPendingSave(save);
    setPackPickerOpen(true);
  }, []);

  const onDeviceFiles = useCallback(
    (list: FileList | null) => {
      if (!list?.length) return;
      const files = Array.from(list).filter((f) => f.type.startsWith('image/'));
      if (!files.length) {
        toast({ title: 'Выберите изображение или GIF', variant: 'destructive' });
        return;
      }
      const bad = files.filter((f) => f.size > USER_STICKER_MAX_FILE_BYTES);
      if (bad.length) {
        toast({
          title: 'Файл слишком большой',
          description: `До ${Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024))} МБ.`,
          variant: 'destructive',
        });
        return;
      }
      openSavePicker({ kind: 'files', files });
      if (fileInputRef.current) fileInputRef.current.value = '';
    },
    [openSavePicker, toast]
  );

  const handleConfirmPack = useCallback(
    async (packId: string) => {
      if (!pendingSave || !firestore || !storage) return;
      setSaveBusy(true);
      try {
        if (pendingSave.kind === 'files') {
          const res = await addFilesToPack(packId, pendingSave.files, firestore, storage);
          if (res.ok > 0) {
            toast({ title: `Сохранено в пак: ${res.ok}` });
            setPackPickerOpen(false);
            setPendingSave(null);
          } else {
            toast({ title: 'Не удалось сохранить', variant: 'destructive' });
          }
        } else {
          const r = await addChatAttachmentToUserStickerPack(
            pendingSave.att,
            packId,
            userId,
            firestore,
            storage
          );
          if (r.ok) {
            toast({ title: 'Сохранено в стикерпак' });
            setPackPickerOpen(false);
            setPendingSave(null);
          } else if (r.error === 'file_too_large') {
            toast({
              title: 'Файл слишком большой',
              description: `До ${Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024))} МБ.`,
              variant: 'destructive',
            });
          } else if (r.error === 'fetch_failed') {
            toast({
              title: 'Не удалось скачать GIF',
              description: 'Сервер или браузер заблокировал загрузку (CORS). Сохраните файл на устройство и добавьте через «С устройства».',
              variant: 'destructive',
            });
          } else {
            toast({ title: 'Не удалось сохранить', variant: 'destructive' });
          }
        }
      } finally {
        setSaveBusy(false);
      }
    },
    [addFilesToPack, firestore, pendingSave, storage, toast, userId]
  );

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <Tabs defaultValue="stickers" className="w-full">
        <TabsList className="grid w-full grid-cols-2 rounded-xl">
          <TabsTrigger value="stickers" className="rounded-lg text-xs font-bold uppercase tracking-wide">
            Стикеры
          </TabsTrigger>
          <TabsTrigger value="gif" className="rounded-lg text-xs font-bold uppercase tracking-wide">
            GIF
          </TabsTrigger>
        </TabsList>
        <TabsContent value="stickers" className="mt-2 outline-none">
          <UserStickersTab userId={userId} onPickSticker={onPickStickerAttachment} />
        </TabsContent>
        <TabsContent value="gif" className="mt-2 flex flex-col gap-2 outline-none">
          <div className="flex flex-wrap gap-1.5">
            <Button
              type="button"
              size="sm"
              variant="secondary"
              className="h-8 flex-1 rounded-lg text-[10px] font-bold uppercase tracking-wide sm:flex-none"
              onClick={() => fileInputRef.current?.click()}
            >
              <Upload className="mr-1.5 h-3.5 w-3.5 shrink-0" />
              В мой пак
            </Button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*,.gif"
              multiple
              className="hidden"
              onChange={(e) => onDeviceFiles(e.target.files)}
            />
          </div>
          <p className="text-[10px] leading-snug text-muted-foreground px-0.5">
            GIF или картинка с устройства сохраняются в выбранный стикерпак — потом отправляйте из вкладки «Стикеры».
          </p>
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={gifQuery}
              onChange={(e) => setGifQuery(e.target.value)}
              placeholder="Поиск GIF…"
              className="h-9 rounded-xl pl-8 text-sm"
              onMouseDown={(e) => e.stopPropagation()}
            />
          </div>
          {tenorMissing && (
            <p className="text-[10px] leading-snug text-muted-foreground px-0.5">
              Поиск Tenor недоступен без ключа. Загрузите GIF кнопкой «В мой пак» или сохраняйте из сообщений в чате.
            </p>
          )}
          <ScrollArea className="h-48 pr-2">
            {gifLoading ? (
              <div className="flex h-32 items-center justify-center">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : gifItems.length === 0 ? (
              <p className="py-6 text-center text-xs text-muted-foreground">
                {gifQuery.trim().length < 1 ? 'Введите запрос или загрузите файл выше' : 'Ничего не найдено'}
              </p>
            ) : (
              <div className="grid grid-cols-3 gap-1.5 p-0.5">
                {gifItems.map((item) => (
                  <div key={item.id} className="group relative aspect-square">
                    <button
                      type="button"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleGifPick(item)}
                      className="relative h-full w-full overflow-hidden rounded-lg bg-muted/40 hover:ring-2 hover:ring-primary/40"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={item.url} alt="" className="h-full w-full object-cover" loading="lazy" />
                    </button>
                    <button
                      type="button"
                      title="Сохранить в мой пак"
                      className="absolute right-0.5 top-0.5 flex h-7 w-7 items-center justify-center rounded-md bg-background/90 text-muted-foreground opacity-0 shadow-sm ring-1 ring-border transition-opacity hover:text-primary group-hover:opacity-100"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={(e) => {
                        e.stopPropagation();
                        openSavePicker({
                          kind: 'remote',
                          att: {
                            url: item.url,
                            name: `gif_${item.id}.gif`,
                            type: 'image/gif',
                            size: 0,
                            ...(item.width && item.height ? { width: item.width, height: item.height } : {}),
                          },
                        });
                      }}
                    >
                      <BookmarkPlus className="h-3.5 w-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </ScrollArea>
        </TabsContent>
      </Tabs>

      <StickerPackPickerDialog
        open={packPickerOpen}
        onOpenChange={(o) => {
          setPackPickerOpen(o);
          if (!o) setPendingSave(null);
        }}
        userId={userId}
        title="Сохранить в стикерпак"
        description="Выберите пак, нажмите «Сохранить» или создайте новый пак. Затем отправляйте из вкладки «Стикеры»."
        busy={saveBusy}
        onConfirmPack={handleConfirmPack}
        createPack={(name) => createPack(name)}
      />
    </div>
  );
}
