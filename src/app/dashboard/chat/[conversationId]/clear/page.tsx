
'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
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

export default function ClearConversationPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [isClearing, setIsClearing] = useState(false);

  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';
  const conversationRef = useMemoFirebase(() => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null), [firestore, conversationId]);
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  const handleConfirmClear = async () => {
    if (!conversationRef || !currentUser) return;

    setIsClearing(true);
    try {
      const now = new Date().toISOString();
      await updateDoc(conversationRef, {
        [`clearedAt.${currentUser.id}`]: now,
        // Reset unread counters for this user since history is being hidden/cleared
        [`unreadCounts.${currentUser.id}`]: 0,
        [`unreadThreadCounts.${currentUser.id}`]: 0
      });
      
      toast({
        title: 'История очищена',
        description: `История переписки в чате "${conversation?.name || 'с пользователем'}" удалена для вас.`,
      });
      router.push('/dashboard/chat');
    } catch (error: any) {
      console.error("Failed to clear history:", error);
      toast({
        variant: 'destructive',
        title: 'Ошибка',
        description: error.message,
      });
      setIsClearing(false);
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
          <AlertDialogTitle>Очистить историю?</AlertDialogTitle>
          <AlertDialogDescription>
            Все текущие сообщения и обсуждения будут удалены из вашего окна чата. Собеседник по-прежнему будет видеть всю историю.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isClearing}>Отмена</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirmClear}
            disabled={isClearing}
            className="rounded-full font-bold"
          >
            {isClearing && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Очистить для меня
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
