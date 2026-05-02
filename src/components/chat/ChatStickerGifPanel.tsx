'use client';

import React, { useCallback, useEffect, useState, useRef } from 'react';
import dynamic from 'next/dynamic';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Loader2, Search, BookmarkPlus, X, History, Sparkles } from 'lucide-react';
import { UserStickersTab } from '@/components/chat/UserStickersTab';
import { StickerPackPickerDialog } from '@/components/chat/StickerPackPickerDialog';
import { useUserStickerPacks } from '@/hooks/use-user-sticker-packs';
import { addChatAttachmentToUserStickerPack } from '@/lib/user-sticker-packs-client';
import { giphyCache, type GiphyItem, type GiphyType } from '@/lib/giphy-cache-store';
import type { ChatAttachment } from '@/lib/types';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

// Тяжёлый emoji-picker подгружается лениво только когда вкладка нужна.
const EmojiPicker = dynamic(() => import('emoji-picker-react'), {
  ssr: false,
  loading: () => (
    <div className="flex h-48 items-center justify-center">
      <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
    </div>
  ),
});

type GiphyResponse = {
  ok?: boolean;
  error?: string;
  items?: Array<GiphyItem>;
  offset?: number;
  count?: number;
  total?: number;
  /** Если запрос был автоматически переведён — оригинал пользователя. */
  translatedFrom?: string | null;
  /** Что реально ушло в GIPHY (на английском, если был перевод). */
  query?: string;
};

type PendingSave =
  | { kind: 'remote'; att: ChatAttachment };

const GIF_EMOJI_FILTERS = [
  '😂', '❤️', '🔥', '👍', '😍', '🎉', '😢', '🤔', '🙏', '😎', '😴', '🤯',
];

type ChatStickerGifPanelProps = {
  userId: string;
  onPickStickerAttachment: (attachment: ChatAttachment) => void;
  onPickGifAttachment: (att: ChatAttachment) => void;
  /** Вставить unicode-эмодзи в текст композера. Если не задан — вкладка «Эмодзи»
   *  показывает заглушку. */
  onPickEmoji?: (emoji: string) => void;
  className?: string;
};

async function fetchGifs(
  q: string,
  type: GiphyType = 'gifs',
  offset = 0,
): Promise<GiphyResponse> {
  const params = new URLSearchParams();
  if (q.trim()) params.set('q', q.trim());
  if (type === 'stickers') params.set('type', 'stickers');
  if (offset > 0) params.set('offset', String(offset));
  const qs = params.toString();
  try {
    const res = await fetch(`/api/giphy/search${qs ? `?${qs}` : ''}`);
    return (await res.json()) as GiphyResponse;
  } catch {
    return { ok: false, items: [] };
  }
}

/**
 * Шторка композера: 3 вкладки — Эмодзи / Стикеры / GIF (паритет с мобайлом).
 * - Эмодзи: горизонтальная строка анимированных (GIPHY stickers, кеш 24h) + полный
 *   unicode-пикер `emoji-picker-react`.
 * - Стикеры: свои паки + общие, как раньше.
 * - GIF: эмодзи-фильтры, trending по умолчанию (кеш 24h), последние 30 просмотренных.
 */
