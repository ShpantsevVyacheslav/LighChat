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
import { useToast } from '@/hooks/use-toast';
import { sendNotificationToRoles, sendNotificationToUsers } from '@/actions/notification-actions';
import { Loader2, Bell } from 'lucide-react';
import type { UserRole } from '@/lib/types';

type Audience = 'all' | 'admin' | 'worker' | 'uids';

export function AdminPushNotificationsPanel() {
  const { toast } = useToast();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [link, setLink] = useState('/dashboard/chat');
  const [audience, setAudience] = useState<Audience>('worker');
  const [uidsRaw, setUidsRaw] = useState('');
  const [sending, setSending] = useState(false);

  const send = async () => {
    if (!title.trim() || !body.trim()) {
      toast({ variant: 'destructive', title: 'Заполните заголовок и текст' });
      return;
    }
    setSending(true);
    try {
      let res: { success: boolean; error?: string };
      if (audience === 'uids') {
        const ids = uidsRaw
          .split(/[\s,;]+/)
          .map((s) => s.trim())
          .filter(Boolean);
        if (ids.length === 0) {
          toast({ variant: 'destructive', title: 'Укажите хотя бы один user id' });
          setSending(false);
          return;
        }
        res = await sendNotificationToUsers(ids, title.trim(), body.trim(), link.trim() || '/dashboard/chat', true);
      } else {
        const roles: UserRole[] =
          audience === 'all'
            ? ['admin', 'worker']
            : audience === 'admin'
              ? ['admin']
              : ['worker'];
        res = await sendNotificationToRoles(roles, title.trim(), body.trim(), link.trim() || '/dashboard/chat');
      }
      if (res.success) {
        toast({ title: 'Уведомления отправлены' });
        setTitle('');
        setBody('');
      } else {
        toast({ variant: 'destructive', title: res.error || 'Ошибка отправки' });
      }
    } catch (e) {
      console.error(e);
      toast({ variant: 'destructive', title: 'Ошибка отправки' });
    } finally {
      setSending(false);
    }
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Bell className="h-5 w-5 text-primary" />
          Push-уведомления
        </CardTitle>
        <CardDescription>
          FCM: сохранение в коллекцию уведомлений пользователя и рассылка на зарегистрированные устройства (токены в{' '}
          <code className="text-xs">fcmTokens</code>). Рассылка с этой панели доставляется принудительно и не учитывает
          личные настройки получателя (тишина, тихие часы, превью).
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4 max-w-xl">
        <div className="space-y-2">
          <Label>Аудитория</Label>
          <Select value={audience} onValueChange={(v) => setAudience(v as Audience)}>
            <SelectTrigger className="rounded-xl">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Все роли (admin + worker)</SelectItem>
              <SelectItem value="admin">Только администраторы</SelectItem>
              <SelectItem value="worker">Только сотрудники (worker)</SelectItem>
              <SelectItem value="uids">По списку user id</SelectItem>
            </SelectContent>
          </Select>
        </div>
        {audience === 'uids' && (
          <div className="space-y-2">
            <Label>User ID (через запятую или с новой строки)</Label>
            <Textarea
              rows={4}
              value={uidsRaw}
              onChange={(e) => setUidsRaw(e.target.value)}
              placeholder="uid1&#10;uid2"
              className="font-mono text-xs"
            />
          </div>
        )}
        <div className="space-y-2">
          <Label htmlFor="push-title">Заголовок</Label>
          <Input id="push-title" value={title} onChange={(e) => setTitle(e.target.value)} className="rounded-xl" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="push-body">Текст</Label>
          <Textarea id="push-body" rows={3} value={body} onChange={(e) => setBody(e.target.value)} className="rounded-xl" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="push-link">Ссылка (deep link)</Label>
          <Input id="push-link" value={link} onChange={(e) => setLink(e.target.value)} className="rounded-xl" />
        </div>
        <Button type="button" onClick={() => void send()} disabled={sending}>
          {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
          Отправить
        </Button>
      </CardContent>
    </Card>
  );
}
