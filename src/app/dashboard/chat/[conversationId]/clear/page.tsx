
'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase, useUser as useFirebaseUser } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import { logger } from '@/lib/logger';
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
  const { user: firebaseAuthUser } = useFirebaseUser();
  const { toast } = useToast();
  const { t } = useI18n();
  const [isClearing, setIsClearing] = useState(false);

  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';
  const conversationRef = useMemoFirebase(() => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null), [firestore, conversationId]);
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  const handleConfirmClear = async () => {
    if (!conversationRef) return;
    const uid = currentUser?.id || firebaseAuthUser?.uid;
    if (!uid) {
      toast({
        variant: 'destructive',
        title: t('chatOps.clearDialog.toastNoSessionTitle'),
        description: t('chatOps.clearDialog.toastNoSessionDesc'),
      });
      return;
    }

    setIsClearing(true);
    try {
      const now = new Date().toISOString();
      await updateDoc(conversationRef, {
        [`clearedAt.${uid}`]: now,
        // Reset unread counters for this user since history is being hidden/cleared
        [`unreadCounts.${uid}`]: 0,
        [`unreadThreadCounts.${uid}`]: 0
      });
      
      toast({
        title: t('chatOps.clearDialog.toastClearedTitle'),
        description: conversation?.name
          ? t('chatOps.clearDialog.toastClearedDescNamed', { name: conversation.name })
          : t('chatOps.clearDialog.toastClearedDescFallback'),
      });
      router.push('/dashboard/chat');
    } catch (error: unknown) {
      logger.error('clear-history', 'failed', error);
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : t('chatOps.clearDialog.fallbackError');
      toast({
        variant: 'destructive',
        title: t('chatOps.clearDialog.toastErrorTitle'),
        description: message,
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
          <AlertDialogTitle>{t('chatOps.clearDialog.title')}</AlertDialogTitle>
          <AlertDialogDescription>
            {t('chatOps.clearDialog.description')}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isClearing}>{t('chatOps.clearDialog.cancel')}</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirmClear}
            disabled={isClearing}
            className="rounded-full font-bold"
          >
            {isClearing && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {t('chatOps.clearDialog.confirm')}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