export function ChatStickerGifPanel({
  userId,
  onPickStickerAttachment,
  onPickGifAttachment,
  onPickEmoji,
  className,
}: ChatStickerGifPanelProps) {
  const { toast } = useToast();
  const [gifQuery, setGifQuery] = useState('');
  const [gifLoading, setGifLoading] = useState(false);
  const [gifLoadingMore, setGifLoadingMore] = useState(false);
  const [gifHasMore, setGifHasMore] = useState(false);
  const [gifTotal, setGifTotal] = useState(0);
  const [gifLastQuery, setGifLastQuery] = useState('');
  const [gifItems, setGifItems] = useState<GiphyItem[]>([]);
  const [recentGifs, setRecentGifs] = useState<GiphyItem[]>([]);
  const [gifMissingKey, setGifMissingKey] = useState(false);
  const [activeEmojiFilter, setActiveEmojiFilter] = useState<string | null>(null);
  const [translatedHint, setTranslatedHint] = useState<string | null>(null);
  const gifScrollRef = useRef<HTMLDivElement>(null);

  // Анимированные эмодзи (GIPHY stickers).
  const [animEmojis, setAnimEmojis] = useState<GiphyItem[]>([]);
  const [animEmojisLoading, setAnimEmojisLoading] = useState(false);

  const [packPickerOpen, setPackPickerOpen] = useState(false);
  const [pendingSave, setPendingSave] = useState<PendingSave | null>(null);
  const [saveBusy, setSaveBusy] = useState(false);

  const { firestore, storage, createPack } = useUserStickerPacks(userId);

  // ============ Bootstrap ============

  // Загружаем недавние и trending при монтировании.
  useEffect(() => {
    setRecentGifs(giphyCache.getRecent());
    const cachedGifs = giphyCache.getTrending('gifs');
    if (cachedGifs && cachedGifs.length > 0) {
      setGifItems(cachedGifs);
    } else {
      void (async () => {
        setGifLoading(true);
        const r = await fetchGifs('');
        setGifLoading(false);
        if (r.error === 'missing_key') setGifMissingKey(true);
        const items = r.items ?? [];
        setGifItems(items);
        if (items.length > 0) giphyCache.saveTrending('gifs', items);
      })();
    }

    // Анимированные эмодзи — это GIPHY v2/emoji (именно эмодзи, не стикеры).
    const cachedEmojis = giphyCache.getTrending('emoji');
    if (cachedEmojis && cachedEmojis.length > 0) {
      setAnimEmojis(cachedEmojis);
    } else {
      void (async () => {
        setAnimEmojisLoading(true);
        const r = await fetchGifs('', 'emoji');
        setAnimEmojisLoading(false);
        const items = r.items ?? [];
        setAnimEmojis(items);
        if (items.length > 0) giphyCache.saveTrending('emoji', items);
      })();
    }
  }, []);

  // Дебаунс поиска GIF + учёт эмодзи-фильтра. Кеш по (type, query) — TTL 24h.
  const searchTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    if (searchTimer.current) clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(async () => {
      const q = gifQuery.trim();
      const effective = q.length >= 1 ? q : (activeEmojiFilter ?? '');
      setGifLastQuery(effective);
      const cached = giphyCache.get('gifs', effective);
      if (cached && cached.length > 0) {
        setGifItems(cached);
        setGifLoading(false);
        setGifTotal(cached.length);
        setGifHasMore(true);
        setTranslatedHint(null);
        return;
      }
      setGifLoading(true);
      const r = await fetchGifs(effective);
      setGifLoading(false);
      if (r.error === 'missing_key') setGifMissingKey(true);
      else setGifMissingKey(false);
      const items = r.items ?? [];
      const total = r.total ?? items.length;
      setGifItems(items);
      setGifTotal(total);
      setGifHasMore(items.length < total);
      setTranslatedHint(
        r.translatedFrom && r.query && r.query !== r.translatedFrom
          ? r.query
          : null,
      );
      if (items.length > 0) giphyCache.save('gifs', effective, items);
    }, 350);
    return () => {
      if (searchTimer.current) clearTimeout(searchTimer.current);
    };
  }, [gifQuery, activeEmojiFilter]);

  // Подгрузка следующей страницы при близости к концу скролла.
  const loadMoreGifs = useCallback(async () => {
    if (gifLoadingMore || !gifHasMore || gifLoading) return;
    setGifLoadingMore(true);
    const r = await fetchGifs(gifLastQuery, 'gifs', gifItems.length);
    setGifLoadingMore(false);
    const next = r.items ?? [];
    if (!next.length) {
      setGifHasMore(false);
      return;
    }
    const merged = [...gifItems];
    const existingIds = new Set(merged.map((a) => a.id));
    for (const it of next) {
      if (!existingIds.has(it.id)) merged.push(it);
    }
    setGifItems(merged);
    const total = r.total ?? merged.length;
    setGifTotal(total);
    setGifHasMore(merged.length < total);
    giphyCache.save('gifs', gifLastQuery, merged);
  }, [gifLoadingMore, gifHasMore, gifLoading, gifLastQuery, gifItems]);

  const handleGifScroll = useCallback(
    (e: React.UIEvent<HTMLDivElement>) => {
      const el = e.currentTarget;
      if (el.scrollHeight - el.scrollTop - el.clientHeight < 200) {
        void loadMoreGifs();
      }
    },
    [loadMoreGifs],
  );

  // ============ Handlers ============

  const handleGifPick = useCallback(
    (item: GiphyItem) => {
      const att: ChatAttachment = {
        url: item.url,
        name: `gif_${item.id}.gif`,
        type: 'image/gif',
        size: 0,
        ...(item.width && item.height ? { width: item.width, height: item.height } : {}),
      };
      onPickGifAttachment(att);
      giphyCache.addRecent(item);
      setRecentGifs(giphyCache.getRecent());
    },
    [onPickGifAttachment],
  );

  /// Анимированный эмодзи отправляется как стикер (`sticker_giphy_*`),
  /// чтобы получатель рендерил его без пузыря фиксированного размера.
  const handleAnimEmojiPick = useCallback(
    (item: GiphyItem) => {
      const att: ChatAttachment = {
        url: item.url,
        name: `sticker_giphy_${item.id}.gif`,
        type: 'image/gif',
        size: 0,
        ...(item.width && item.height
          ? { width: item.width, height: item.height }
          : {}),
      };
      onPickStickerAttachment(att);
    },
    [onPickStickerAttachment],
  );

  const openSavePicker = useCallback((save: PendingSave) => {
    setPendingSave(save);
    setPackPickerOpen(true);
  }, []);

  const handleConfirmPack = useCallback(
    async (packId: string) => {
      if (!pendingSave || !firestore || !storage) return;
      setSaveBusy(true);
      try {
        const r = await addChatAttachmentToUserStickerPack(
          pendingSave.att,
          packId,
          userId,
          firestore,
          storage,
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
            description:
              'Сервер или браузер заблокировал загрузку (CORS). Сохраните файл на устройство.',
            variant: 'destructive',
          });
        } else {
          toast({ title: 'Не удалось сохранить', variant: 'destructive' });
        }
      } finally {
        setSaveBusy(false);
      }
    },
    [firestore, pendingSave, storage, toast, userId],
  );

  const showRecent =
    recentGifs.length > 0 && gifQuery.trim().length < 1 && activeEmojiFilter === null;

  // ============ UI ============

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <Tabs defaultValue="emoji" className="w-full">
        <TabsList className="grid w-full grid-cols-3 rounded-xl">
          <TabsTrigger value="emoji" className="rounded-lg text-xs font-bold uppercase tracking-wide">
            Эмодзи
          </TabsTrigger>
          <TabsTrigger value="stickers" className="rounded-lg text-xs font-bold uppercase tracking-wide">
            Стикеры
          </TabsTrigger>
          <TabsTrigger value="gif" className="rounded-lg text-xs font-bold uppercase tracking-wide">
            GIF
          </TabsTrigger>
        </TabsList>

        {/* ============ EMOJI TAB ============ */}
        <TabsContent value="emoji" className="mt-2 flex flex-col gap-2 outline-none">
          {animEmojisLoading ? (
            <div className="flex h-16 items-center justify-center">
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            </div>
          ) : animEmojis.length > 0 ? (
            <>
              <div className="flex items-center gap-1 px-1 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">
                <Sparkles className="h-3 w-3" />
                Анимированные
              </div>
              <ScrollArea className="w-full whitespace-nowrap pb-1">
                <div className="flex gap-1.5 px-0.5">
                  {animEmojis.map((item) => (
                    <button
                      key={item.id}
                      type="button"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleAnimEmojiPick(item)}
                      className="h-16 w-16 shrink-0 overflow-hidden rounded-lg bg-muted/40 p-1 hover:ring-2 hover:ring-primary/40"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={item.url} alt="" className="h-full w-full object-contain" loading="lazy" />
                    </button>
                  ))}
                </div>
              </ScrollArea>
              <div className="h-px w-full bg-border/40" />
            </>
          ) : null}

          {onPickEmoji ? (
            <div className="flex justify-center">
              <EmojiPicker
                onEmojiClick={(data) => onPickEmoji(data.emoji)}
                width="100%"
                height={320}
                searchPlaceholder="Поиск…"
                lazyLoadEmojis
                previewConfig={{ showPreview: false }}
              />
            </div>
          ) : (
            <p className="py-6 text-center text-xs text-muted-foreground">
              Эмодзи в текст недоступны для этого окна.
            </p>
          )}
        </TabsContent>

        {/* ============ STICKERS TAB ============ */}
        <TabsContent value="stickers" className="mt-2 outline-none">
          <StickersTabBody userId={userId} onPickSticker={onPickStickerAttachment} />
        </TabsContent>

        {/* ============ GIF TAB ============ */}
        <TabsContent value="gif" className="mt-2 flex flex-col gap-2 outline-none">
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={gifQuery}
              onChange={(e) => setGifQuery(e.target.value)}
              placeholder="Поиск GIF…"
              className="h-9 rounded-xl pl-8 pr-8 text-sm"
              onMouseDown={(e) => e.stopPropagation()}
            />
            {gifQuery.length > 0 && (
              <button
                type="button"
                onClick={() => setGifQuery('')}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>

          {/* Эмодзи-фильтры */}
          <ScrollArea className="w-full whitespace-nowrap">
            <div className="flex gap-1.5 px-0.5">
              <EmojiFilterChip
                label="Все"
                active={activeEmojiFilter === null}
                onClick={() => setActiveEmojiFilter(null)}
              />
              {GIF_EMOJI_FILTERS.map((emoji) => (
                <EmojiFilterChip
                  key={emoji}
                  label={emoji}
                  active={activeEmojiFilter === emoji}
                  onClick={() => {
                    setActiveEmojiFilter(emoji);
                    setGifQuery('');
                  }}
                />
              ))}
            </div>
          </ScrollArea>

          {gifMissingKey && (
            <p className="px-0.5 text-[10px] leading-snug text-muted-foreground">
              Поиск GIF временно недоступен.
            </p>
          )}

          {translatedHint && (
            <p className="px-0.5 text-[10px] leading-snug text-muted-foreground">
              Искали: {translatedHint}
            </p>
          )}

          <div
            ref={gifScrollRef}
            onScroll={handleGifScroll}
            className="h-72 overflow-y-auto overflow-x-hidden pr-2"
          >
            {gifLoading ? (
              <div className="flex h-32 items-center justify-center">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {showRecent && (
                  <>
                    <div className="flex items-center gap-1 px-1 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">
                      <History className="h-3 w-3" />
                      Недавние
                    </div>
                    <GifGrid items={recentGifs} onPick={handleGifPick} onSave={openSavePicker} />
                    <div className="flex items-center gap-1 px-1 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">
                      <Sparkles className="h-3 w-3" />
                      Trending
                    </div>
                  </>
                )}
                {gifItems.length === 0 ? (
                  <p className="py-6 text-center text-xs text-muted-foreground">
                    Ничего не найдено
                  </p>
                ) : (
                  <GifGrid items={gifItems} onPick={handleGifPick} onSave={openSavePicker} />
                )}
                {gifLoadingMore && (
                  <div className="flex items-center justify-center py-2">
                    <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                  </div>
                )}
              </div>
            )}
          </div>
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

function EmojiFilterChip({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
      className={cn(
        'shrink-0 rounded-full px-3 py-1 text-sm transition-colors',
        active
          ? 'bg-primary/20 ring-1 ring-primary/60 text-foreground'
          : 'bg-muted/40 hover:bg-muted text-foreground/85',
        label.length <= 3 && 'text-base',
      )}
    >
      {label}
    </button>
  );
}

function GifGrid({
  items,
  onPick,
  onSave,
}: {
  items: GiphyItem[];
  onPick: (item: GiphyItem) => void;
  onSave: (save: PendingSave) => void;
}) {
  return (
    <div className="grid grid-cols-3 gap-1.5 p-0.5">
      {items.map((item) => (
        <div key={item.id} className="group relative aspect-square">
          <button
            type="button"
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => onPick(item)}
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
              onSave({
                kind: 'remote',
                att: {
                  url: item.url,
                  name: `gif_${item.id}.gif`,
                  type: 'image/gif',
                  size: 0,
                  ...(item.width && item.height
                    ? { width: item.width, height: item.height }
                    : {}),
                },
              });
            }}
          >
            <BookmarkPlus className="h-3.5 w-3.5" />
          </button>
        </div>
      ))}
    </div>
  );
}

