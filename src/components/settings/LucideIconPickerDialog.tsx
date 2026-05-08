'use client';

import React, { useMemo, useState } from 'react';
import { DynamicIcon, type IconName } from 'lucide-react/dynamic';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Search } from 'lucide-react';
import { filterLucideIconNamesForPicker } from '@/lib/bottom-nav-icons';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

const MAX_PICKER_RESULTS = 240;

type LucideIconPickerDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: string;
  currentName: string;
  onSelect: (name: string) => void | Promise<void>;
};

export function LucideIconPickerDialog({
  open,
  onOpenChange,
  title,
  description,
  currentName,
  onSelect,
}: LucideIconPickerDialogProps) {
  const { t } = useI18n();
  const [query, setQuery] = useState('');

  React.useEffect(() => {
    if (open) setQuery('');
  }, [open]);

  const filtered = useMemo(() => filterLucideIconNamesForPicker(query, MAX_PICKER_RESULTS), [query]);

  const handlePick = (name: string) => {
    void (async () => {
      await Promise.resolve(onSelect(name));
      onOpenChange(false);
    })();
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="flex max-h-[85vh] max-w-md flex-col gap-0 overflow-hidden rounded-2xl p-0 sm:max-w-md">
        <DialogHeader className="shrink-0 space-y-1 border-b border-border/60 px-4 pb-3 pt-4">
          <DialogTitle className="text-base">{title}</DialogTitle>
          {description ? <DialogDescription className="text-xs">{description}</DialogDescription> : null}
          <div className="relative pt-2">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={t('settings.iconPicker.searchPlaceholder')}
              className="h-10 rounded-xl pl-9"
              autoFocus
            />
          </div>
        </DialogHeader>
        <ScrollArea className="h-[min(60vh,420px)] px-3 pb-3">
          <div className="grid grid-cols-6 gap-1.5 py-3 sm:grid-cols-7">
            {filtered.map((name) => {
              const isSel = name === currentName;
              return (
                <button
                  key={name}
                  type="button"
                  title={name}
                  onClick={() => handlePick(name)}
                  className={cn(
                    'flex aspect-square items-center justify-center rounded-xl transition-colors',
                    isSel
                      ? 'bg-primary text-primary-foreground ring-2 ring-primary/30'
                      : 'bg-muted/50 hover:bg-muted dark:bg-white/[0.06] dark:hover:bg-white/10'
                  )}
                >
                  <DynamicIcon
                    name={name as IconName}
                    className="h-5 w-5"
                    strokeWidth={2}
                  />
                </button>
              );
            })}
          </div>
          {filtered.length === 0 && (
            <p className="py-8 text-center text-sm text-muted-foreground">{t('settings.iconPicker.nothingFound')}</p>
          )}
        </ScrollArea>
        <div className="shrink-0 border-t border-border/60 px-4 py-3">
          <Button type="button" variant="ghost" className="w-full rounded-xl" onClick={() => onOpenChange(false)}>
            {t('common.cancel')}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
