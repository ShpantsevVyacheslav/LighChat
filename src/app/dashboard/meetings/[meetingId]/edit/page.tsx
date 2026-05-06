
'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Loader2, Settings, ShieldAlert, ShieldCheck } from 'lucide-react';
import { addMinutes } from 'date-fns';
import { useI18n } from '@/hooks/use-i18n';

const DURATION_OPTIONS = [
  { labelKey: 'current' as const, value: 'current' },
  { labelKey: 'infinity' as const, value: 'infinity' },
  { labelKey: 'm15' as const, value: '15' },
  { labelKey: 'm30' as const, value: '30' },
  { labelKey: 'h1' as const, value: '60' },
  { labelKey: 'h2' as const, value: '120' },
  { labelKey: 'h4' as const, value: '240' },
];

export default function EditMeetingPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  
  const meetingId = typeof params.meetingId === 'string' ? params.meetingId : '';
  const meetingRef = useMemoFirebase(() => (firestore && meetingId ? doc(firestore, 'meetings', meetingId) : null), [firestore, meetingId]);
  const { data: meeting, isLoading } = useDoc<Meeting>(meetingRef);

  const [name, setName] = useState('');
  const [duration, setDuration] = useState('current');
  const [isPrivate, setIsPrivate] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (meeting) {
      setName(meeting.name);
      setIsPrivate(meeting.isPrivate || false);
    }
  }, [meeting]);

  const handleSave = async () => {
    if (!meetingRef || !name.trim()) return;

    setIsSaving(true);
    try {
      const updateData: Record<string, unknown> = { 
          name: name.trim(),
          isPrivate: isPrivate
      };
      
      if (duration === 'infinity') {
          updateData.expiresAt = null;
      } else if (duration !== 'current') {
          updateData.expiresAt = addMinutes(new Date(), parseInt(duration, 10)).toISOString();
      }

      await updateDoc(meetingRef, updateData);
      toast({ title: t('meetingsPage.edit.toastUpdated') });
      router.push('/dashboard/meetings');
    } catch (error: unknown) {
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : t('meetingsPage.edit.fallbackError');
      toast({
        variant: 'destructive',
        title: t('meetingsPage.edit.toastErrorTitle'),
        description: message,
      });
      setIsSaving(false);
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
    <AlertDialog open={true} onOpenChange={(open) => !open && !isSaving && router.back()}>
      <AlertDialogContent className="rounded-[2.5rem] max-w-md border-none shadow-2xl">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5 text-primary" /> {t('meetingsPage.edit.dialogTitle')}
          </AlertDialogTitle>
          <AlertDialogDescription>{t('meetingsPage.edit.dialogDescription')}</AlertDialogDescription>
        </AlertDialogHeader>

        <div className="py-6 space-y-6">
          <div className="space-y-2">
            <Label htmlFor="name" className="text-xs font-bold uppercase tracking-wider opacity-60">{t('meetingsPage.edit.nameLabel')}</Label>
            <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="rounded-2xl h-12 bg-muted/50 border-none"
                placeholder={t('meetingsPage.edit.namePlaceholder')}
                autoFocus
            />
          </div>

          <div className="space-y-2">
            <Label className="text-xs font-bold uppercase tracking-wider opacity-60">{t('meetingsPage.edit.lifetimeLabel')}</Label>
            <Select value={duration} onValueChange={setDuration}>
                <SelectTrigger className="rounded-2xl h-12 bg-muted/50 border-none">
                    <SelectValue placeholder={t('meetingsPage.edit.lifetimePlaceholder')} />
                </SelectTrigger>
                <SelectContent className="rounded-2xl">
                    {DURATION_OPTIONS.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>{t(`meetingsPage.edit.durationOption.${opt.labelKey}`)}</SelectItem>
                    ))}
                </SelectContent>
            </Select>
            <p className="text-[10px] text-muted-foreground px-2">{t('meetingsPage.edit.lifetimeStatusPrefix')} {meeting?.expiresAt ? t('meetingsPage.edit.lifetimeStatusLimited') : t('meetingsPage.edit.lifetimeStatusInfinite')}</p>
          </div>

          <div className="space-y-2">
            <Label className="text-xs font-bold uppercase tracking-wider opacity-60">{t('meetingsPage.edit.privacyLabel')}</Label>
            <div className="flex items-center gap-3 h-12 bg-muted/30 rounded-2xl px-4 border border-border/50">
                {isPrivate ? <ShieldAlert className="h-4 w-4 text-amber-500" /> : <ShieldCheck className="h-4 w-4 text-green-500" />}
                <span className="text-sm font-medium flex-1">{isPrivate ? t('meetingsPage.edit.privacyPrivate') : t('meetingsPage.edit.privacyOpen')}</span>
                <Switch checked={isPrivate} onCheckedChange={setIsPrivate} />
            </div>
          </div>
        </div>

        <AlertDialogFooter className="bg-muted/10 p-2 -mx-6 -mb-6 mt-4">
          <AlertDialogCancel disabled={isSaving} className="rounded-2xl border-none bg-transparent hover:bg-muted">{t('meetingsPage.edit.cancel')}</AlertDialogCancel>
          <AlertDialogAction onClick={(e) => { e.preventDefault(); handleSave(); }} disabled={isSaving || !name.trim()} className="rounded-2xl px-8 font-bold">
            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {t('meetingsPage.edit.save')}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
