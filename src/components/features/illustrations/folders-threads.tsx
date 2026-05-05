import * as React from 'react';
import { CornerDownRight, Folder, FolderOpen, Pin, Star } from 'lucide-react';
import { cn } from '@/lib/utils';

const FOLDERS = [
  { name: 'Все', count: 24, active: false, icon: Folder },
  { name: 'Работа', count: 8, active: true, icon: FolderOpen },
  { name: 'Семья', count: 4, active: false, icon: Folder },
  { name: 'Учёба', count: 12, active: false, icon: Folder },
  { name: 'Избранное', count: 3, active: false, icon: Star },
];

/** Папки чатов слева (`ChatFolderRail`) + список + тред с двумя ответами. */
export function MockFoldersThreads({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full overflow-hidden', className)}>
      <aside className="flex w-[112px] flex-col gap-1 border-r border-black/5 dark:border-white/10 bg-background/40 p-2">
        {FOLDERS.map((f, i) => {
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
          Работа · чаты
        </p>
        {[
          { name: 'Команда · Дизайн', last: 'Юля: пушнул новый вариант', unread: 3, pinned: true },
          { name: 'Маркетинг', last: 'Костя: отчёт готов', unread: 0, pinned: false },
          { name: 'CRM-релизы', last: 'Алина: жду апрува', unread: 1, pinned: false },
        ].map((c, i) => (
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
              <p className="truncate text-[11px] text-muted-foreground">{c.last}</p>
            </div>
            {c.unread ? (
              <span className="rounded-full bg-primary px-1.5 py-0.5 text-[10px] font-bold text-primary-foreground">
                {c.unread}
              </span>
            ) : null}
          </div>
        ))}
        {!compact ? (
          <div
            className="mt-2 rounded-2xl border border-violet-400/25 bg-violet-400/5 p-2 animate-feat-bubble-in"
            style={{ animationDelay: '700ms' }}
          >
            <div className="flex items-center gap-1.5 text-[10px] font-semibold text-violet-500 dark:text-violet-300">
              <CornerDownRight className="h-3 w-3" aria-hidden />
              Тред · «Цена пакета» · 6 ответов
            </div>
            <div className="mt-1.5 flex flex-col gap-1">
              <div className="self-start rounded-xl rounded-tl-md bg-muted px-2 py-1 text-[11px] text-foreground">
                Думаю, 4990 будет в самый раз
              </div>
              <div className="self-end rounded-xl rounded-tr-md bg-primary px-2 py-1 text-[11px] text-primary-foreground">
                Поддерживаю
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
