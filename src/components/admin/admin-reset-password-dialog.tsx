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
import type { User } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { adminSetUserPasswordAction } from '@/actions/admin-actions';
import { RefreshCw, Copy } from 'lucide-react';

function generatePassword(length = 14): string {
  const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%';
  const arr = new Uint32Array(length);
  crypto.getRandomValues(arr);
  return Array.from(arr, (x) => chars[x % chars.length]).join('');
}

interface AdminResetPasswordDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  target: User | null;
  getIdToken: () => Promise<string | null>;
}

export function AdminResetPasswordDialog({ open, onOpenChange, target, getIdToken }: AdminResetPasswordDialogProps) {
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const fillRandom = () => setPassword(generatePassword());

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(password);
      toast({ title: 'Пароль скопирован' });
    } catch {
      toast({ variant: 'destructive', title: 'Не удалось скопировать' });
    }
  };

  const submit = async () => {
    if (!target || password.length < 8) {
      toast({ variant: 'destructive', title: 'Пароль не короче 8 символов' });
      return;
    }
    const token = await getIdToken();
    if (!token) {
      toast({ variant: 'destructive', title: 'Нет сессии администратора' });
      return;
    }
    setLoading(true);
    try {
      const res = await adminSetUserPasswordAction({
        idToken: token,
        targetUserId: target.id,
        newPassword: password,
      });
      if (res.ok) {
        toast({ title: 'Пароль обновлён', description: 'Сообщите его пользователю по безопасному каналу.' });
        onOpenChange(false);
        setPassword('');
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) setPassword('');
        onOpenChange(v);
      }}
    >
      <DialogContent className="rounded-2xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Сброс пароля</DialogTitle>
          <DialogDescription>
            Новый пароль для <strong>{target?.name}</strong>. После сохранения пользователь входит с ним вместо старого.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor="new-pwd">Новый пароль</Label>
          <div className="flex gap-2">
            <Input
              id="new-pwd"
              type="text"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Минимум 8 символов"
            />
            <Button type="button" size="icon" variant="outline" onClick={fillRandom} title="Сгенерировать">
              <RefreshCw className="h-4 w-4" />
            </Button>
            <Button type="button" size="icon" variant="outline" onClick={() => void copy()} disabled={!password}>
              <Copy className="h-4 w-4" />
            </Button>
          </div>
        </div>
        <DialogFooter className="gap-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={loading}>
            Отмена
          </Button>
          <Button type="button" onClick={() => void submit()} disabled={loading}>
            Сохранить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
