'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { arrayRemove, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
import { useUser as useFirebaseUser } from '@/firebase';
import { useI18n } from '@/hooks/use-i18n';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Loader2 } from 'lucide-react';

export default function DeleteConversationPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { toast } = useToast();
  const { user: authUser } = useAuth();
  const { user: firebaseAuthUser } = useFirebaseUser();
  const { t } = useI18n();
  const [isDeleting, setIsDeleting] = useState(false);

  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';
  const conversationRef = useMemoFirebase(() => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null), [firestore, conversationId]);
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  const handleConfirmDelete = async () => {
    if (!conversationRef) return;

    setIsDeleting(true);
    try {
      await deleteDoc(conversationRef);
      const uid = authUser?.id || firebaseAuthUser?.uid;
      if (firestore && uid && conversationId) {
        try {
          await updateDoc(doc(firestore, 'userChats', uid), {
            conversationIds: arrayRemove(conversationId),
          });
        } catch (indexErr) {
          console.warn('[DeleteConversation] userChats arrayRemove after delete:', indexErr);
        }
      }
      toast({
        title: t('chatOps.deleteDialog.toastDeletedTitle'),
        description: t('chatOps.deleteDialog.toastDeletedDesc'),
      });
      router.push('/dashboard/chat');
    } catch (error: unknown) {
      // Fallback: если Firestore-правило запретило удалять parent-документ
      // (пользователь уже не в `participantIds` — вышел/убрали из группы,
      // устаревший индекс userChats), по крайней мере скрываем чат из своего
      // списка, чтобы UI не зависал на «удалить не удалось». Сам документ
      // `conversations/{id}` остаётся нетронутым — это безопасно для
      // остальных участников. См. firestore.rules §conversations.delete.
      const isPermissionDenied =
        typeof error === 'object' &&
        error != null &&
        'code' in error &&
        (error as { code?: unknown }).code === 'permission-denied';
      const uid = authUser?.id || firebaseAuthUser?.uid;
      if (isPermissionDenied && firestore && uid && conversationId) {
        try {
          await updateDoc(doc(firestore, 'userChats', uid), {
            conversationIds: arrayRemove(conversationId),
          });
          toast({
            title: t('chatOps.deleteDialog.toastHiddenTitle'),
            description: t('chatOps.deleteDialog.toastHiddenDesc'),
          });
          router.push('/dashboard/chat');
          return;
        } catch (hideErr) {
          console.error('[DeleteConversation] hide-from-userChats fallback failed:', hideErr);
        }
      }
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : t('chatOps.deleteDialog.fallbackError');
      console.error(
        'Failed to delete chat:',
        error,
        { conversationId, uid: authUser?.id, participantIds: conversation?.participantIds }
      );
      toast({
        variant: 'destructive',
        title: t('chatOps.deleteDialog.toastErrorTitle'),
        description: message,
      });
      setIsDeleting(false);
    }
  };

  if (isLoading) {
    return (
        <div className="fixed inset-0 bg-background/80 flex items-center justify-center z-50">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
    );
  }

  return (
    <AlertDialog
      open={true}
      onOpenChange={(open) => {
        if (!open) {
          router.back();
        }
      }}
    >
      <AlertDialogContent className="rounded-[2rem] border-none shadow-2xl">
        <AlertDialogHeader>
          <AlertDialogTitle>{t('chatOps.deleteDialog.title')}</AlertDialogTitle>
          <AlertDialogDescription>
            {t('chatOps.deleteDialog.description')}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isDeleting}>{t('chatOps.deleteDialog.cancel')}</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirmDelete}
            disabled={isDeleting}
            className="bg-destructive hover:bg-destructive/90 rounded-full font-bold"
          >
            {isDeleting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {t('chatOps.deleteDialog.confirm')}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
