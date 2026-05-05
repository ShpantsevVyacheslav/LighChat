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
import { createSupportTicketAction } from '@/actions/support-ticket-actions';
import type { TicketCategory, TicketPriority } from '@/lib/types';

export function UserSupportForm() {
  const { user } = useAuth();
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [category, setCategory] = useState<TicketCategory>('other');
  const [priority, setPriority] = useState<TicketPriority>('medium');
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState(false);

  const submit = async () => {
    if (!user || !subject.trim() || !message.trim()) return;
    setSending(true);
    const res = await createSupportTicketAction({
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
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
          <p className="text-sm font-medium">Обращение отправлено!</p>
          <p className="text-xs text-muted-foreground text-center">Мы ответим вам в ближайшее время.</p>
          <Button variant="outline" className="rounded-xl mt-2" onClick={() => setSuccess(false)}>
            Создать ещё
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
          Написать в поддержку
        </CardTitle>
        <CardDescription>Опишите проблему или предложение — мы свяжемся с вами.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label>Тема</Label>
          <Input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder="Кратко опишите проблему"
            className="rounded-xl"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-2">
            <Label>Категория</Label>
            <Select value={category} onValueChange={(v) => setCategory(v as TicketCategory)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="bug">Баг</SelectItem>
                <SelectItem value="account">Аккаунт</SelectItem>
                <SelectItem value="feature">Предложение</SelectItem>
                <SelectItem value="other">Другое</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>Приоритет</Label>
            <Select value={priority} onValueChange={(v) => setPriority(v as TicketPriority)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="low">Низкий</SelectItem>
                <SelectItem value="medium">Средний</SelectItem>
                <SelectItem value="high">Высокий</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="space-y-2">
          <Label>Сообщение</Label>
          <Textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Подробно опишите ситуацию..."
            className="rounded-xl min-h-[100px]"
          />
        </div>

        <Button
          onClick={submit}
          disabled={!subject.trim() || !message.trim() || sending}
          className="rounded-full w-full"
        >
          {sending ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
          Отправить
        </Button>
      </CardContent>
    </Card>
  );
}
