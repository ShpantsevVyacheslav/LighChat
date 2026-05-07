'use client';

import { useMemo, useState, useEffect, useRef, useCallback } from 'react';
import { collection, limit, orderBy, query } from 'firebase/firestore';
import { File as FileIcon, Image as ImageIcon, Link as LinkIcon, Mic, Play, Video } from 'lucide-react';
import Link from 'next/link';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { ChatAttachment, ChatMessage, User } from '@/lib/types';
import { categorizeAttachmentsFromMessages } from '@/lib/chat-attachments-from-messages';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { VideoCirclePlayer } from '@/components/chat/VideoCirclePlayer';
import { MediaViewer, type MediaViewerItem } from '@/components/chat/media-viewer';
import { isGridGalleryAttachment, isGridGalleryVideo } from '@/components/chat/attachment-visual';
import { HeicAwareChatImage } from '@/components/chat/parts/HeicAwareChatImage';
import { useChatAttachmentDisplaySrc } from '@/components/chat/use-chat-attachment-display-src';

function VideoThumb({ video, onClick }: { video: ChatAttachment; onClick: () => void }) {
  const displaySrc = useChatAttachmentDisplaySrc(video);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [duration, setDuration] = useState<number | null>(null);

  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    const onMeta = () => {
      if (v.duration && isFinite(v.duration)) setDuration(v.duration);
    };
    if (v.readyState >= 1) onMeta();
    else v.addEventListener('loadedmetadata', onMeta);
    return () => v.removeEventListener('loadedmetadata', onMeta);
  }, [displaySrc]);

  const formatTime = (time: number) => {
    if (isNaN(time) || !isFinite(time) || time === 0) return '0:00';
    const m = Math.floor(time / 60);
    const s = Math.floor(time % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <button
      type="button"
      className="relative aspect-square w-full overflow-hidden rounded-xl bg-black"
      onClick={onClick}
    >
      <video
        ref={videoRef}
        src={`${displaySrc}#t=0.1`}
        className="pointer-events-none absolute inset-0 h-full w-full object-cover"
        preload="metadata"
        muted
        playsInline
      />
      <div className="absolute inset-0 flex items-center justify-center bg-black/20">
        <Play className="h-6 w-6 fill-white text-white opacity-80" />
      </div>
      {duration !== null && (
        <div className="absolute bottom-1.5 right-1.5 rounded bg-black/60 px-1.5 py-0.5 font-mono text-[10px] font-bold text-white">
          {formatTime(duration)}
        </div>
      )}
    </button>
  );
}

