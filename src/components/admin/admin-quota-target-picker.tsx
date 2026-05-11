'use client';

import React, { useMemo, useState } from 'react';
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';
import { Check, ChevronsUpDown, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';

export type AdminQuotaTargetOption = {
  id: string;
  primary: string;
  secondary?: string;
  /** Дополнительные поля для матчинга поиска (login, email и т.д.). */
  haystack?: string[];
};

type Props = {
  value: string;
  onChange: (id: string) => void;
  options: AdminQuotaTargetOption[];
  placeholder: string;
  searchPlaceholder: string;
  emptyMessage: string;
  loading?: boolean;
  disabled?: boolean;
};

function matches(opt: AdminQuotaTargetOption, q: string): boolean {
  if (!q) return true;
  const lower = q.toLowerCase();
  if (opt.id.toLowerCase().includes(lower)) return true;
  if (ruEnSubstringMatch(opt.primary, q)) return true;
  if (opt.secondary && ruEnSubstringMatch(opt.secondary, q)) return true;
  if (opt.haystack) {
    for (const h of opt.haystack) {
      if (!h) continue;
      if (h.toLowerCase().includes(lower)) return true;
      if (ruEnSubstringMatch(h, q)) return true;
    }
  }
  return false;
}

export function AdminQuotaTargetPicker({
  value,
  onChange,
  options,
  placeholder,
  searchPlaceholder,
  emptyMessage,
  loading,
  disabled,
}: Props) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');

  const selected = useMemo(
    () => options.find((o) => o.id === value),
    [options, value],
  );

  // cmdk сам фильтрует по value; передадим только подмножество вручную
  // (чтобы матчинг бил по id/primary/secondary/haystack одновременно).
  const filtered = useMemo(() => {
    if (!search.trim()) return options.slice(0, 50);
    const q = search.trim();
    const hits = options.filter((o) => matches(o, q));
    return hits.slice(0, 50);
  }, [options, search]);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          role="combobox"
          aria-expanded={open}
          disabled={disabled}
          className="justify-between rounded-xl w-full min-w-0"
        >
          <span className="truncate text-left">
            {selected ? (
              <>
                <span className="font-medium">{selected.primary}</span>
                {selected.secondary && (
                  <span className="ml-1 text-muted-foreground text-xs">{selected.secondary}</span>
                )}
              </>
            ) : value ? (
              <span className="font-mono text-xs">{value}</span>
            ) : (
              <span className="text-muted-foreground">{placeholder}</span>
            )}
          </span>
          {loading ? (
            <Loader2 className="ml-2 h-4 w-4 shrink-0 animate-spin opacity-50" />
          ) : (
            <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="p-0 w-[--radix-popover-trigger-width] min-w-[280px]" align="start">
        <Command shouldFilter={false}>
          <CommandInput
            value={search}
            onValueChange={setSearch}
            placeholder={searchPlaceholder}
          />
          <CommandList>
            <CommandEmpty>{loading ? '…' : emptyMessage}</CommandEmpty>
            <CommandGroup>
              {filtered.map((opt) => (
                <CommandItem
                  key={opt.id}
                  value={opt.id}
                  onSelect={() => {
                    onChange(opt.id);
                    setOpen(false);
                    setSearch('');
                  }}
                  className="cursor-pointer"
                >
                  <Check
                    className={cn(
                      'mr-2 h-4 w-4',
                      value === opt.id ? 'opacity-100' : 'opacity-0',
                    )}
                  />
                  <div className="flex flex-col min-w-0">
                    <span className="truncate text-sm">{opt.primary}</span>
                    {opt.secondary && (
                      <span className="truncate text-xs text-muted-foreground">
                        {opt.secondary}
                      </span>
                    )}
                  </div>
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
