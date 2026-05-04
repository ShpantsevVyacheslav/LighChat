'use client';

import React, { useCallback, useEffect, useState, useRef } from 'react';
import dynamic from 'next/dynamic';
import { Theme } from 'emoji-picker-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea, ScrollBar } from '@/components/ui/scroll-area';
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
  /** Явный hasMore с сервера (v2/emoji не отдаёт total — клиент должен
   *  смотреть на этот флаг). */
  hasMore?: boolean;
  translatedFrom?: string | null;
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
  if (type === 'emoji') params.set('type', 'emoji');
  if (offset > 0) params.set('offset', String(offset));
  const qs = params.toString();
  try {
    const res = await fetch(`/api/giphy/search${qs ? `?${qs}` : ''}`);
    return (await res.json()) as GiphyResponse;
  } catch {
    return { ok: false, items: [] };
  }
}

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

  // Динамическая высота emoji-picker — он не уважает height="100%".
  const emojiHostRef = useRef<HTMLDivElement>(null);
  const [emojiPickerHeight, setEmojiPickerHeight] = useState<number>(360);
  useEffect(() => {
    const el = emojiHostRef.current;
    if (!el || typeof ResizeObserver === 'undefined') return;
    const ro = new ResizeObserver((entries) => {
      const h = entries[0]?.contentRect.height;
      if (h && h > 100) setEmojiPickerHeight(h);
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const [animEmojis, setAnimEmojis] = useState<GiphyItem[]>([]);
  const [animEmojisLoading, setAnimEmojisLoading] = useState(false);
  const [animEmojisLoadingMore, setAnimEmojisLoadingMore] = useState(false);
  const [animEmojisHasMore, setAnimEmojisHasMore] = useState(true);

  const [packPickerOpen, setPackPickerOpen] = useState(false);
  const [pendingSave, setPendingSave] = useState<PendingSave | null>(null);
  const [saveBusy, setSaveBusy] = useState(false);

  const { firestore, storage, createPack } = useUserStickerPacks(userId);

  // ============ Bootstrap ============

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

    const cachedEmojis = giphyCache.getTrending('emoji');
    if (cachedEmojis && cachedEmojis.length > 0) {
      setAnimEmojis(cachedEmojis);
      // У кеша нет инфы о hasMore — разрешаем дозагрузку при скролле.
      setAnimEmojisHasMore(true);
    } else {
      void (async () => {
        setAnimEmojisLoading(true);
        const r = await fetchGifs('', 'emoji');
        setAnimEmojisLoading(false);
        const items = r.items ?? [];
        setAnimEmojis(items);
        setAnimEmojisHasMore(r.hasMore ?? items.length > 0);
        if (items.length > 0) giphyCache.saveTrending('emoji', items);
      })();
    }
  }, []);

  const loadMoreAnimEmojis = useCallback(async () => {
    if (animEmojisLoadingMore || !animEmojisHasMore) return;
    setAnimEmojisLoadingMore(true);
    const r = await fetchGifs('', 'emoji', animEmojis.length);
    setAnimEmojisLoadingMore(false);
    const next = r.items ?? [];
    if (next.length === 0) {
      setAnimEmojisHasMore(false);
      return;
    }
    let addedCount = 0;
    setAnimEmojis((prev) => {
      // Дедуп по id и url — защита от случая когда GIPHY возвращает
      // одну и ту же позицию с разными id (или наоборот, разные с одним url).
      const ids = new Set(prev.map((a) => a.id));
      const urls = new Set(prev.map((a) => a.url));
      const merged = [...prev];
      for (const it of next) {
        if (ids.has(it.id) || urls.has(it.url)) continue;
        merged.push(it);
        ids.add(it.id);
        urls.add(it.url);
      }
      addedCount = merged.length - prev.length;
      // Эмодзи-кеш живёт навсегда (TTL не применяется в giphyCache.get
      // для type='emoji'). Накопленный список переписывается каждой
      // страницей и доступен между сессиями.
      giphyCache.saveTrending('emoji', merged);
      return merged;
    });
    // Если страница оказалась полностью дублирующей — стоп, чтобы не
    // зациклиться на хвосте каталога GIPHY.
    setAnimEmojisHasMore(addedCount > 0 && (r.hasMore ?? false));
  }, [animEmojisLoadingMore, animEmojisHasMore, animEmojis.length]);

  const handleAnimEmojisScroll = useCallback(
    (e: React.UIEvent<HTMLDivElement>) => {
      const el = e.currentTarget;
      // Горизонтальный скролл: тригер за 200px до правого края.
      if (el.scrollWidth - el.scrollLeft - el.clientWidth < 200) {
        void loadMoreAnimEmojis();
      }
    },
    [loadMoreAnimEmojis],
  );

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

  /// Анимированный эмодзи: префикс `sticker_emoji_giphy_*` чтобы получатель
  /// рендерил его как unicode-эмодзи (~76px), а не как 200px-стикер.
  /// `sticker_giphy_*` зарезервирован за GIPHY-стикерами из библиотеки
  /// (вкладка Стикеры → GIPHY).
  const handleAnimEmojiPick = useCallback(
    (item: GiphyItem) => {
      const att: ChatAttachment = {
        url: item.url,
        name: `sticker_emoji_giphy_${item.id}.gif`,
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

  // Свой state-based таб-контроллер вместо Radix Tabs.
  // Radix-Tabs при цепочке flex-1 + min-h-0 не растягивает активный TabsContent
  // надёжно, из-за чего контент сжимался к низу панели.
  const [activeTab, setActiveTab] = useState<'emoji' | 'stickers' | 'gif'>('emoji');
  const tabBtn = (value: typeof activeTab, label: string) => (
    <button
      type="button"
      onClick={() => setActiveTab(value)}
      className={cn(
        'flex-1 rounded-lg px-3 py-1.5 text-xs font-bold uppercase tracking-wide transition-colors',
        activeTab === value
          ? 'bg-background text-foreground shadow-sm'
          : 'text-muted-foreground hover:text-foreground',
      )}
    >
      {label}
    </button>
  );

  // ============ UI ============

  return (
    <div className={cn('flex min-h-0 flex-1 flex-col gap-2', className)}>
      <div className="flex shrink-0 gap-1 rounded-xl bg-muted p-1">
        {tabBtn('emoji', 'Эмодзи')}
        {tabBtn('stickers', 'Стикеры')}
        {tabBtn('gif', 'GIF')}
      </div>

      {/* ============ EMOJI TAB ============ */}
      {activeTab === 'emoji' && (
        <div className="flex min-h-0 flex-1 flex-col gap-2 outline-none">
          {/* Анимированные эмодзи — горизонтальная строка с прокруткой */}
          {animEmojisLoading ? (
            <div className="flex h-16 shrink-0 items-center justify-center">
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            </div>
          ) : animEmojis.length > 0 ? (
            <div className="shrink-0">
              <div className="mb-1 flex items-center gap-1 px-1 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">
                <Sparkles className="h-3 w-3" />
                Анимированные
              </div>
              <div
                onScroll={handleAnimEmojisScroll}
                className="flex w-full gap-1.5 overflow-x-auto overflow-y-hidden whitespace-nowrap px-0.5 pb-1"
              >
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
                {(animEmojisLoadingMore || (animEmojisHasMore && animEmojis.length > 0)) && (
                  <div className="flex h-16 w-16 shrink-0 items-center justify-center">
                    <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                  </div>
                )}
              </div>
              <div className="mt-1 h-px w-full bg-border/40" />
            </div>
          ) : null}

          {/* Emoji picker заполняет оставшееся пространство.
              emoji-picker-react требует пиксельный height (`100%` не растягивается
              корректно через цепочку flex-1 + Radix Tabs). Считаем динамически
              в `_emojiPickerHeight` через ResizeObserver. */}
          <div ref={emojiHostRef} className="min-h-0 flex-1">
            {onPickEmoji ? (
              <EmojiPicker
                onEmojiClick={(data) => onPickEmoji(data.emoji)}
                width="100%"
                height={emojiPickerHeight}
                theme={Theme.DARK}
                searchPlaceholder="Поиск…"
                lazyLoadEmojis
                previewConfig={{ showPreview: false }}
              />
            ) : (
              <p className="py-6 text-center text-xs text-muted-foreground">
                Эмодзи в текст недоступны для этого окна.
              </p>
            )}
          </div>
        </div>
      )}

      {/* ============ STICKERS TAB ============ */}
      {activeTab === 'stickers' && (
        <div className="flex min-h-0 flex-1 flex-col outline-none">
          <StickersTabBody userId={userId} onPickSticker={onPickStickerAttachment} className="flex-1 min-h-0" />
        </div>
      )}

      {/* ============ GIF TAB ============ */}
      {activeTab === 'gif' && (
        <div className="flex min-h-0 flex-1 flex-col gap-2 outline-none">
          {/* Поиск */}
          <div className="relative shrink-0">
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
          <div className="shrink-0">
            <ScrollArea className="w-full whitespace-nowrap">
              <div className="flex gap-1.5 px-0.5 pb-1">
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
              <ScrollBar orientation="horizontal" />
            </ScrollArea>
          </div>

          {gifMissingKey && (
            <p className="shrink-0 px-0.5 text-[10px] leading-snug text-muted-foreground">
              Поиск GIF временно недоступен.
            </p>
          )}

          {translatedHint && (
            <p className="shrink-0 px-0.5 text-[10px] leading-snug text-muted-foreground">
              Искали: {translatedHint}
            </p>
          )}

          {/* Прокручиваемая область GIF — заполняет оставшееся место */}
          <div
            ref={gifScrollRef}
            onScroll={handleGifScroll}
            className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden pr-1"
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
        </div>
      )}

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
  // «Все» остаётся на базовом text-xs; эмодзи-чипы чуть крупнее (text-base).
  const isEmoji = label !== 'Все' && label.length <= 3;
  return (
    <button
      type="button"
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
      className={cn(
        'shrink-0 rounded-full px-3 py-1 text-xs transition-colors',
        active
          ? 'bg-primary/20 ring-1 ring-primary/60 text-foreground'
          : 'bg-muted/40 hover:bg-muted text-foreground/85',
        isEmoji && 'text-base',
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
 * Вкладка «Стикеры»: свои/общие паки + библиотека (GIPHY stickers).
 */
function StickersTabBody({
  userId,
  onPickSticker,
  className,
}: {
  userId: string;
  onPickSticker: (att: ChatAttachment) => void;
  className?: string;
}) {
  const [scope, setScope] = useState<'user' | 'library'>('user');

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <div className="flex shrink-0 gap-1">
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
          Библиотека
        </Button>
      </div>
      {scope === 'user' ? (
        <UserStickersTab userId={userId} onPickSticker={onPickSticker} className="flex-1 min-h-0" />
      ) : (
        <GiphyStickerLibrary onPickSticker={onPickSticker} className="flex-1 min-h-0" />
      )}
    </div>
  );
}

function GiphyStickerLibrary({
  onPickSticker,
  className,
}: {
  onPickSticker: (att: ChatAttachment) => void;
  className?: string;
}) {
  const [query, setQuery] = useState('');
  const [items, setItems] = useState<GiphyItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(false);
  const [activeFilter, setActiveFilter] = useState<string | null>(null);
  const [translatedHint, setTranslatedHint] = useState<string | null>(null);
  const debounce = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastEffectiveQuery = useRef('');

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
      const total = r.total ?? list.length;
      setItems(list);
      setHasMore(list.length < total);
      lastEffectiveQuery.current = '';
      if (list.length > 0) giphyCache.saveTrending('stickers', list);
    })();
  }, []);

  useEffect(() => {
    if (debounce.current) clearTimeout(debounce.current);
    debounce.current = setTimeout(async () => {
      const q = query.trim();
      const effective = q.length >= 1 ? q : (activeFilter ?? '');
      const cached = giphyCache.get('stickers', effective);
      if (cached && cached.length > 0) {
        setItems(cached);
        setLoading(false);
        setHasMore(true);
        setTranslatedHint(null);
        lastEffectiveQuery.current = effective;
        return;
      }
      setLoading(true);
      const r = await fetchGifs(effective, 'stickers');
      setLoading(false);
      const list = r.items ?? [];
      const total = r.total ?? list.length;
      setItems(list);
      setHasMore(list.length < total);
      lastEffectiveQuery.current = effective;
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

  const loadMore = useCallback(async () => {
    if (loadingMore || !hasMore || loading) return;
    setLoadingMore(true);
    const r = await fetchGifs(lastEffectiveQuery.current, 'stickers', items.length);
    setLoadingMore(false);
    const next = r.items ?? [];
    if (!next.length) { setHasMore(false); return; }
    const merged = [...items];
    const existingIds = new Set(merged.map((a) => a.id));
    for (const it of next) {
      if (!existingIds.has(it.id)) merged.push(it);
    }
    const total = r.total ?? merged.length;
    setItems(merged);
    setHasMore(merged.length < total);
    giphyCache.save('stickers', lastEffectiveQuery.current, merged);
  }, [loadingMore, hasMore, loading, items]);

  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    const el = e.currentTarget;
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 200) {
      void loadMore();
    }
  }, [loadMore]);

  const handlePick = useCallback(
    (item: GiphyItem) => {
      onPickSticker({
        url: item.url,
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
    <div className={cn('flex flex-col gap-2', className)}>
      <div className="relative shrink-0">
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

      {/* Эмодзи-фильтры */}
      <div className="shrink-0">
        <ScrollArea className="w-full whitespace-nowrap">
          <div className="flex gap-1.5 px-0.5 pb-1">
            <EmojiFilterChip
              label="Все"
              active={activeFilter === null}
              onClick={() => { setActiveFilter(null); setQuery(''); }}
            />
            {GIF_EMOJI_FILTERS.map((emoji) => (
              <EmojiFilterChip
                key={emoji}
                label={emoji}
                active={activeFilter === emoji}
                onClick={() => { setActiveFilter(emoji); setQuery(''); }}
              />
            ))}
          </div>
          <ScrollBar orientation="horizontal" />
        </ScrollArea>
      </div>

      {translatedHint && (
        <p className="shrink-0 px-0.5 text-[10px] leading-snug text-muted-foreground">
          Искали: {translatedHint}
        </p>
      )}

      <div
        className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden"
        onScroll={handleScroll}
      >
          {loading ? (
            <div className="flex h-32 items-center justify-center">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : items.length === 0 ? (
            <p className="py-6 text-center text-xs text-muted-foreground">
              Ничего не найдено
            </p>
          ) : (
            <>
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
              {loadingMore && (
                <div className="flex items-center justify-center py-3">
                  <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                </div>
              )}
            </>
          )}
      </div>
    </div>
  );
}
