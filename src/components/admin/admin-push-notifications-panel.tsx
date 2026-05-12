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
import { useAuth as useFirebaseAuth } from '@/firebase';
import type { UserRole } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';
import { logger } from '@/lib/logger';

type Audience = 'all' | 'admin' | 'worker' | 'uids';

export function AdminPushNotificationsPanel() {
  const { t } = useI18n();
  const { toast } = useToast();
  const firebaseAuth = useFirebaseAuth();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [link, setLink] = useState('/dashboard/chat');
  const [audience, setAudience] = useState<Audience>('worker');
  const [uidsRaw, setUidsRaw] = useState('');
  const [sending, setSending] = useState(false);

  const send = async () => {
    if (!title.trim() || !body.trim()) {
      toast({ variant: 'destructive', title: t('admin.pushNotifications.fillTitleAndBody') });
      return;
    }
    setSending(true);
    try {
      const idToken = await firebaseAuth?.currentUser?.getIdToken();
      if (!idToken) {
        toast({ variant: 'destructive', title: t('admin.pushNotifications.noAuthToken') });
        setSending(false);
        return;
      }
      let res: { success: boolean; error?: string };
      if (audience === 'uids') {
        const ids = uidsRaw
          .split(/[\s,;]+/)
          .map((s) => s.trim())
          .filter(Boolean);
        if (ids.length === 0) {
          toast({ variant: 'destructive', title: t('admin.pushNotifications.atLeastOneUid') });
          setSending(false);
          return;
        }
        res = await sendNotificationToUsers(idToken, ids, title.trim(), body.trim(), link.trim() || '/dashboard/chat', true);
      } else {
        const roles: UserRole[] =
          audience === 'all'
            ? ['admin', 'worker']
            : audience === 'admin'
              ? ['admin']
              : ['worker'];
        res = await sendNotificationToRoles(idToken, roles, title.trim(), body.trim(), link.trim() || '/dashboard/chat');
      }
      if (res.success) {
        toast({ title: t('admin.pushNotifications.sent') });
        setTitle('');
        setBody('');
      } else {
        toast({ variant: 'destructive', title: res.error || t('admin.pushNotifications.sendError') });
      }
    } catch (e) {
      logger.error('admin-push', 'send notification failed', e);
      toast({ variant: 'destructive', title: t('admin.pushNotifications.sendError') });
    } finally {
      setSending(false);
    }
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Bell className="h-5 w-5 text-primary" />
          {t('admin.pushNotifications.title')}
        </CardTitle>
        <CardDescription>
          {t('admin.pushNotifications.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4 max-w-xl">
        <div className="space-y-2">
          <Label>{t('admin.pushNotifications.audienceLabel')}</Label>
          <Select value={audience} onValueChange={(v) => setAudience(v as Audience)}>
            <SelectTrigger className="rounded-xl">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">{t('admin.pushNotifications.audienceAll')}</SelectItem>
              <SelectItem value="admin">{t('admin.pushNotifications.audienceAdmin')}</SelectItem>
              <SelectItem value="worker">{t('admin.pushNotifications.audienceWorker')}</SelectItem>
              <SelectItem value="uids">{t('admin.pushNotifications.audienceUids')}</SelectItem>
            </SelectContent>
          </Select>
        </div>
        {audience === 'uids' && (
          <div className="space-y-2">
            <Label>{t('admin.pushNotifications.userIdListLabel')}</Label>
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
          <Label htmlFor="push-title">{t('admin.pushNotifications.titleLabel')}</Label>
          <Input id="push-title" value={title} onChange={(e) => setTitle(e.target.value)} className="rounded-xl" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="push-body">{t('admin.pushNotifications.bodyLabel')}</Label>
          <Textarea id="push-body" rows={3} value={body} onChange={(e) => setBody(e.target.value)} className="rounded-xl" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="push-link">{t('admin.pushNotifications.linkLabel')}</Label>
          <Input id="push-link" value={link} onChange={(e) => setLink(e.target.value)} className="rounded-xl" />
        </div>
        <Button type="button" onClick={() => void send()} disabled={sending}>
          {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
          {t('admin.pushNotifications.send')}
        </Button>
      </CardContent>
    </Card>
  );
}
