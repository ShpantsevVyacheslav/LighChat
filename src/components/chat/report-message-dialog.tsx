'use client';

import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { useToast } from '@/hooks/use-toast';
import { createMessageReportAction } from '@/actions/moderation-actions';
import type { ReportReason } from '@/lib/types';

interface ReportMessageDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversationId: string;
  messageId: string;
  messageSenderId: string;
  messageSenderName?: string;
  messageText?: string;
}

export function ReportMessageDialog({
  open,
  onOpenChange,
  conversationId,
  messageId,
  messageSenderId,
  messageSenderName,
  messageText,
}: ReportMessageDialogProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const [reason, setReason] = useState<ReportReason>('inappropriate');
  const [description, setDescription] = useState('');
  const [sending, setSending] = useState(false);

  const submit = async () => {
    if (!user) return;
    setSending(true);
    const res = await createMessageReportAction({
      reporterId: user.id,
      reporterName: user.name,
      conversationId,
      messageId,
      messageSenderId,
      messageSenderName,
      messageText,
      reason,
      description: description.trim() || undefined,
    });
    setSending(false);
    if (res.ok) {
      toast({ title: 'Жалоба отправлена' });
      onOpenChange(false);
      setDescription('');
    } else {
      toast({ variant: 'destructive', title: res.error });
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-3xl max-w-sm">
        <DialogHeader>
          <DialogTitle>Пожаловаться</DialogTitle>
          <DialogDescription>Сообщение будет рассмотрено администратором.</DialogDescription>
        </DialogHeader>
        <div className="space-y-4 pt-2">
          <div className="space-y-2">
            <Label>Причина</Label>
            <Select value={reason} onValueChange={(v) => setReason(v as ReportReason)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="spam">Спам</SelectItem>
                <SelectItem value="harassment">Оскорбление</SelectItem>
                <SelectItem value="inappropriate">Неприемлемый контент</SelectItem>
                <SelectItem value="other">Другое</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>Комментарий (необязательно)</Label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Дополнительные детали..."
              className="rounded-xl min-h-[60px] resize-none"
            />
          </div>

          <Button
            onClick={submit}
            disabled={sending}
            className="w-full rounded-full"
          >
            {sending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
            Отправить жалобу
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
