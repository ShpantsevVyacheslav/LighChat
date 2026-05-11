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
import { useI18n } from '@/hooks/use-i18n';
import { useAuth } from '@/hooks/use-auth';
import { useUser } from '@/firebase';
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
  const { user: firebaseUser } = useUser();
  const { toast } = useToast();
  const { t } = useI18n();
  const [reason, setReason] = useState<ReportReason>('inappropriate');
  const [description, setDescription] = useState('');
  const [sending, setSending] = useState(false);

  const submit = async () => {
    if (!user || !firebaseUser) return;
    setSending(true);
    // SECURITY: server derives reporterId/reporterName from this idToken via
    // verifyUserByIdToken; client cannot impersonate another uid.
    const idToken = await firebaseUser.getIdToken();
    const res = await createMessageReportAction({
      idToken,
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
      toast({ title: t('chat.report.submitted') });
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
          <DialogTitle>{t('chat.report.title')}</DialogTitle>
          <DialogDescription>{t('chat.report.description')}</DialogDescription>
        </DialogHeader>
        <div className="space-y-4 pt-2">
          <div className="space-y-2">
            <Label>{t('chat.report.reason')}</Label>
            <Select value={reason} onValueChange={(v) => setReason(v as ReportReason)}>
              <SelectTrigger className="rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="spam">{t('chat.moderation.reasonSpam')}</SelectItem>
                <SelectItem value="harassment">{t('chat.moderation.reasonHarassment')}</SelectItem>
                <SelectItem value="inappropriate">{t('chat.moderation.reasonInappropriate')}</SelectItem>
                <SelectItem value="offensive">{t('chat.moderation.reasonOffensive')}</SelectItem>
                <SelectItem value="violence">{t('chat.moderation.reasonViolence')}</SelectItem>
                <SelectItem value="fraud">{t('chat.moderation.reasonFraud')}</SelectItem>
                <SelectItem value="other">{t('chat.moderation.reasonOther')}</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>{t('chat.report.commentOptional')}</Label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={t('chat.report.detailsPlaceholder')}
              className="rounded-xl min-h-[60px] resize-none"
            />
          </div>

          <Button
            onClick={submit}
            disabled={sending}
            className="w-full rounded-full"
          >
            {sending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
            {t('chat.report.submit')}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
