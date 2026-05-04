import * as React from 'react';
import { Shield } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockSwitchRow } from '../mocks/mock-switch-row';

export function MockPrivacy({ className, compact }: { className?: string; compact?: boolean }) {
  return (
    <div className={cn('relative flex h-full w-full flex-col gap-2 p-3', className)}>
      <div className="flex items-center gap-2 rounded-2xl border border-primary/20 bg-primary/10 px-3 py-2">
        <Shield className="h-4 w-4 text-primary" aria-hidden />
        <div className="leading-tight">
          <p className="text-xs font-semibold text-foreground">Приватность</p>
          <p className="text-[10px] text-muted-foreground">Решайте, что видят другие.</p>
        </div>
      </div>
      <div className="grid flex-1 gap-1.5 overflow-hidden">
        <MockSwitchRow label="Статус «онлайн»" hint="Видят, что вы сейчас в сети" on />
        <MockSwitchRow label="Был в сети" hint="Точное время последнего визита" on={false} />
        <MockSwitchRow label="Отчёты о прочтении" hint="Двойная галочка собеседнику" on />
        {!compact ? (
          <>
            <MockSwitchRow label="Глобальный поиск" hint="Найти вас по имени могут все" on={false} />
            <MockSwitchRow label="Добавление в группы" hint="Только из контактов" on />
          </>
        ) : null}
      </div>
    </div>
  );
}