/** Контент вкладок «Медиа, ссылки и файлы» для правой шторки или вложенного листа (без оболочки страницы). */
export function ConversationMediaPanel({
  conversationId,
  currentUser,
  allUsers = [],
  /** Компенсировать родительский `p-4`, чтобы вкладки и сетка доходили до краёв шторки. */
  edgeToEdge = false,
}: {
  conversationId: string;
  currentUser: User;
  /** Для заголовка просмотрщика медиа (как в основном чате); пустой — подпись «Участник». */
  allUsers?: User[];
  edgeToEdge?: boolean;
}) {
  const firestore = useFirestore();
  const [mediaViewerState, setMediaViewerState] = useState({ isOpen: false, startIndex: 0 });
  const [activeCircleUrl, setActiveCircleUrl] = useState<string | null>(null);

  const messagesQuery = useMemoFirebase(
    () =>
      firestore && conversationId
        ? query(
            collection(firestore, `conversations/${conversationId}/messages`),
            orderBy('createdAt', 'desc'),
            limit(500)
          )
        : null,
    [firestore, conversationId]
  );

  const { data: messageRows, isLoading } = useCollection<ChatMessage>(messagesQuery);
  const messages = useMemo(() => {
    const rows = messageRows ?? [];
    return [...rows].reverse();
  }, [messageRows]);

  const allMediaItems = useMemo((): MediaViewerItem[] => {
    const items: MediaViewerItem[] = [];
    messages.forEach((msg) => {
      if (msg.isDeleted || !msg.attachments) return;
      msg.attachments.forEach((att) => {
        if (isGridGalleryAttachment(att)) {
          items.push({
            ...att,
            messageId: msg.id,
            senderId: msg.senderId,
            createdAt: msg.createdAt,
          });
        }
      });
    });
    return items.filter((item, index, self) => index === self.findIndex((t) => t.url === item.url));
  }, [messages]);

  const handleOpenMediaViewer = useCallback(
    (att: ChatAttachment) => {
      const idx = allMediaItems.findIndex((item) => item.url === att.url);
      if (idx >= 0) setMediaViewerState({ isOpen: true, startIndex: idx });
    },
    [allMediaItems]
  );

  const { media, files, links, audios, circles } = useMemo(
    () => categorizeAttachmentsFromMessages(messages),
    [messages]
  );

  const tabsListClass =
    'no-scrollbar mb-4 grid h-auto w-full grid-cols-5 gap-0.5 rounded-lg border-none bg-zinc-900/70 p-1 sm:gap-1';
  const tabTriggerClass =
    'h-auto min-h-9 w-full min-w-0 justify-center whitespace-normal px-1 py-1.5 text-center text-[11px] leading-tight text-zinc-400 data-[state=active]:bg-zinc-800 data-[state=active]:text-zinc-50 data-[state=active]:shadow-none sm:min-h-10 sm:px-1.5 sm:text-xs';

  const tabsBody = (
    <>
      {isLoading && !messageRows ? (
        <p className="text-sm text-zinc-500">Загрузка…</p>
      ) : (
        <Tabs defaultValue="media" className="w-full">
          <TabsList className={tabsListClass}>
            <TabsTrigger value="media" className={tabTriggerClass}>
              Медиа
            </TabsTrigger>
            <TabsTrigger value="circles" className={tabTriggerClass}>
              Кружки
            </TabsTrigger>
            <TabsTrigger value="files" className={tabTriggerClass}>
              Файлы
            </TabsTrigger>
            <TabsTrigger value="links" className={tabTriggerClass}>
              Ссылки
            </TabsTrigger>
            <TabsTrigger value="audios" className={tabTriggerClass}>
              Аудио
            </TabsTrigger>
          </TabsList>
          <TabsContent value="media">
            {media.length > 0 ? (
              <div className="grid grid-cols-3 gap-1 sm:grid-cols-4">
                {media.map((item, index) =>
                  isGridGalleryVideo(item) ? (
                    <VideoThumb
                      key={`${item.url}-${index}`}
                      video={item}
                      onClick={() => handleOpenMediaViewer(item)}
                    />
                  ) : (
                    <button
                      key={`${item.url}-${index}`}
                      type="button"
                      className="relative aspect-square overflow-hidden rounded-xl bg-muted/25"
                      onClick={() => handleOpenMediaViewer(item)}
                    >
                      <HeicAwareChatImage
                        attachment={item}
                        alt=""
                        className="absolute inset-0 h-full w-full object-cover"
                        loading="lazy"
                        decoding="async"
                      />
                    </button>
                  )
                )}
              </div>
            ) : (
              <Empty Icon={ImageIcon} label="Нет медиа" />
            )}
          </TabsContent>
          <TabsContent value="circles">
            {circles.length > 0 ? (
              <div className="grid grid-cols-3 gap-3 sm:grid-cols-4">
                {circles.map((circle, index) => {
                  const isActive = activeCircleUrl === circle.url;
                  return (
                    <div
                      key={`${circle.url}-${index}`}
                      className={
                        isActive
                          ? 'col-span-full flex min-h-0 justify-center py-4'
                          : 'relative flex aspect-square w-full min-h-0 items-center justify-center overflow-hidden'
                      }
                    >
                      <VideoCirclePlayer
                        attachment={circle}
                        isCurrentUser={circle.senderId === currentUser.id}
                        createdAt={circle.createdAt || new Date().toISOString()}
                        readAt={null}
                        hideTimestamp
                        layout="grid"
                        onClick={() => setActiveCircleUrl(isActive ? null : circle.url)}
                      />
                    </div>
                  );
                })}
              </div>
            ) : (
              <Empty Icon={Video} label="Нет кружков" />
            )}
          </TabsContent>
          <TabsContent value="files">
            {files.length > 0 ? (
              <div className="space-y-2">
                {files.map((file, index) => (
                  <div
                    key={`${file.url}-${index}`}
                    className="flex items-center gap-3 rounded-2xl border border-zinc-800/80 bg-zinc-900/40 p-3"
                  >
                    <div className="rounded-xl bg-emerald-500/15 p-2">
                      <FileIcon className="h-5 w-5 shrink-0 text-emerald-400" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-bold text-zinc-100">{file.name}</p>
                      <p className="text-[10px] font-bold uppercase text-zinc-500">
                        {(file.size / 1024).toFixed(1)} KB
                      </p>
                    </div>
                    <Button variant="ghost" size="icon" className="shrink-0 rounded-full text-zinc-300" asChild>
                      <a href={file.url} target="_blank" rel="noopener noreferrer">
                        <span className="sr-only">Открыть</span>
                        <FileIcon className="h-4 w-4" />
                      </a>
                    </Button>
                  </div>
                ))}
              </div>
            ) : (
              <Empty Icon={FileIcon} label="Нет файлов" />
            )}
          </TabsContent>
          <TabsContent value="links">
            {links.length > 0 ? (
              <div className="space-y-2">
                {links.map((link) => (
                  <div key={link.url} className="rounded-2xl bg-zinc-900/40 p-3">
                    <div className="flex items-center gap-3">
                      <div className="rounded-xl bg-blue-500/15 p-2">
                        <LinkIcon className="h-4 w-4 text-blue-400" />
                      </div>
                      <Link
                        href={link.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="line-clamp-2 break-all text-sm font-medium text-emerald-400 hover:underline"
                      >
                        {link.url}
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <Empty Icon={LinkIcon} label="Нет ссылок" />
            )}
          </TabsContent>
          <TabsContent value="audios">
            {audios.length > 0 ? (
              <div className="space-y-2">
                {audios.map((audio, index) => (
                  <div key={`${audio.url}-${index}`} className="rounded-2xl bg-zinc-900/40 p-3">
                    <div className="flex items-center gap-3">
                      <div className="rounded-xl bg-indigo-500/15 p-2">
                        <Mic className="h-4 w-4 text-indigo-400" />
                      </div>
                      <audio src={audio.url} controls className="h-8 w-full min-w-0" />
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <Empty Icon={Mic} label="Нет аудио" />
            )}
          </TabsContent>
        </Tabs>
      )}
    </>
  );

  return (
    <>
      {edgeToEdge ? (
        <div className="-mx-4 w-[calc(100%+2rem)] max-w-none">{tabsBody}</div>
      ) : (
        tabsBody
      )}

      <MediaViewer
        isOpen={mediaViewerState.isOpen}
        onOpenChange={(open) => setMediaViewerState((prev) => ({ ...prev, isOpen: open }))}
        media={allMediaItems}
        startIndex={mediaViewerState.startIndex}
        currentUserId={currentUser.id}
        allUsers={allUsers}
      />
    </>
  );
}

function Empty({ Icon, label }: { Icon: React.ComponentType<{ className?: string }>; label: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-zinc-500 opacity-80">
      <Icon className="mb-2 h-10 w-10" />
      <p className="text-xs font-medium">{label}</p>
    </div>
  );
}
