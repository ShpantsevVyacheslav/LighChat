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

/**
 * Универсальный диалог жалобы — поддерживает оба режима:
 *  - **message-report**: `messageId` задан → жалоба на конкретное сообщение
 *    в чате (заголовок «Пожаловаться на сообщение»).
 *  - **user-report**: `messageId` отсутствует → жалоба на пользователя в
 *    целом (заголовок «Пожаловаться на пользователя»). Используется из
 *    `ChatParticipantProfile` (кнопка рядом с «Заблокировать»), что
 *    закрывает H-2 [audit] паритет с mobile.
 *
 * Backend (`createMessageReportAction` + Zod `CreateMessageReportSchema`)
 * уже принимает `messageId?` опционально и кладёт в одну коллекцию
 * `messageReports`; в админ-панели user-report'ы рендерятся как жалобы
 * без «Hide Message» (см. admin-moderation-panel `!r.messageId` disable).
 */
interface ReportMessageDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversationId: string;
  /** Если задан — это жалоба на сообщение, иначе на пользователя. */
  messageId?: string;
  messageSenderId: string;
  messageSenderName?: string;
  messageText?: string;
  /**
   * Сообщение в E2EE-чате (текст уже расшифрован на стороне репортера).
   * Включает UX-предупреждение: отправляя жалобу, репортер сознательно
   * передаёт администратору расшифрованную копию сообщения. Сервер
   * ключей не имеет — без этой передачи модерация E2EE-чатов
   * невозможна в принципе.
   */
  isE2ee?: boolean;
}

export function ReportMessageDialog({
  open,
  onOpenChange,
  conversationId,
  messageId,
  messageSenderId,
  messageSenderName,
  messageText,
  isE2ee,
}: ReportMessageDialogProps) {
  const isUserReport = !messageId;
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
          <DialogTitle>
            {isUserReport ? t('chat.report.userTitle') : t('chat.report.title')}
          </DialogTitle>
          <DialogDescription>
            {isUserReport ? t('chat.report.userDescription') : t('chat.report.description')}
          </DialogDescription>
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

          {isE2ee && !isUserReport && (
            <div className="rounded-xl border border-amber-500/40 bg-amber-500/10 p-3 text-xs space-y-1">
              <p className="font-medium text-amber-700 dark:text-amber-400">
                Сообщение зашифровано E2E
              </p>
              <p className="text-muted-foreground">
                Чтобы модератор мог рассмотреть жалобу, мы приложим
                расшифрованную копию текста сообщения. Файлы (если есть)
                в этой версии пока не передаются — приложите скриншот в
                комментарии при необходимости.
              </p>
            </div>
          )}

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
