'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { arrayRemove, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
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
  const [isDeleting, setIsDeleting] = useState(false);

  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';
  const conversationRef = useMemoFirebase(() => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null), [firestore, conversationId]);
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  const handleConfirmDelete = async () => {
    if (!conversationRef) return;

    setIsDeleting(true);
    try {
      await deleteDoc(conversationRef);
      if (firestore && authUser?.id && conversationId) {
        try {
          await updateDoc(doc(firestore, 'userChats', authUser.id), {
            conversationIds: arrayRemove(conversationId),
          });
        } catch (indexErr) {
          console.warn('[DeleteConversation] userChats arrayRemove after delete:', indexErr);
        }
      }
      toast({
        title: 'Чат удален',
        description: `Переписка была успешно удалена для всех участников.`,
      });
      router.push('/dashboard/chat');
    } catch (error: any) {
      console.error("Failed to delete chat:", error);
      toast({
        variant: 'destructive',
        title: 'Ошибка при удалении',
        description: error.message,
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
          <AlertDialogTitle>Удалить чат?</AlertDialogTitle>
          <AlertDialogDescription>
            Переписка будет безвозвратно удалена для всех участников. Это действие невозможно отменить.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isDeleting}>Отмена</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirmDelete}
            disabled={isDeleting}
            className="bg-destructive hover:bg-destructive/90 rounded-full font-bold"
          >
            {isDeleting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Удалить для всех
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
