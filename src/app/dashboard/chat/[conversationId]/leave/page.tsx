'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, writeBatch, arrayRemove } from 'firebase/firestore';
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

export default function LeaveConversationPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [isLeaving, setIsLeaving] = useState(false);

  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';
  const conversationRef = useMemoFirebase(() => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null), [firestore, conversationId]);
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);
  
  const isCreator = conversation?.createdByUserId === currentUser?.id;

  const handleConfirmLeave = async () => {
    if (!conversationRef || !currentUser || !conversation) return;
    
    if (isCreator) {
        toast({ variant: "destructive", title: "Действие запрещено", description: "Создатель не может покинуть группу. Передайте права или удалите группу." });
        router.back();
        return;
    }

    setIsLeaving(true);
    
    const newParticipantIds = conversation.participantIds.filter(id => id !== currentUser.id);
    const newAdminIds = (conversation.adminIds || []).filter(id => id !== currentUser.id);
    const newParticipantInfo = { ...conversation.participantInfo };
    delete newParticipantInfo[currentUser.id];
    const lastMessageText = `${currentUser.name} покинул(а) группу.`;

    try {
        const batch = writeBatch(firestore);

        batch.update(conversationRef, {
            participantIds: newParticipantIds,
            participantInfo: newParticipantInfo,
            adminIds: newAdminIds,
            lastMessageText: lastMessageText,
            lastMessageSenderId: 'system',
            lastMessageTimestamp: new Date().toISOString(),
        });
        
        const userChatIndexRef = doc(firestore, 'userChats', currentUser.id);
        batch.update(userChatIndexRef, {
            conversationIds: arrayRemove(conversation.id)
        });

        await batch.commit();

        toast({ title: "Вы покинули группу" });
        router.push('/dashboard/chat');
    } catch (e: any) {
        console.error("Failed to leave group:", e);
        toast({ variant: "destructive", title: "Ошибка", description: "Не удалось покинуть группу." });
        setIsLeaving(false);
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
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            {isCreator ? "Действие запрещено" : "Покинуть группу?"}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {isCreator ? "Создатель не может покинуть группу. Вы можете удалить группу или передать права другому администратору." :
                <>Вы уверены, что хотите покинуть группу <span className="font-semibold">{conversation?.name}</span>?</>
            }
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
            <AlertDialogCancel disabled={isLeaving}>Отмена</AlertDialogCancel>
            {!isCreator && (
              <AlertDialogAction onClick={handleConfirmLeave} disabled={isLeaving || isLoading} className="bg-destructive hover:bg-destructive/90 rounded-full">
                  {isLeaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Да, покинуть
              </AlertDialogAction>
            )}
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
