
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
import { useI18n } from '@/hooks/use-i18n';

export default function DeleteMeetingPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  
  const meetingId = typeof params.meetingId === 'string' ? params.meetingId : '';
  const meetingRef = useMemoFirebase(() => (firestore && meetingId ? doc(firestore, 'meetings', meetingId) : null), [firestore, meetingId]);
  const { data: meeting, isLoading } = useDoc<Meeting>(meetingRef);

  const [isDeleting, setIsDeleting] = useState(false);

  const handleConfirmDelete = async () => {
    if (!meetingRef) return;

    setIsDeleting(true);
    try {
      await deleteDoc(meetingRef);
      toast({ title: t('meetingsPage.deleteMeeting.toastDeleted') });
      router.push('/dashboard/meetings');
    } catch (error: unknown) {
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : t('meetingsPage.deleteMeeting.fallbackError');
      toast({
        variant: 'destructive',
        title: t('meetingsPage.deleteMeeting.toastErrorTitle'),
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
    <AlertDialog open={true} onOpenChange={(open) => !open && !isDeleting && router.back()}>
      <AlertDialogContent className="rounded-[2.5rem]">
        <AlertDialogHeader>
          <AlertDialogTitle>{t('meetingsPage.deleteMeeting.title')}</AlertDialogTitle>
          <AlertDialogDescription>
            {t('meetingsPage.deleteMeeting.descriptionNamed', { name: meeting?.name ?? '' })}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isDeleting}>{t('meetingsPage.deleteMeeting.cancel')}</AlertDialogCancel>
          <AlertDialogAction onClick={(e) => { e.preventDefault(); handleConfirmDelete(); }} disabled={isDeleting} className="bg-destructive hover:bg-destructive/90 text-white">
            {isDeleting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {t('meetingsPage.deleteMeeting.confirm')}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
