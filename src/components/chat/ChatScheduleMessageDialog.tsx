'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { format } from 'date-fns';
import { ru } from 'date-fns/locale';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { CalendarClock, ShieldAlert } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

const MIN_SCHEDULE_LEAD_SECONDS = 60;

function startOfMinute(d: Date): Date {
  const x = new Date(d);
  x.setSeconds(0, 0);
  return x;
}

function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

interface Preset {
  id: string;
  labelKey: string;
  computeAt: (now: Date) => Date | null;
}

function tonightAt(hour: number, now: Date): Date | null {
  const d = new Date(now);
  d.setHours(hour, 0, 0, 0);
  if (d.getTime() <= now.getTime() + MIN_SCHEDULE_LEAD_SECONDS * 1000) return null;
  return d;
}

function tomorrowAt(hour: number, now: Date): Date {
  const d = new Date(now);
  d.setDate(d.getDate() + 1);
  d.setHours(hour, 0, 0, 0);
  return d;
}

const PRESETS: Preset[] = [
  { id: 'today-18', labelKey: 'chat.schedule.presetToday18', computeAt: (now) => tonightAt(18, now) },
  { id: 'tomorrow-09', labelKey: 'chat.schedule.presetTomorrow09', computeAt: (now) => tomorrowAt(9, now) },
  { id: 'tomorrow-18', labelKey: 'chat.schedule.presetTomorrow18', computeAt: (now) => tomorrowAt(18, now) },
];

export interface ChatScheduleMessageDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Когда `null` — режим создания. Передайте Date для редактирования существующего. */
  initialSendAt?: Date | null;
  /** Для E2EE-чатов показывает предупреждение про plaintext-публикацию. */
  showE2eeWarning?: boolean;
  /** Кнопка submit. */
  confirmLabel?: string;
  onConfirm: (sendAt: Date) => void | Promise<void>;
}

export function ChatScheduleMessageDialog({
  open,
  onOpenChange,
  initialSendAt,
  showE2eeWarning,
  confirmLabel,
  onConfirm,
}: ChatScheduleMessageDialogProps) {
  const { t } = useI18n();
  const now = useMemo(() => startOfMinute(new Date()), [open]);
  const initial = initialSendAt ?? new Date(now.getTime() + 60 * 60 * 1000);

  const [selectedDate, setSelectedDate] = useState<Date>(() => {
    const d = new Date(initial);
    d.setHours(0, 0, 0, 0);
    return d;
  });
  const [hour, setHour] = useState<number>(initial.getHours());
  const [minute, setMinute] = useState<number>(initial.getMinutes() - (initial.getMinutes() % 5));
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (open) {
      const init = initialSendAt ?? new Date(now.getTime() + 60 * 60 * 1000);
      const d = new Date(init);
      d.setHours(0, 0, 0, 0);
      setSelectedDate(d);
      setHour(init.getHours());
      setMinute(init.getMinutes() - (init.getMinutes() % 5));
      setSubmitting(false);
    }
  }, [open, initialSendAt, now]);

  const computedSendAt = useMemo(() => {
    const d = new Date(selectedDate);
    d.setHours(hour, minute, 0, 0);
    return d;
  }, [selectedDate, hour, minute]);

  const isInPast = computedSendAt.getTime() <= now.getTime() + MIN_SCHEDULE_LEAD_SECONDS * 1000;

  const applyPreset = (preset: Preset) => {
    const at = preset.computeAt(now);
    if (!at) return;
    const dateOnly = new Date(at);
    dateOnly.setHours(0, 0, 0, 0);
    setSelectedDate(dateOnly);
    setHour(at.getHours());
    setMinute(at.getMinutes());
  };

  const handleConfirm = async () => {
    if (isInPast || submitting) return;
    setSubmitting(true);
    try {
      await onConfirm(computedSendAt);
      onOpenChange(false);
    } finally {
      setSubmitting(false);
    }
  };

  // Часы 0..23, минуты с шагом 5.
  const hourOptions = useMemo(() => Array.from({ length: 24 }, (_, i) => i), []);
  const minuteOptions = useMemo(() => Array.from({ length: 12 }, (_, i) => i * 5), []);

  // Если выбран сегодняшний день — отсекаем уже прошедшие часы.
  const allowedHours = useMemo(() => {
    if (!isSameDay(selectedDate, now)) return hourOptions;
    return hourOptions.filter((h) => h >= now.getHours());
  }, [selectedDate, now, hourOptions]);

  const allowedMinutes = useMemo(() => {
    if (!isSameDay(selectedDate, now) || hour > now.getHours()) return minuteOptions;
    return minuteOptions.filter((m) => m > now.getMinutes());
  }, [selectedDate, now, hour, minuteOptions]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <CalendarClock className="h-5 w-5 text-primary" />
            {t('chat.schedule.title')}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <div className="flex flex-wrap gap-2">
            {PRESETS.map((p) => {
              const at = p.computeAt(now);
              return (
                <Button
                  key={p.id}
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={!at}
                  onClick={() => applyPreset(p)}
                >
                  {t(p.labelKey)}
                </Button>
              );
            })}
          </div>

          <div className="rounded-xl border bg-muted/40 p-2 flex justify-center">
            <Calendar
              mode="single"
              selected={selectedDate}
              onSelect={(d) => d && setSelectedDate(d)}
              disabled={(d) => {
                const dd = new Date(d);
                dd.setHours(0, 0, 0, 0);
                const today = new Date(now);
                today.setHours(0, 0, 0, 0);
                return dd.getTime() < today.getTime();
              }}
            />
          </div>

          <div className="flex items-end gap-3">
            <div className="space-y-1 flex-1">
              <label className="text-xs text-muted-foreground">{t('chat.schedule.hours')}</label>
              <Select
                value={String(hour)}
                onValueChange={(v) => setHour(Number(v))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="max-h-64">
                  {allowedHours.map((h) => (
                    <SelectItem key={h} value={String(h)}>
                      {pad2(h)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1 flex-1">
              <label className="text-xs text-muted-foreground">{t('chat.schedule.minutes')}</label>
              <Select
                value={String(minute)}
                onValueChange={(v) => setMinute(Number(v))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="max-h-64">
                  {allowedMinutes.map((m) => (
                    <SelectItem key={m} value={String(m)}>
                      {pad2(m)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div
            className={cn(
              'rounded-lg border px-3 py-2 text-sm',
              isInPast
                ? 'border-destructive/40 bg-destructive/10 text-destructive'
                : 'border-primary/30 bg-primary/5 text-foreground'
            )}
          >
            {isInPast ? (
              <span>{t('chat.schedule.mustBeFuture')}</span>
            ) : (
              <span>
                {t('chat.schedule.willSendAt')} <b>{format(computedSendAt, 'd MMMM yyyy, HH:mm', { locale: ru })}</b>
              </span>
            )}
          </div>

          {showE2eeWarning && (
            <div className="rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-xs text-amber-900 dark:text-amber-200 flex gap-2">
              <ShieldAlert className="h-4 w-4 mt-0.5 shrink-0" />
              <span>
                {t('chat.schedule.e2eeWarning')}
              </span>
            </div>
          )}
        </div>

        <DialogFooter className="gap-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            {t('common.cancel')}
          </Button>
          <Button type="button" onClick={handleConfirm} disabled={isInPast || submitting}>
            {confirmLabel ?? t('chat.schedule.confirm')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
