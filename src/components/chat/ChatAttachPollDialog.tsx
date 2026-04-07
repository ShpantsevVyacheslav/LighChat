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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Plus, Trash2, Loader2, BarChart3 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

export type ChatPollCreateInput = {
  question: string;
  options: string[];
  isAnonymous: boolean;
};

interface ChatAttachPollDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreate: (input: ChatPollCreateInput) => void | Promise<void>;
}

export function ChatAttachPollDialog({ open, onOpenChange, onCreate }: ChatAttachPollDialogProps) {
  const [question, setQuestion] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [isAnonymous, setIsAnonymous] = useState(true);
  const [saving, setSaving] = useState(false);
  const { toast } = useToast();

  const reset = () => {
    setQuestion('');
    setOptions(['', '']);
    setIsAnonymous(true);
  };

  const handleSubmit = async () => {
    const q = question.trim();
    const filtered = options.map((o) => o.trim()).filter(Boolean);
    if (!q) {
      toast({ variant: 'destructive', title: 'Введите вопрос' });
      return;
    }
    if (filtered.length < 2) {
      toast({ variant: 'destructive', title: 'Нужно минимум 2 варианта ответа' });
      return;
    }
    setSaving(true);
    try {
      await onCreate({ question: q, options: filtered, isAnonymous });
      reset();
      onOpenChange(false);
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось создать опрос' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!saving) {
          if (!v) reset();
          onOpenChange(v);
        }
      }}
    >
      <DialogContent className="max-h-[90vh] overflow-y-auto rounded-2xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <BarChart3 className="h-5 w-5 text-primary" />
            Опрос в чате
          </DialogTitle>
          <DialogDescription>
            Как в видеоконференции: участники голосуют в сообщении; при полном составе голосов опрос можно завершить
            автоматически.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-2">
          <div className="space-y-2">
            <Label>Вопрос</Label>
            <Input
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="Например: Во сколько встречаемся?"
              className="rounded-xl"
            />
          </div>
          <div className="space-y-2">
            <Label>Варианты</Label>
            {options.map((opt, idx) => (
              <div key={idx} className="flex gap-2">
                <Input
                  value={opt}
                  onChange={(e) => {
                    const next = [...options];
                    next[idx] = e.target.value;
                    setOptions(next);
                  }}
                  placeholder={`Вариант ${idx + 1}`}
                  className="rounded-xl"
                />
                {options.length > 2 && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="shrink-0"
                    onClick={() => setOptions(options.filter((_, i) => i !== idx))}
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                )}
              </div>
            ))}
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="w-full rounded-xl"
              onClick={() => setOptions([...options, ''])}
            >
              <Plus className="mr-2 h-4 w-4" />
              Добавить вариант
            </Button>
          </div>
          <div className="flex items-center justify-between rounded-xl border p-3">
            <div>
              <p className="text-sm font-medium">{isAnonymous ? 'Анонимное голосование' : 'Видно, кто как голосовал'}</p>
              <p className="text-xs text-muted-foreground">Как в опросах конференции</p>
            </div>
            <Switch checked={isAnonymous} onCheckedChange={setIsAnonymous} />
          </div>
        </div>
        <DialogFooter className="gap-2 sm:gap-0">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={saving}>
            Отмена
          </Button>
          <Button type="button" onClick={handleSubmit} disabled={saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Опубликовать'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