/**
 * Тело вкладки «Стикеры» с переключателем «Мои/Общие» (UserStickersTab) и
 * «GIPHY» — библиотека стикеров с поиском и trending по умолчанию.
 */
function StickersTabBody({
  userId,
  onPickSticker,
}: {
  userId: string;
  onPickSticker: (att: ChatAttachment) => void;
}) {
  const [scope, setScope] = useState<'user' | 'library'>('user');

  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-1">
        <Button
          type="button"
          size="sm"
          variant={scope === 'user' ? 'default' : 'secondary'}
          className="h-7 rounded-full px-3 text-xs"
          onClick={() => setScope('user')}
        >
          Мои/Общие
        </Button>
        <Button
          type="button"
          size="sm"
          variant={scope === 'library' ? 'default' : 'secondary'}
          className="h-7 rounded-full px-3 text-xs"
          onClick={() => setScope('library')}
        >
          GIPHY
        </Button>
      </div>
      {scope === 'user' ? (
        <UserStickersTab userId={userId} onPickSticker={onPickSticker} />
      ) : (
        <GiphyStickerLibrary onPickSticker={onPickSticker} />
      )}
    </div>
  );
}

function GiphyStickerLibrary({
  onPickSticker,
}: {
  onPickSticker: (att: ChatAttachment) => void;
}) {
  const [query, setQuery] = useState('');
  const [items, setItems] = useState<GiphyItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeFilter, setActiveFilter] = useState<string | null>(null);
  const [translatedHint, setTranslatedHint] = useState<string | null>(null);
  const debounce = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Bootstrap trending stickers + cache.
  useEffect(() => {
    const cached = giphyCache.getTrending('stickers');
    if (cached && cached.length > 0) {
      setItems(cached);
      return;
    }
    void (async () => {
      setLoading(true);
      const r = await fetchGifs('', 'stickers');
      setLoading(false);
      const list = r.items ?? [];
      setItems(list);
      if (list.length > 0) giphyCache.saveTrending('stickers', list);
    })();
  }, []);

  // Debounced search (учитывая эмодзи-фильтр).
  useEffect(() => {
    if (debounce.current) clearTimeout(debounce.current);
    debounce.current = setTimeout(async () => {
      const q = query.trim();
      const effective = q.length >= 1 ? q : (activeFilter ?? '');
      const cached = giphyCache.get('stickers', effective);
      if (cached && cached.length > 0) {
        setItems(cached);
        setLoading(false);
        setTranslatedHint(null);
        return;
      }
      setLoading(true);
      const r = await fetchGifs(effective, 'stickers');
      setLoading(false);
      const list = r.items ?? [];
      setItems(list);
      setTranslatedHint(
        r.translatedFrom && r.query && r.query !== r.translatedFrom
          ? r.query
          : null,
      );
      if (list.length > 0) giphyCache.save('stickers', effective, list);
    }, 350);
    return () => {
      if (debounce.current) clearTimeout(debounce.current);
    };
  }, [query, activeFilter]);

  const handlePick = useCallback(
    (item: GiphyItem) => {
      onPickSticker({
        url: item.url,
        // Префикс sticker_giphy_ — ChatAttachments рендерит как стикер
        // (без пузыря, фиксированный размер). Паритет с мобайлом.
        name: `sticker_giphy_${item.id}.gif`,
        type: 'image/gif',
        size: 0,
        ...(item.width && item.height
          ? { width: item.width, height: item.height }
          : {}),
      });
    },
    [onPickSticker],
  );

  return (
    <div className="flex flex-col gap-2">
      <div className="relative">
        <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Поиск стикеров…"
          className="h-9 rounded-xl pl-8 pr-8 text-sm"
          onMouseDown={(e) => e.stopPropagation()}
        />
        {query.length > 0 && (
          <button
            type="button"
            onClick={() => setQuery('')}
            className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        )}
      </div>

      {/* Эмодзи-фильтры (паритет с GIF-вкладкой). */}
      <ScrollArea className="w-full whitespace-nowrap">
        <div className="flex gap-1.5 px-0.5">
          <EmojiFilterChip
            label="Все"
            active={activeFilter === null}
            onClick={() => {
              setActiveFilter(null);
              setQuery('');
            }}
          />
          {GIF_EMOJI_FILTERS.map((emoji) => (
            <EmojiFilterChip
              key={emoji}
              label={emoji}
              active={activeFilter === emoji}
              onClick={() => {
                setActiveFilter(emoji);
                setQuery('');
              }}
            />
          ))}
        </div>
      </ScrollArea>

      {translatedHint && (
        <p className="px-0.5 text-[10px] leading-snug text-muted-foreground">
          Искали: {translatedHint}
        </p>
      )}

      <div className="h-72 overflow-y-auto overflow-x-hidden">
        {loading ? (
          <div className="flex h-32 items-center justify-center">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : items.length === 0 ? (
          <p className="py-6 text-center text-xs text-muted-foreground">
            Ничего не найдено
          </p>
        ) : (
          <div className="grid grid-cols-4 gap-1.5 p-0.5">
            {items.map((item) => (
              <button
                key={item.id}
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => handlePick(item)}
                className="aspect-square overflow-hidden rounded-lg bg-muted/30 p-1 hover:ring-2 hover:ring-primary/40"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={item.url}
                  alt=""
                  className="h-full w-full object-contain"
                  loading="lazy"
                />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
