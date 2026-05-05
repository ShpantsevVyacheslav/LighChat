'use client';

import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Megaphone, Loader2, Plus, Trash2, Edit2 } from 'lucide-react';
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore';
import { useFirestore, useAuth as useFirebaseAuth } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import {
  createAnnouncementAction,
  updateAnnouncementAction,
  deleteAnnouncementAction,
} from '@/actions/announcements-actions';
import type { Announcement, AnnouncementType } from '@/lib/types';

const TYPE_LABELS: Record<AnnouncementType, string> = {
  info: 'Инфо',
  warning: 'Предупреждение',
  maintenance: 'Тех. работы',
  update: 'Обновление',
};

const TYPE_COLORS: Record<AnnouncementType, string> = {
  info: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
  warning: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  maintenance: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400',
  update: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
};

export function AdminAnnouncementsPanel() {
  const firestore = useFirestore();
  const firebaseAuth = useFirebaseAuth();
  const { toast } = useToast();
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [type, setType] = useState<AnnouncementType>('info');
  const [isActive, setIsActive] = useState(true);
  const [dismissible, setDismissible] = useState(true);
  const [expiresAt, setExpiresAt] = useState('');

  useEffect(() => {
    if (!firestore) return;
    const q = query(collection(firestore, 'announcements'), orderBy('createdAt', 'desc'));
    return onSnapshot(q, (snap) => {
      setAnnouncements(snap.docs.map((d) => d.data() as Announcement));
      setLoading(false);
    });
  }, [firestore]);

  const resetForm = () => {
    setEditingId(null);
    setTitle('');
    setBody('');
    setType('info');
    setIsActive(true);
    setDismissible(true);
    setExpiresAt('');
    setShowForm(false);
  };

  const openEdit = (a: Announcement) => {
    setEditingId(a.id);
    setTitle(a.title);
    setBody(a.body);
    setType(a.type);
    setIsActive(a.isActive);
    setDismissible(a.dismissible);
    setExpiresAt(a.expiresAt ?? '');
    setShowForm(true);
  };

  const submit = async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token || !title.trim() || !body.trim()) return;

    setBusy('save');
    if (editingId) {
      const res = await updateAnnouncementAction({
        idToken: token,
        id: editingId,
        patch: {
          title: title.trim(),
          body: body.trim(),
          type,
          isActive,
          dismissible,
          expiresAt: expiresAt || undefined,
        },
      });
      if (res.ok) {
        toast({ title: 'Обновлено' });
        resetForm();
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    } else {
      const res = await createAnnouncementAction({
        idToken: token,
        title: title.trim(),
        body: body.trim(),
        type,
        isActive,
        dismissible,
        expiresAt: expiresAt || undefined,
      });
      if (res.ok) {
        toast({ title: 'Создано' });
        resetForm();
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    }
    setBusy(null);
  };

  const remove = async (id: string) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setBusy(id);
    const res = await deleteAnnouncementAction({ idToken: token, id });
    setBusy(null);
    if (!res.ok) toast({ variant: 'destructive', title: res.error });
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Megaphone className="h-5 w-5 text-primary" />
              Объявления
            </CardTitle>
            <CardDescription>Баннеры, видимые всем пользователям.</CardDescription>
          </div>
          {!showForm && (
            <Button size="sm" className="rounded-xl" onClick={() => setShowForm(true)}>
              <Plus className="h-4 w-4 mr-1" /> Создать
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {showForm && (
          <div className="rounded-2xl border p-4 space-y-3 bg-muted/20">
            <p className="text-sm font-medium">{editingId ? 'Редактировать' : 'Новое объявление'}</p>
            <div className="space-y-2">
              <Label className="text-xs">Заголовок</Label>
              <Input value={title} onChange={(e) => setTitle(e.target.value)} className="rounded-xl" />
            </div>
            <div className="space-y-2">
              <Label className="text-xs">Текст</Label>
              <Textarea value={body} onChange={(e) => setBody(e.target.value)} className="rounded-xl min-h-[80px]" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2">
                <Label className="text-xs">Тип</Label>
                <Select value={type} onValueChange={(v) => setType(v as AnnouncementType)}>
                  <SelectTrigger className="rounded-xl"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {(Object.keys(TYPE_LABELS) as AnnouncementType[]).map((t) => (
                      <SelectItem key={t} value={t}>{TYPE_LABELS[t]}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label className="text-xs">Истекает (ISO дата, опционально)</Label>
                <Input value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} placeholder="2026-12-31" className="rounded-xl" />
              </div>
            </div>
            <div className="flex items-center gap-4">
              <label className="flex items-center gap-2 text-sm cursor-pointer">
                <Switch checked={isActive} onCheckedChange={setIsActive} />
                Активно
              </label>
              <label className="flex items-center gap-2 text-sm cursor-pointer">
                <Switch checked={dismissible} onCheckedChange={setDismissible} />
                Закрываемое
              </label>
            </div>
            <div className="flex gap-2 pt-1">
              <Button onClick={submit} disabled={!title.trim() || !body.trim() || busy === 'save'} className="rounded-full">
                {busy === 'save' && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                {editingId ? 'Сохранить' : 'Создать'}
              </Button>
              <Button variant="outline" onClick={resetForm} className="rounded-full">Отмена</Button>
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex justify-center py-6"><Loader2 className="h-5 w-5 animate-spin" /></div>
        ) : announcements.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-4">Объявлений нет.</p>
        ) : (
          <div className="space-y-2">
            {announcements.map((a) => (
              <div key={a.id} className="rounded-2xl border p-3 space-y-1.5">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="secondary" className={`text-[10px] ${TYPE_COLORS[a.type]}`}>
                    {TYPE_LABELS[a.type]}
                  </Badge>
                  {a.isActive ? (
                    <Badge variant="secondary" className="text-[10px] bg-green-100 text-green-800 dark:bg-green-900/30">Активно</Badge>
                  ) : (
                    <Badge variant="outline" className="text-[10px]">Скрыто</Badge>
                  )}
                  <span className="ml-auto flex gap-1">
                    <Button size="icon" variant="ghost" className="h-7 w-7 rounded-lg" onClick={() => openEdit(a)}>
                      <Edit2 className="h-3.5 w-3.5" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-7 w-7 rounded-lg text-destructive" onClick={() => remove(a.id)} disabled={busy === a.id}>
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </span>
                </div>
                <p className="text-sm font-medium">{a.title}</p>
                <p className="text-xs text-muted-foreground line-clamp-2">{a.body}</p>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
