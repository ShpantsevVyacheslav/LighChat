'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Loader2, HelpCircle, CheckCircle2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { useUser } from '@/firebase';
import { createSupportTicketAction } from '@/actions/support-ticket-actions';
import type { TicketCategory, TicketPriority } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';

export function UserSupportForm() {
  const { user } = useAuth();
  const { user: firebaseUser } = useUser();
  const { t } = useI18n();
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [category, setCategory] = useState<TicketCategory>('other');
  const [priority, setPriority] = useState<TicketPriority>('medium');
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState(false);

  const submit = async () => {
    if (!user || !firebaseUser || !subject.trim() || !message.trim()) return;
    setSending(true);
    // SECURITY: server derives userId/userName/userEmail from this token,
    // never trust the client-side `user` object for ticket attribution.
    const idToken = await firebaseUser.getIdToken();
    const res = await createSupportTicketAction({
      idToken,
      subject: subject.trim(),
      category,
      priority,
      message: message.trim(),
    });
    setSending(false);
    if (res.ok) {
      setSuccess(true);
      setSubject('');
      setMessage('');
    }
  };

  if (success) {
    return (
      <Card className="rounded-3xl">
        <CardContent className="flex flex-col items-center gap-3 py-8">
          <CheckCircle2 className="h-10 w-10 text-green-500" />
          <p className="text-sm font-medium">{t('support.successTitle')}</p>
          <p className="text-xs text-muted-foreground text-center">{t('support.successHint')}</p>
          <Button variant="outline" className="rounded-xl mt-2" onClick={() => setSuccess(false)}>
            {t('support.createAnother')}
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <HelpCircle className="h-5 w-5 text-primary" />
          {t('support.formTitle')}
        </CardTitle>
        <CardDescription>{t('support.formDescription')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label>{t('support.subjectLabel')}</Label>
          <Input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder={t('support.subjectPlaceholder')}
            className="rounded-xl"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-2">
            <Label>{t('support.categoryLabel')}</Label>
            <Select value={category} onValueChange={(v) => setCategory(v as TicketCategory)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="bug">{t('support.categoryBug')}</SelectItem>
                <SelectItem value="account">{t('support.categoryAccount')}</SelectItem>
                <SelectItem value="feature">{t('support.categoryFeature')}</SelectItem>
                <SelectItem value="other">{t('support.categoryOther')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>{t('support.priorityLabel')}</Label>
            <Select value={priority} onValueChange={(v) => setPriority(v as TicketPriority)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="low">{t('support.priorityLow')}</SelectItem>
                <SelectItem value="medium">{t('support.priorityMedium')}</SelectItem>
                <SelectItem value="high">{t('support.priorityHigh')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="space-y-2">
          <Label>{t('support.messageLabel')}</Label>
          <Textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder={t('support.messagePlaceholder')}
            className="rounded-xl min-h-[100px]"
          />
        </div>

        <Button
          onClick={submit}
          disabled={!subject.trim() || !message.trim() || sending}
          className="rounded-full w-full"
        >
          {sending ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
          {t('support.submit')}
        </Button>
      </CardContent>
    </Card>
  );
}
