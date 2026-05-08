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
import { useI18n } from '@/hooks/use-i18n';
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
  const { t } = useI18n();

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
      toast({ variant: 'destructive', title: t('chat.pollForm.enterQuestion') });
      return;
    }
    if (filtered.length < 2) {
      toast({ variant: 'destructive', title: t('chat.pollForm.minTwoOptions') });
      return;
    }
    if (quizMode) {
      if (correctOptionIndex < 0 || correctOptionIndex >= filtered.length) {
        toast({ variant: 'destructive', title: t('chat.pollForm.selectCorrect') });
        return;
      }
    }
    let closesAtIso: string | null = null;
    if (closesAtLocal.trim()) {
      const d = new Date(closesAtLocal);
      if (Number.isNaN(d.getTime()) || d.getTime() <= Date.now()) {
        toast({ variant: 'destructive', title: t('chat.pollForm.closesAtFuture') });
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
      toast({ variant: 'destructive', title: t('chat.pollForm.createFailed') });
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
            {t('chat.pollForm.title')}
          </DialogTitle>
          <DialogDescription>
            {t('chat.pollForm.description')}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-2">
          <div className="space-y-2">
            <Label>{t('chat.pollForm.questionLabel')}</Label>
            <Input
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder={t('chat.pollForm.questionPlaceholder')}
              className="rounded-xl"
            />
          </div>
          <div className="space-y-2">
            <Label>{t('chat.pollForm.descriptionLabel')}</Label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={t('chat.pollForm.descriptionPlaceholder')}
              rows={2}
              className="rounded-xl resize-none"
            />
          </div>
          <div className="space-y-2">
            <Label>{t('chat.pollForm.optionsLabel')}</Label>
            {options.map((opt, idx) => (
              <div key={idx} className="flex gap-2">
                <Input
                  value={opt}
                  onChange={(e) => {
                    const next = [...options];
                    next[idx] = e.target.value;
                    setOptions(next);
                  }}
                  placeholder={`${t('chat.pollForm.optionN')} ${idx + 1}`}
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
              {t('chat.pollForm.addOption')}
            </Button>
            {options.length >= MAX_OPTIONS ? (
              <p className="text-xs text-muted-foreground">{t('chat.pollForm.limitReached')} {MAX_OPTIONS}.</p>
            ) : (
              <p className="text-xs text-muted-foreground">
                {t('chat.pollForm.canAddMore')} {MAX_OPTIONS - options.length}.
              </p>
            )}
          </div>

          <div className="space-y-3 rounded-xl border p-3">
            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">{t('chat.pollForm.settingsHeading')}</p>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.anonymousLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.anonymousHint')}</p>
              </div>
              <Switch checked={isAnonymous} onCheckedChange={setIsAnonymous} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.multipleLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.multipleHint')}</p>
              </div>
              <Switch
                checked={allowMultipleAnswers}
                onCheckedChange={setAllowMultipleAnswers}
                disabled={quizMode}
              />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.addOptionsLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.addOptionsHint')}</p>
              </div>
              <Switch checked={allowAddingOptions} onCheckedChange={setAllowAddingOptions} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.revoteLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.revoteHint')}</p>
              </div>
              <Switch checked={allowRevoting} onCheckedChange={setAllowRevoting} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.shuffleLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.shuffleHint')}</p>
              </div>
              <Switch checked={shuffleOptions} onCheckedChange={setShuffleOptions} />
            </div>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium">{t('chat.pollForm.quizLabel')}</p>
                <p className="text-xs text-muted-foreground">{t('chat.pollForm.quizHint')}</p>
              </div>
              <Switch checked={quizMode} onCheckedChange={setQuizOn} />
            </div>
            {quizMode && filteredOptions.length >= 2 && (
              <div className="space-y-2 border-t pt-3">
                <Label>{t('chat.pollForm.correctOption')}</Label>
                <select
                  className="flex h-10 w-full rounded-xl border border-input bg-background px-3 text-sm"
                  value={correctOptionIndex}
                  onChange={(e) => setCorrectOptionIndex(Number(e.target.value))}
                >
                  {filteredOptions.map((o, i) => (
                    <option key={i} value={i}>
                      {o || `${t('chat.pollForm.optionN')} ${i + 1}`}
                    </option>
                  ))}
                </select>
                <Label>{t('chat.pollForm.quizExplanationLabel')}</Label>
                <Textarea
                  value={quizExplanation}
                  onChange={(e) => setQuizExplanation(e.target.value)}
                  placeholder={t('chat.pollForm.quizExplanationPlaceholder')}
                  rows={2}
                  className="rounded-xl resize-none"
                />
              </div>
            )}
            <div className="space-y-2 border-t pt-3">
              <Label>{t('chat.pollForm.closesAtLabel')}</Label>
              <Input
                type="datetime-local"
                value={closesAtLocal}
                onChange={(e) => setClosesAtLocal(e.target.value)}
                className="rounded-xl"
              />
              <p className="text-xs text-muted-foreground">{t('chat.pollForm.closesAtHint')}</p>
            </div>
          </div>
        </div>
        <DialogFooter className="gap-2 sm:gap-0">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={saving}>
            {t('common.cancel')}
          </Button>
          <Button type="button" onClick={handleSubmit} disabled={saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : t('chat.pollForm.publish')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
