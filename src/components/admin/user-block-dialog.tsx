'use client';

import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Input } from '@/components/ui/input';
import { doc, updateDoc } from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';
import type { User } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';

export type BlockDurationPreset = 'forever' | '1h' | '24h' | '7d' | '30d' | 'custom';

const PRESETS: { id: Exclude<BlockDurationPreset, 'custom'>; label: string; ms: number | null }[] = [
  { id: 'forever', label: 'Навсегда (до разблокировки админом)', ms: null },
  { id: '1h', label: '1 час', ms: 60 * 60 * 1000 },
  { id: '24h', label: '24 часа', ms: 24 * 60 * 60 * 1000 },
  { id: '7d', label: '7 дней', ms: 7 * 24 * 60 * 60 * 1000 },
  { id: '30d', label: '30 дней', ms: 30 * 24 * 60 * 60 * 1000 },
];

interface UserBlockDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  firestore: Firestore | null;
  target: User | null;
  blockedById: string;
  onDone?: () => void;
}

export function UserBlockDialog({
  open,
  onOpenChange,
  firestore,
  target,
  blockedById,
  onDone,
}: UserBlockDialogProps) {
  const [preset, setPreset] = useState<BlockDurationPreset>('24h');
  const [customDays, setCustomDays] = useState('3');
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const computeUntilIso = (): string | null => {
    if (preset === 'forever') return null;
    if (preset === 'custom') {
      const d = Math.max(1, parseInt(customDays, 10) || 1);
      return new Date(Date.now() + d * 24 * 60 * 60 * 1000).toISOString();
    }
    const p = PRESETS.find((x) => x.id === preset);
    if (!p || p.ms == null) return null;
    return new Date(Date.now() + p.ms).toISOString();
  };

  const handleSubmit = async () => {
    if (!firestore || !target) return;
    setLoading(true);
    try {
      const until = computeUntilIso();
      await updateDoc(doc(firestore, 'users', target.id), {
        accountBlock: {
          active: true,
          until,
          blockedAt: new Date().toISOString(),
          blockedBy: blockedById,
        },
      });
      toast({ title: 'Пользователь заблокирован' });
      onOpenChange(false);
      onDone?.();
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось заблокировать' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-2xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Заблокировать пользователя</DialogTitle>
          <DialogDescription>
            {target ? (
              <>
                Учётная запись <strong>{target.name}</strong> не сможет войти в приложение до истечения срока или
                разблокировки.
              </>
            ) : null}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <Label>Срок</Label>
          <RadioGroup
            value={preset}
            onValueChange={(v) => setPreset(v as BlockDurationPreset)}
            className="grid gap-2"
            disabled={loading}
          >
            {PRESETS.map((p) => (
              <label
                key={p.id}
                className="flex cursor-pointer items-center gap-3 rounded-xl border border-border/70 p-3 has-[[data-state=checked]]:border-primary/50"
              >
                <RadioGroupItem value={p.id} id={`block-${p.id}`} />
                <span className="text-sm">{p.label}</span>
              </label>
            ))}
            <label className="flex flex-col gap-2 rounded-xl border border-border/70 p-3 has-[[data-state=checked]]:border-primary/50">
              <div className="flex items-center gap-3">
                <RadioGroupItem value="custom" id="block-custom" />
                <span className="text-sm">Свой срок (дней)</span>
              </div>
              {preset === 'custom' && (
                <Input
                  type="number"
                  min={1}
                  max={3650}
                  value={customDays}
                  onChange={(e) => setCustomDays(e.target.value)}
                  className="max-w-[120px]"
                />
              )}
            </label>
          </RadioGroup>
        </div>
        <DialogFooter className="gap-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={loading}>
            Отмена
          </Button>
          <Button type="button" variant="destructive" onClick={() => void handleSubmit()} disabled={loading || !target}>
            Заблокировать
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
