
'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, deleteDoc } from 'firebase/firestore';
import type { Meeting } from '@/lib/types';
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

export default function DeleteMeetingPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { toast } = useToast();
  
  const meetingId = typeof params.meetingId === 'string' ? params.meetingId : '';
  const meetingRef = useMemoFirebase(() => (firestore && meetingId ? doc(firestore, 'meetings', meetingId) : null), [firestore, meetingId]);
  const { data: meeting, isLoading } = useDoc<Meeting>(meetingRef);

  const [isDeleting, setIsDeleting] = useState(false);

  const handleConfirmDelete = async () => {
    if (!meetingRef) return;

    setIsDeleting(true);
    try {
      await deleteDoc(meetingRef);
      toast({ title: 'Встреча удалена' });
      router.push('/dashboard/meetings');
    } catch (error: any) {
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
    <AlertDialog open={true} onOpenChange={(open) => !open && !isDeleting && router.back()}>
      <AlertDialogContent className="rounded-[2.5rem]">
        <AlertDialogHeader>
          <AlertDialogTitle>Удалить встречу?</AlertDialogTitle>
          <AlertDialogDescription>
            Вы уверены? Это действие нельзя отменить. Запись о встрече "{meeting?.name}" будет навсегда удалена из истории.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isDeleting}>Отмена</AlertDialogCancel>
          <AlertDialogAction onClick={(e) => { e.preventDefault(); handleConfirmDelete(); }} disabled={isDeleting} className="bg-destructive hover:bg-destructive/90 text-white">
            {isDeleting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Удалить
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
