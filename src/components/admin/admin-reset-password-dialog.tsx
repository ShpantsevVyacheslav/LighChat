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
import { useI18n } from '@/hooks/use-i18n';

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
  const { t } = useI18n();
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const fillRandom = () => setPassword(generatePassword());

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(password);
      toast({ title: t('admin.resetPassword.passwordCopied') });
    } catch {
      toast({ variant: 'destructive', title: t('admin.resetPassword.copyFailed') });
    }
  };

  const submit = async () => {
    if (!target || password.length < 8) {
      toast({ variant: 'destructive', title: t('admin.resetPassword.passwordMin') });
      return;
    }
    const token = await getIdToken();
    if (!token) {
      toast({ variant: 'destructive', title: t('admin.resetPassword.noAdminSession') });
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
        toast({ title: t('admin.resetPassword.passwordUpdated'), description: t('admin.resetPassword.passwordUpdatedDesc') });
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
          <DialogTitle>{t('admin.resetPassword.title')}</DialogTitle>
          <DialogDescription>
            {t('admin.resetPassword.description').replace('{name}', target?.name ?? '')}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor="new-pwd">{t('admin.resetPassword.newPasswordLabel')}</Label>
          <div className="flex gap-2">
            <Input
              id="new-pwd"
              type="text"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={t('admin.resetPassword.newPasswordPlaceholder')}
            />
            <Button type="button" size="icon" variant="outline" onClick={fillRandom} title={t('admin.resetPassword.generateTitle')}>
              <RefreshCw className="h-4 w-4" />
            </Button>
            <Button type="button" size="icon" variant="outline" onClick={() => void copy()} disabled={!password}>
              <Copy className="h-4 w-4" />
            </Button>
          </div>
        </div>
        <DialogFooter className="gap-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={loading}>
            {t('admin.resetPassword.cancel')}
          </Button>
          <Button type="button" onClick={() => void submit()} disabled={loading}>
            {t('admin.resetPassword.save')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
