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
import { useUser, useStorage } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import { createMessageReportAction } from '@/actions/moderation-actions';
import type {
  ChatAttachment,
  ChatMessageE2eeAttachmentEnvelopeV2,
  ReportReason,
} from '@/lib/types';
import {
  randomEvidenceNonce,
  uploadE2eeEvidence,
} from '@/lib/moderation/upload-e2ee-evidence';
import { logger } from '@/lib/logger';

/**
 * Универсальный диалог жалобы — поддерживает оба режима:
 *  - **message-report**: `messageId` задан → жалоба на конкретное сообщение
 *    в чате.
 *  - **user-report**: `messageId` отсутствует → жалоба на пользователя.
 *
 * Для E2EE-сообщений с вложениями репортер опционально передаёт
 * расшифрованную копию (evidence) в админ-only Storage-зону через
 * `uploadE2eeEvidence`. UI явно предупреждает о disclosure'е.
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
  /** Включает E2EE-предупреждение и блок «приложить evidence». */
  isE2ee?: boolean;
  /** E2EE envelope'ы — для evidence-аплоада. null элементы пропускаются. */
  e2eeAttachments?: Array<ChatMessageE2eeAttachmentEnvelopeV2 | null>;
  /** Эпоха сообщения для получения chat key. */
  messageEpoch?: number;
  /** Геттер chat key, обычно `e2eeConv.getChatKeyRawV2ForEpoch`. */
  getChatKeyRawV2ForEpoch?: (epoch: number) => Promise<ArrayBuffer | null>;
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
  e2eeAttachments,
  messageEpoch,
  getChatKeyRawV2ForEpoch,
}: ReportMessageDialogProps) {
  const isUserReport = !messageId;
  const { user } = useAuth();
  const { user: firebaseUser } = useUser();
  const storage = useStorage();
  const { toast } = useToast();
  const { t } = useI18n();
  const [reason, setReason] = useState<ReportReason>('inappropriate');
  const [description, setDescription] = useState('');
  const [sending, setSending] = useState(false);
  const [includeMedia, setIncludeMedia] = useState(true);
  const [evidenceStage, setEvidenceStage] = useState<'idle' | 'uploading' | 'done'>('idle');

  const realE2eeEnvelopes = (e2eeAttachments ?? []).filter(
    (e): e is ChatMessageE2eeAttachmentEnvelopeV2 => !!e,
  );
  const hasE2eeMedia =
    !!isE2ee && !isUserReport && realE2eeEnvelopes.length > 0 && !!messageId &&
    typeof messageEpoch === 'number' && !!getChatKeyRawV2ForEpoch && !!storage;

  const submit = async () => {
    if (!user || !firebaseUser) return;
    setSending(true);
    try {
      const idToken = await firebaseUser.getIdToken();

      let evidenceNonce: string | undefined;
      let evidenceAttachments: ChatAttachment[] | undefined;

      if (hasE2eeMedia && includeMedia) {
        setEvidenceStage('uploading');
        try {
          const nonce = randomEvidenceNonce();
          const uploaded = await uploadE2eeEvidence({
            storage: storage!,
            conversationId,
            messageId: messageId!,
            reporterUid: user.id,
            evidenceNonce: nonce,
            envelopes: realE2eeEnvelopes,
            getChatKeyRawV2ForEpoch: getChatKeyRawV2ForEpoch!,
            messageEpoch: messageEpoch!,
          });
          if (uploaded.length > 0) {
            evidenceNonce = nonce;
            evidenceAttachments = uploaded;
          }
          setEvidenceStage('done');
        } catch (e) {
          logger.error('moderation-report', 'uploadE2eeEvidence', e);
          setEvidenceStage('idle');
          toast({
            variant: 'destructive',
            title: 'Не удалось приложить evidence-копию',
            description: 'Жалоба будет отправлена без вложений.',
          });
        }
      }

      const res = await createMessageReportAction({
        idToken,
        conversationId,
        messageId,
        messageSenderId,
        messageSenderName,
        messageText,
        reason,
        description: description.trim() || undefined,
        evidenceNonce,
        evidenceAttachments,
      });
      if (res.ok) {
        toast({ title: t('chat.report.submitted') });
        onOpenChange(false);
        setDescription('');
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    } finally {
      setSending(false);
      setEvidenceStage('idle');
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
            <div className="rounded-xl border border-amber-500/40 bg-amber-500/10 p-3 text-xs space-y-2">
              <p className="font-medium text-amber-700 dark:text-amber-400">
                Сообщение зашифровано E2E
              </p>
              <p className="text-muted-foreground">
                Чтобы модератор мог рассмотреть жалобу, мы приложим
                расшифрованную копию текста сообщения.
                {hasE2eeMedia && ' Вложения (файлы) будут расшифрованы локально и переданы как evidence в admin-only зону Storage — никто, кроме админа, к ним не получит доступа.'}
              </p>
              {hasE2eeMedia && (
                <label className="flex items-center gap-2 cursor-pointer pt-1">
                  <input
                    type="checkbox"
                    checked={includeMedia}
                    onChange={(e) => setIncludeMedia(e.target.checked)}
                    disabled={sending}
                  />
                  <span>Приложить вложения ({realE2eeEnvelopes.length} шт.)</span>
                </label>
              )}
              {evidenceStage === 'uploading' && (
                <p className="flex items-center gap-1 text-muted-foreground">
                  <Loader2 className="h-3 w-3 animate-spin" /> Шифрованная расшифровка и upload evidence…
                </p>
              )}
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
