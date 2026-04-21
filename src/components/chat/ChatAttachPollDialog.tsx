'use client';

import React, { useState, useMemo } from 'react';
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
import { Textarea } from '@/components/ui/textarea';
import { Plus, Trash2, Loader2, BarChart3 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import type { ChatPollCreateInput } from '@/lib/chat-poll-create';

export type { ChatPollCreateInput } from '@/lib/chat-poll-create';

const MAX_OPTIONS = 12;

interface ChatAttachPollDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreate: (input: ChatPollCreateInput) => void | Promise<void>;
}

export function ChatAttachPollDialog({ open, onOpenChange, onCreate }: ChatAttachPollDialogProps) {
  const [question, setQuestion] = useState('');
  const [description, setDescription] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [isAnonymous, setIsAnonymous] = useState(true);
  const [allowMultipleAnswers, setAllowMultipleAnswers] = useState(false);
  const [allowAddingOptions, setAllowAddingOptions] = useState(false);
  const [allowRevoting, setAllowRevoting] = useState(true);
  const [shuffleOptions, setShuffleOptions] = useState(false);
  const [quizMode, setQuizMode] = useState(false);
  const [correctOptionIndex, setCorrectOptionIndex] = useState(0);
  const [quizExplanation, setQuizExplanation] = useState('');
  const [closesAtLocal, setClosesAtLocal] = useState('');
  const [saving, setSaving] = useState(false);
  const { toast } = useToast();

  const filteredOptions = useMemo(
    () => options.map((o) => o.trim()).filter(Boolean),
    [options]
  );

  const reset = () => {
    setQuestion('');
    setDescription('');
    setOptions(['', '']);
    setIsAnonymous(true);
    setAllowMultipleAnswers(false);
    setAllowAddingOptions(false);
    setAllowRevoting(true);
    setShuffleOptions(false);
    setQuizMode(false);
    setCorrectOptionIndex(0);
    setQuizExplanation('');
    setClosesAtLocal('');
  };

  const handleSubmit = async () => {
    const q = question.trim();
    const filtered = filteredOptions;
    if (!q) {
      toast({ variant: 'destructive', title: 'Введите вопрос' });
      return;
    }
    if (filtered.length < 2) {
      toast({ variant: 'destructive', title: 'Нужно минимум 2 варианта ответа' });
      return;
    }
    if (quizMode) {
      if (correctOptionIndex < 0 || correctOptionIndex >= filtered.length) {
        toast({ variant: 'destructive', title: 'Выберите правильный вариант' });
        return;
      }
    }
    let closesAtIso: string | null = null;
    if (closesAtLocal.trim()) {
      const d = new Date(closesAtLocal);
      if (Number.isNaN(d.getTime()) || d.getTime() <= Date.now()) {
        toast({ variant: 'destructive', title: 'Укажите время закрытия в будущем' });
        return;
      }
      closesAtIso = d.toISOString();
    }

    const input: ChatPollCreateInput = {
      question: q,
      description: description.trim() || undefined,
      options: filtered,
      isAnonymous,
      allowMultipleAnswers: allowMultipleAnswers || undefined,
      allowAddingOptions: allowAddingOptions || undefined,
      allowRevoting: allowRevoting ? undefined : false,
      shuffleOptions: shuffleOptions || undefined,
      quizMode: quizMode || undefined,
      correctOptionIndex: quizMode ? correctOptionIndex : undefined,
      quizExplanation: quizMode && quizExplanation.trim() ? quizExplanation.trim() : undefined,
      closesAt: closesAtIso,
    };

    setSaving(true);
    try {
      await onCreate(input);
      reset();
      onOpenChange(false);
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Не удалось создать опрос' });
    } finally {
      setSaving(false);
    }
  };

  const setQuizOn = (on: boolean) => {
    setQuizMode(on);
    if (on) {
      setAllowMultipleAnswers(false);
      setCorrectOptionIndex(0);
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
            Участники голосуют в сообщении. Доступны настройки как в Telegram: несколько ответов, викторина,
            срок, перемешивание вариантов и др.
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
            <Label>Пояснение (необязательно)</Label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Дополнительный текст к опросу"
              rows={2}
              className="rounded-xl resize-none"
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
              disabled={options.length >= MAX_OPTIONS}
              onClick={() => setOptions([...options, ''])}
            >
              <Plus className="mr-2 h-4 w-4" />
              Добавить вариант
            </Button>
            {options.length >= MAX_OPTIONS ? (
              <p className="text-xs text-muted-foreground">Достигнут лимит {MAX_OPTIONS} вариантов.</p>
            ) : (
              <p className="text-xs text-muted-foreground">
                Можно добавить ещё {MAX_OPTIONS - options.length} вариант(ов).
              </p>
            )}
          </div>

          <div className="space-y-3 rounded-xl border p-3">
            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Настройки</p>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Анонимное голосование</p>
                <p className="text-xs text-muted-foreground">Не показывать, кто за что голосовал</p>
              </div>
              <Switch checked={isAnonymous} onCheckedChange={setIsAnonymous} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Несколько ответов</p>
                <p className="text-xs text-muted-foreground">Можно выбрать несколько вариантов</p>
              </div>
              <Switch
                checked={allowMultipleAnswers}
                onCheckedChange={setAllowMultipleAnswers}
                disabled={quizMode}
              />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Добавление вариантов</p>
                <p className="text-xs text-muted-foreground">Участники могут предложить свой вариант</p>
              </div>
              <Switch checked={allowAddingOptions} onCheckedChange={setAllowAddingOptions} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Можно изменить голос</p>
                <p className="text-xs text-muted-foreground">Переголосование до закрытия опроса</p>
              </div>
              <Switch checked={allowRevoting} onCheckedChange={setAllowRevoting} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Перемешать варианты</p>
                <p className="text-xs text-muted-foreground">Порядок строк свой у каждого участника</p>
              </div>
              <Switch checked={shuffleOptions} onCheckedChange={setShuffleOptions} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">Режим викторины</p>
                <p className="text-xs text-muted-foreground">Один правильный ответ и пояснение</p>
              </div>
              <Switch checked={quizMode} onCheckedChange={setQuizOn} />
            </div>
            {quizMode && filteredOptions.length >= 2 && (
              <div className="space-y-2 border-t pt-3">
                <Label>Правильный вариант</Label>
                <select
                  className="flex h-10 w-full rounded-xl border border-input bg-background px-3 text-sm"
                  value={correctOptionIndex}
                  onChange={(e) => setCorrectOptionIndex(Number(e.target.value))}
                >
                  {filteredOptions.map((o, i) => (
                    <option key={i} value={i}>
                      {o || `Вариант ${i + 1}`}
                    </option>
                  ))}
                </select>
                <Label>Пояснение после ответа (необязательно)</Label>
                <Textarea
                  value={quizExplanation}
                  onChange={(e) => setQuizExplanation(e.target.value)}
                  placeholder="Текст для неверного ответа или подсказка"
                  rows={2}
                  className="rounded-xl resize-none"
                />
              </div>
            )}
            <div className="space-y-2 border-t pt-3">
              <Label>Закрыть опрос (необязательно)</Label>
              <Input
                type="datetime-local"
                value={closesAtLocal}
                onChange={(e) => setClosesAtLocal(e.target.value)}
                className="rounded-xl"
              />
              <p className="text-xs text-muted-foreground">По наступлении времени опрос завершится автоматически.</p>
            </div>
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
