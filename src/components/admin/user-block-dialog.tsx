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
import { useI18n } from '@/hooks/use-i18n';
import { logger } from '@/lib/logger';

export type BlockDurationPreset = 'forever' | '1h' | '24h' | '7d' | '30d' | 'custom';

const PRESET_KEYS: { id: Exclude<BlockDurationPreset, 'custom'>; labelKey: string; ms: number | null }[] = [
  { id: 'forever', labelKey: 'admin.blockDialog.forever', ms: null },
  { id: '1h', labelKey: 'admin.blockDialog.oneHour', ms: 60 * 60 * 1000 },
  { id: '24h', labelKey: 'admin.blockDialog.twentyFourHours', ms: 24 * 60 * 60 * 1000 },
  { id: '7d', labelKey: 'admin.blockDialog.sevenDays', ms: 7 * 24 * 60 * 60 * 1000 },
  { id: '30d', labelKey: 'admin.blockDialog.thirtyDays', ms: 30 * 24 * 60 * 60 * 1000 },
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
  const { t } = useI18n();
  const { toast } = useToast();

  const computeUntilIso = (): string | null => {
    if (preset === 'forever') return null;
    if (preset === 'custom') {
      const d = Math.max(1, parseInt(customDays, 10) || 1);
      return new Date(Date.now() + d * 24 * 60 * 60 * 1000).toISOString();
    }
    const p = PRESET_KEYS.find((x) => x.id === preset);
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
      toast({ title: t('admin.blockDialog.blocked') });
      onOpenChange(false);
      onDone?.();
    } catch (e) {
      logger.error('user-block', 'block/unblock failed', e);
      toast({ variant: 'destructive', title: t('admin.blockDialog.blockError') });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-2xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{t('admin.blockDialog.title')}</DialogTitle>
          <DialogDescription>
            {target ? t('admin.blockDialog.description').replace('{name}', target.name) : null}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <Label>{t('admin.blockDialog.durationLabel')}</Label>
          <RadioGroup
            value={preset}
            onValueChange={(v) => setPreset(v as BlockDurationPreset)}
            className="grid gap-2"
            disabled={loading}
          >
            {PRESET_KEYS.map((p) => (
              <label
                key={p.id}
                className="flex cursor-pointer items-center gap-3 rounded-xl border border-border/70 p-3 has-[[data-state=checked]]:border-primary/50"
              >
                <RadioGroupItem value={p.id} id={`block-${p.id}`} />
                <span className="text-sm">{t(p.labelKey)}</span>
              </label>
            ))}
            <label className="flex flex-col gap-2 rounded-xl border border-border/70 p-3 has-[[data-state=checked]]:border-primary/50">
              <div className="flex items-center gap-3">
                <RadioGroupItem value="custom" id="block-custom" />
                <span className="text-sm">{t('admin.blockDialog.customDays')}</span>
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
            {t('admin.blockDialog.cancel')}
          </Button>
          <Button type="button" variant="destructive" onClick={() => void handleSubmit()} disabled={loading || !target}>
            {t('admin.blockDialog.block')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
