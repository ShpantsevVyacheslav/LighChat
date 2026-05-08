'use client';

/**
 * [audit M-009] Извлечён из `ChatWindow.tsx` (раньше — 4 useState'а +
 * 50-строчный useCallback inline). Теперь чат-окну остаётся только
 * `openSaveDialog(att, mode)` для пункта меню «Сохранить как стикер»
 * + проброс возвращённых полей в `StickerPackPickerDialog`.
 *
 * Логика: пользователь нажимает «сохранить вложение в стикерпак»,
 * открывается диалог с выбором/созданием пака, после `confirmToPack(packId)`
 * вложение либо копируется как есть (`copy`), либо нормализуется до
 * квадратной png (`normalize_sticker`). Toast'ы покрывают success +
 * file-too-large + cors + generic.
 */

import { useCallback, useState } from 'react';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';
import {
  addChatAttachmentToUserStickerPack,
  addChatImageAsSquareStickerToPack,
  createUserStickerPack,
} from '@/lib/user-sticker-packs-client';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';
import type { ChatAttachment } from '@/lib/types';

export type StickerSaveMode = 'copy' | 'normalize_sticker';

type ToastFn = (opts: {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;

type TFn = (key: string, params?: Record<string, string | number>) => string;

export type StickerSaveFlow = {
  /** Открыт ли диалог. */
  open: boolean;
  /** Текущее вложение, переданное на сохранение. */
  attachment: ChatAttachment | null;
  /** Режим: копия или normalize → square sticker. */
  mode: StickerSaveMode;
  /** Идёт операция (блокирует UI диалога). */
  busy: boolean;
  /** Открыть диалог для сохранения вложения. */
  openSaveDialog: (attachment: ChatAttachment, mode?: StickerSaveMode) => void;
  /** Закрыть диалог. Вызывается из `onOpenChange(false)`. */
  closeDialog: () => void;
  /** Подтверждение пользователем выбранного пака — основной экшен. */
  confirmToPack: (packId: string) => Promise<void>;
  /** Создание нового пака (passthrough в диалог). Возвращает packId или null. */
  createPack: (name: string) => Promise<string | null>;
};

export function useStickerSaveFlow(opts: {
  firestore: Firestore | null;
  storage: FirebaseStorage | null;
  currentUserId: string;
  toast: ToastFn;
  t: TFn;
}): StickerSaveFlow {
  const { firestore, storage, currentUserId, toast, t } = opts;

  const [open, setOpen] = useState(false);
  const [attachment, setAttachment] = useState<ChatAttachment | null>(null);
  const [mode, setMode] = useState<StickerSaveMode>('copy');
  const [busy, setBusy] = useState(false);

  const openSaveDialog = useCallback(
    (att: ChatAttachment, m: StickerSaveMode = 'copy') => {
      setMode(m);
      setAttachment(att);
      setOpen(true);
    },
    [],
  );

  const closeDialog = useCallback(() => {
    setOpen(false);
    setAttachment(null);
    setMode('copy');
  }, []);

  const confirmToPack = useCallback(
    async (packId: string) => {
      if (!attachment || !firestore || !storage) return;
      setBusy(true);
      try {
        const r =
          mode === 'normalize_sticker'
            ? await addChatImageAsSquareStickerToPack(
                attachment,
                packId,
                currentUserId,
                firestore,
                storage,
              )
            : await addChatAttachmentToUserStickerPack(
                attachment,
                packId,
                currentUserId,
                firestore,
                storage,
              );
        if (r.ok) {
          toast({
            title: t('chat.savedToStickerPack'),
            description:
              mode === 'normalize_sticker'
                ? t('chat.savedToStickerPackNormalized')
                : undefined,
          });
          closeDialog();
        } else if (r.error === 'file_too_large') {
          toast({
            title: t('chat.fileTooLarge'),
            description: t('chat.fileSizeLimitMb', {
              size: Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024)),
            }),
            variant: 'destructive',
          });
        } else if (r.error === 'fetch_failed') {
          toast({
            title: t('chat.downloadFailedCors'),
            description: t('chat.downloadFailedCorsHint'),
            variant: 'destructive',
          });
        } else {
          toast({ title: t('chat.saveFailed'), variant: 'destructive' });
        }
      } finally {
        setBusy(false);
      }
    },
    [attachment, mode, firestore, storage, currentUserId, toast, t, closeDialog],
  );

  const createPack = useCallback(
    async (name: string) => {
      if (!firestore) return null;
      return createUserStickerPack(firestore, currentUserId, name);
    },
    [firestore, currentUserId],
  );

  return {
    open,
    attachment,
    mode,
    busy,
    openSaveDialog,
    closeDialog,
    confirmToPack,
    createPack,
  };
}
