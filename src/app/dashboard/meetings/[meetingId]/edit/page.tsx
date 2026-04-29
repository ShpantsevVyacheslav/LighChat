
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

const DURATION_OPTIONS = [
  { label: 'Оставить как есть', value: 'current' },
  { label: 'Без ограничений', value: 'infinity' },
  { label: 'Завершить через 15 мин', value: '15' },
  { label: 'Завершить через 30 мин', value: '30' },
  { label: 'Завершить через 1 час', value: '60' },
  { label: 'Завершить через 2 часа', value: '120' },
  { label: 'Завершить через 4 часа', value: '240' },
];

export default function EditMeetingPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const { toast } = useToast();
  
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
      toast({ title: 'Настройки обновлены' });
      router.push('/dashboard/meetings');
    } catch (error: unknown) {
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : 'Не удалось обновить настройки.';
      toast({
        variant: 'destructive',
        title: 'Ошибка',
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
            <Settings className="h-5 w-5 text-primary" /> Настройки встречи
          </AlertDialogTitle>
          <AlertDialogDescription>Измените параметры конференции.</AlertDialogDescription>
        </AlertDialogHeader>
        
        <div className="py-6 space-y-6">
          <div className="space-y-2">
            <Label htmlFor="name" className="text-xs font-bold uppercase tracking-wider opacity-60">Название</Label>
            <Input 
                id="name"
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                className="rounded-2xl h-12 bg-muted/50 border-none"
                placeholder="Название встречи"
                autoFocus
            />
          </div>

          <div className="space-y-2">
            <Label className="text-xs font-bold uppercase tracking-wider opacity-60">Срок жизни комнаты</Label>
            <Select value={duration} onValueChange={setDuration}>
                <SelectTrigger className="rounded-2xl h-12 bg-muted/50 border-none">
                    <SelectValue placeholder="Выберите длительность" />
                </SelectTrigger>
                <SelectContent className="rounded-2xl">
                    {DURATION_OPTIONS.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                    ))}
                </SelectContent>
            </Select>
            <p className="text-[10px] text-muted-foreground px-2">Текущий статус: {meeting?.expiresAt ? 'Лимитирована' : 'Без ограничений'}</p>
          </div>

          <div className="space-y-2">
            <Label className="text-xs font-bold uppercase tracking-wider opacity-60">Приватность</Label>
            <div className="flex items-center gap-3 h-12 bg-muted/30 rounded-2xl px-4 border border-border/50">
                {isPrivate ? <ShieldAlert className="h-4 w-4 text-amber-500" /> : <ShieldCheck className="h-4 w-4 text-green-500" />}
                <span className="text-sm font-medium flex-1">{isPrivate ? 'Приватная (нужно одобрение)' : 'Открытая (вход по ссылке)'}</span>
                <Switch checked={isPrivate} onCheckedChange={setIsPrivate} />
            </div>
          </div>
        </div>

        <AlertDialogFooter className="bg-muted/10 p-2 -mx-6 -mb-6 mt-4">
          <AlertDialogCancel disabled={isSaving} className="rounded-2xl border-none bg-transparent hover:bg-muted">Отмена</AlertDialogCancel>
          <AlertDialogAction onClick={(e) => { e.preventDefault(); handleSave(); }} disabled={isSaving || !name.trim()} className="rounded-2xl px-8 font-bold">
            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Сохранить
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
