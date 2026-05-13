'use client';

import * as React from 'react';
import { Folder, FolderOpen, MessageSquare, Pin, Star } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/** Папки чатов слева (`ChatFolderRail`) + список + тред с двумя ответами. */
export function MockFoldersThreads({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  const folders = [
    { name: t.folderAll, count: 24, active: false, icon: Folder },
    { name: t.folderWork, count: 8, active: true, icon: FolderOpen },
    { name: t.folderFamily, count: 4, active: false, icon: Folder },
    { name: t.folderStudy, count: 12, active: false, icon: Folder },
    { name: t.folderStarred, count: 3, active: false, icon: Star },
  ];
  // В реальном `ConversationItem` тред-маркер встроен в строку чата
  // (маленький `<MessageSquare>` бейдж с подписью «Discussion · N»).
  // Здесь второй чат выводит этот бейдж под названием — это и есть
  // визуализация треда в обычном списке чатов, без отдельной плашки.
  const chats = [
    { name: t.chat1Name, last: t.chat1Last, unread: 3, pinned: true, threadCount: 0 },
    { name: t.chat2Name, last: t.chat2Last, unread: 0, pinned: false, threadCount: 4 },
    { name: t.chat3Name, last: t.chat3Last, unread: 1, pinned: false, threadCount: 0 },
  ];
  return (
    <div className={cn('relative flex h-full w-full overflow-hidden', className)}>
      <aside className="flex w-[112px] flex-col gap-1 border-r border-black/5 dark:border-white/10 bg-background/40 p-2">
        {folders.map((f, i) => {
          const Icon = f.icon;
          return (
            <div
              key={f.name}
              className={cn(
                'flex items-center gap-2 rounded-xl px-2 py-1.5 text-[11px] font-semibold animate-feat-bubble-in',
                f.active
                  ? 'bg-violet-400/15 text-violet-500 dark:text-violet-300 ring-1 ring-violet-400/30'
                  : 'text-muted-foreground'
              )}
              style={{ animationDelay: `${i * 70}ms` }}
            >
              <Icon className="h-3.5 w-3.5" aria-hidden />
              <span className="flex-1 truncate">{f.name}</span>
              <span className="text-[10px] opacity-70">{f.count}</span>
            </div>
          );
        })}
      </aside>
      <div className="flex flex-1 flex-col p-3">
        <p className="mb-2 px-1 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">
          {t.folderWorkChats}
        </p>
        {chats.map((c, i) => (
          <div
            key={c.name}
            className="flex items-center gap-2 rounded-xl px-2 py-2 hover:bg-foreground/5 animate-feat-bubble-in"
            style={{ animationDelay: `${400 + i * 80}ms` }}
          >
            <div className="h-7 w-7 rounded-full bg-gradient-to-br from-primary/70 to-primary" />
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1">
                {c.pinned ? <Pin className="h-3 w-3 text-muted-foreground" aria-hidden /> : null}
                <p className="truncate text-xs font-semibold text-foreground">{c.name}</p>
              </div>
              <div className="flex items-center gap-1.5">
                <p className="truncate text-[11px] text-muted-foreground">{c.last}</p>
                {c.threadCount > 0 ? (
                  <span className="inline-flex shrink-0 items-center gap-0.5 rounded-full bg-violet-400/15 px-1.5 py-px text-[9px] font-bold text-violet-500 dark:text-violet-300">
                    <MessageSquare className="h-2.5 w-2.5" aria-hidden />
                    {c.threadCount}
                  </span>
                ) : null}
              </div>
            </div>
            {c.unread ? (
              <span className="rounded-full bg-primary px-1.5 py-0.5 text-[10px] font-bold text-primary-foreground">
                {c.unread}
              </span>
            ) : null}
          </div>
        ))}
        {/* Реальный UI не показывает treads как отдельный «блок» под списком
            чатов — тред-индикатор уже встроен в строку конкретного чата как
            крошечный бейдж `<MessageSquare> N`. */}
      </div>
    </div>
  );
}
