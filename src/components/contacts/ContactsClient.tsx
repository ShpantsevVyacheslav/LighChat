'use client';

import React, { useMemo, useState, useCallback, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase, useUsersByDocumentIds, useUser as useFirebaseUser } from '@/firebase';
import { doc } from 'firebase/firestore';
import type { User, UserContactsIndex } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { PhoneInput } from '@/components/ui/phone-input';
import {
  UserPlus,
  Loader2,
  MessageSquare,
  Trash2,
  Smartphone,
  AlertCircle as AlertCircleIcon,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  findUserByPhoneInFirestore,
  addContactId,
  removeContactId,
  saveDeviceContactsConsent,
  dismissPhoneBookOffer,
} from '@/lib/contacts-client-actions';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import { normalizePhoneDigits } from '@/lib/phone-utils';
import { isPwaDisplayMode } from '@/lib/pwa-display-mode';
import { cn } from '@/lib/utils';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { ContactsSyncPromoBanner } from '@/components/contacts/ContactsSyncPromoBanner';
import { ContactsPermissionGuideDialog } from '@/components/contacts/ContactsPermissionGuideDialog';

type ContactPickerNavigator = Navigator & {
  contacts?: {
    select: (props: string[], opts?: { multiple?: boolean }) => Promise<Array<{ tel?: string[] }>>;
  };
};

/** Кнопка-иконка в духе iOS: стекло без яркой обводки. */
const glassIconButtonClass = cn(
  'inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-[0.95rem]',
  'bg-white/45 shadow-sm backdrop-blur-xl ring-1 ring-black/[0.05]',
  'transition-all hover:bg-white/60 active:scale-[0.96]',
  'dark:bg-white/[0.09] dark:ring-white/[0.06] dark:shadow-[0_2px_20px_rgba(0,0,0,0.25)] dark:hover:bg-white/[0.14]'
);

export function ContactsClient() {
  const { user: currentUser } = useAuth();
  const { user: firebaseUser } = useFirebaseUser();
  const ownerUid = firebaseUser?.uid ?? null;
  const firestore = useFirestore();
  const router = useRouter();
  const { toast } = useToast();

  const [phoneInput, setPhoneInput] = useState('');
  const [searchBusy, setSearchBusy] = useState(false);
  const [chatBusyId, setChatBusyId] = useState<string | null>(null);
  const [removeBusyId, setRemoveBusyId] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const [addSheetOpen, setAddSheetOpen] = useState(false);
  const [pwaPhoneBookOpen, setPwaPhoneBookOpen] = useState(false);
  const [contactPermissionGuideOpen, setContactPermissionGuideOpen] = useState(false);
  const skipDismissOnCloseRef = useRef(false);

  const contactsRef = useMemoFirebase(() => {
    if (!firestore || !ownerUid) return null;
    return doc(firestore, 'userContacts', ownerUid);
  }, [firestore, ownerUid]);

  const { data: contactsIndex, isLoading: loadingContacts, error: contactsDocError } =
    useDoc<UserContactsIndex>(contactsRef);

  const contactIds = useMemo(() => contactsIndex?.contactIds ?? [], [contactsIndex?.contactIds]);

  const { usersById, isLoading: loadingUsers } = useUsersByDocumentIds(firestore, contactIds);

  const contactRows = useMemo(() => {
    if (contactIds.length === 0) return [];
    return contactIds.map((id) => ({
      id,
      user: usersById.get(id) ?? null,
    }));
  }, [contactIds, usersById]);

  const listLoading =
    !contactsDocError && (loadingContacts || (contactIds.length > 0 && loadingUsers));
  const hasConsent = Boolean(contactsIndex?.deviceSyncConsentAt);

  const contactPickerSupported =
    typeof navigator !== 'undefined' &&
    'contacts' in navigator &&
    typeof (navigator as ContactPickerNavigator).contacts?.select === 'function';

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (contactsDocError || loadingContacts || !ownerUid) return;
    if (!isPwaDisplayMode()) return;
    if (!contactPickerSupported) return;
    if (hasConsent) return;
    if (contactsIndex?.phoneBookOfferDismissedAt) return;
    setPwaPhoneBookOpen(true);
  }, [
    contactsDocError,
    loadingContacts,
    ownerUid,
    contactPickerSupported,
    hasConsent,
    contactsIndex?.phoneBookOfferDismissedAt,
  ]);

  const importFromDevice = useCallback(
    async (opts?: { bypassConsentCheck?: boolean; onPermissionDenied?: () => void }) => {
      if (!firestore || !currentUser || !ownerUid) return;
      if (!opts?.bypassConsentCheck && !contactsIndex?.deviceSyncConsentAt) {
        toast({ title: 'Нет согласия на доступ', variant: 'destructive' });
        return;
      }
      const nav = navigator as ContactPickerNavigator;
      if (!nav.contacts?.select) {
        toast({
          title: 'Недоступно',
          description: 'В этом браузере нет выбора контактов.',
        });
        return;
      }
      setSyncBusy(true);
      let added = 0;
      try {
        const picked = await nav.contacts.select(['tel'], { multiple: true });
        const seen = new Set(contactIds);
        for (const c of picked) {
          const tels = c.tel ?? [];
          for (const raw of tels) {
            const found = await findUserByPhoneInFirestore(firestore, raw);
            if (!found || found.id === ownerUid) continue;
            if (!canStartDirectChat(currentUser, found)) continue;
            if (seen.has(found.id)) continue;
            await addContactId(firestore, ownerUid, found.id);
            seen.add(found.id);
            added += 1;
          }
        }
        toast({
          title: 'Готово',
          description: added
            ? `Добавлено в контакты: ${added}`
            : 'Совпадений по номерам в LighChat не найдено.',
        });
      } catch (e) {
        if ((e as Error).name === 'AbortError' || (e as Error).name === 'NotAllowedError') {
          if (opts?.onPermissionDenied) {
            opts.onPermissionDenied();
          } else {
            toast({ title: 'Доступ отменён' });
          }
        } else {
          console.error(e);
          toast({ title: 'Ошибка импорта', variant: 'destructive' });
        }
      } finally {
        setSyncBusy(false);
      }
    },
    [firestore, currentUser, ownerUid, contactsIndex?.deviceSyncConsentAt, contactIds, toast]
  );

  /** Показ после онбординга: иначе одновременно AlertDialog и баннер перегружают экран. */
  const showContactsSyncPromo =
    isPwaDisplayMode() &&
    contactPickerSupported &&
    !contactsDocError &&
    !listLoading &&
    (hasConsent || Boolean(contactsIndex?.phoneBookOfferDismissedAt));

  const handleAddByPhone = async () => {
    if (!firestore || !currentUser || !ownerUid) return;
    const digits = normalizePhoneDigits(phoneInput);
    if (digits.length < 11) {
      toast({ title: 'Введите номер полностью', variant: 'destructive' });
      return;
    }
    setSearchBusy(true);
    try {
      const found = await findUserByPhoneInFirestore(firestore, phoneInput);
      if (!found) {
        toast({
          title: 'Пользователь не найден',
          description: 'Проверьте номер или зарегистрирован ли он в LighChat.',
        });
        return;
      }
      if (found.id === ownerUid) {
        toast({ title: 'Нельзя добавить себя', variant: 'destructive' });
        return;
      }
      if (!canStartDirectChat(currentUser, found)) {
        toast({
          title: 'Недоступно',
          description: 'С этим пользователем нельзя связаться по правилам ролей.',
          variant: 'destructive',
        });
        return;
      }
      if (contactIds.includes(found.id)) {
        toast({ title: 'Уже в контактах', description: found.name });
        setPhoneInput('');
        setAddSheetOpen(false);
        return;
      }
      await addContactId(firestore, ownerUid, found.id);
      toast({ title: 'Контакт добавлен', description: found.name });
      setPhoneInput('');
      setAddSheetOpen(false);
    } catch (e) {
      console.error(e);
      toast({ title: 'Ошибка', description: 'Не удалось добавить контакт.', variant: 'destructive' });
    } finally {
      setSearchBusy(false);
    }
  };

  const openChat = async (other: User) => {
    if (!firestore || !currentUser || !ownerUid) return;
    setChatBusyId(other.id);
    try {
      const id = await createOrOpenDirectChat(firestore, currentUser, other);
      router.push(`/dashboard/chat?conversationId=${encodeURIComponent(id)}`);
    } catch (e) {
      console.error(e);
      toast({ title: 'Не удалось открыть чат', variant: 'destructive' });
    } finally {
      setChatBusyId(null);
    }
  };

  const removeContact = async (otherId: string) => {
    if (!firestore || !currentUser || !ownerUid) return;
    setRemoveBusyId(otherId);
    try {
      await removeContactId(firestore, ownerUid, otherId);
      toast({ title: 'Контакт удалён' });
    } catch (e) {
      console.error(e);
      toast({ title: 'Ошибка удаления', variant: 'destructive' });
    } finally {
      setRemoveBusyId(null);
    }
  };

  const handlePhoneBookAllow = async () => {
    if (!firestore || !ownerUid) return;
    skipDismissOnCloseRef.current = true;
    setPwaPhoneBookOpen(false);
    try {
      await saveDeviceContactsConsent(firestore, ownerUid, true);
      await importFromDevice({ bypassConsentCheck: true });
    } catch (e) {
      console.error(e);
      toast({ title: 'Ошибка', description: 'Не удалось выполнить импорт.', variant: 'destructive' });
    } finally {
      skipDismissOnCloseRef.current = false;
    }
  };

  const handlePhoneBookNotNow = async () => {
    if (!firestore || !ownerUid) return;
    try {
      await dismissPhoneBookOffer(firestore, ownerUid);
    } catch (e) {
      console.error(e);
    }
    setPwaPhoneBookOpen(false);
  };

  const handlePhoneBookOpenChange = (open: boolean) => {
    if (open) {
      setPwaPhoneBookOpen(true);
      return;
    }
    if (syncBusy) return;
    setPwaPhoneBookOpen(false);
    if (!skipDismissOnCloseRef.current && firestore && ownerUid) {
      void dismissPhoneBookOffer(firestore, ownerUid).catch((e) => console.error(e));
    }
  };

  if (!currentUser || !ownerUid) return null;

  const sheetSurfaceClass = cn(
    'rounded-t-[1.75rem] !border-0 bg-background/[0.93] backdrop-blur-2xl',
    'shadow-[0_-12px_40px_-8px_rgba(0,0,0,0.45)] dark:shadow-[0_-12px_48px_-6px_rgba(0,0,0,0.65)]',
    'pb-[max(1.5rem,env(safe-area-inset-bottom,0px))]'
  );

  return (
    <div className="mx-auto max-w-lg px-[max(0.25rem,calc(1rem/3))] pb-20 pt-4 md:px-[max(0.25rem,calc(1.5rem/3))] md:pt-6">
      {contactsDocError && (
        <Alert variant="destructive" className="mb-4 rounded-2xl border-red-500/30 bg-destructive/10">
          <AlertCircleIcon className="h-4 w-4" />
          <AlertTitle>Нет доступа к контактам</AlertTitle>
          <AlertDescription className="text-sm">
            Правила Firestore не разрешают чтение <code className="text-xs">userContacts/{'{uid}'}</code>. Выполните{' '}
            <code className="text-xs">firebase deploy --only firestore:rules</code> из корня проекта (файл{' '}
            <code className="text-xs">firestore.rules</code>).
          </AlertDescription>
        </Alert>
      )}

      <header className="mb-5 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-2xl font-semibold tracking-tight">Контакты</h1>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {listLoading ? 'Загрузка…' : contactRows.length === 0 ? 'Список пуст' : `${contactRows.length} в списке`}
          </p>
        </div>
        <button
          type="button"
          className={glassIconButtonClass}
          onClick={() => setAddSheetOpen(true)}
          aria-label="Добавить контакт"
        >
          <UserPlus className="h-[1.15rem] w-[1.15rem]" strokeWidth={1.75} />
        </button>
      </header>

      {listLoading ? (
        <div className="flex min-h-[180px] items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground/60" aria-hidden />
        </div>
      ) : contactRows.length === 0 ? (
        <p className="px-1 py-10 text-center text-sm leading-relaxed text-muted-foreground">
          Добавьте контакт по номеру телефона — кнопка{' '}
          <UserPlus className="mx-0.5 inline h-4 w-4 align-text-bottom" strokeWidth={1.75} /> сверху.
          {isPwaDisplayMode() &&
            contactPickerSupported &&
            !hasConsent &&
            !contactsIndex?.phoneBookOfferDismissedAt && (
              <> При первом открытии можно импортировать совпадения из телефонной книги.</>
            )}
        </p>
      ) : (
        <ul className="divide-y divide-border/40 dark:divide-white/10">
          {contactRows.map(({ id, user: u }) => (
            <li key={id}>
              <div className="flex items-center gap-3 py-3">
                <Avatar className="h-11 w-11 shrink-0 ring-1 ring-black/5 dark:ring-white/10">
                  {u ? <AvatarImage src={u.avatar} alt="" /> : null}
                  <AvatarFallback className="text-sm font-medium">{u ? u.name.charAt(0) : '?'}</AvatarFallback>
                </Avatar>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium leading-tight">{u ? u.name : 'Пользователь недоступен'}</p>
                  {u
                    ? u.username?.trim()
                      ? (
                          <p className="truncate text-xs text-muted-foreground">@{u.username}</p>
                        )
                      : null
                    : (
                        <p className="truncate text-xs text-muted-foreground">{`${id.slice(0, 8)}…`}</p>
                      )}
                </div>
                <div className="flex shrink-0 items-center gap-1">
                  <button
                    type="button"
                    className={cn(glassIconButtonClass, 'h-9 w-9 rounded-[0.75rem]')}
                    onClick={() => u && openChat(u)}
                    disabled={!u || chatBusyId === id}
                    aria-label="Написать"
                  >
                    {chatBusyId === id ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <MessageSquare className="h-4 w-4" strokeWidth={1.75} />
                    )}
                  </button>
                  <button
                    type="button"
                    className={cn(
                      glassIconButtonClass,
                      'h-9 w-9 rounded-[0.75rem] text-destructive hover:text-destructive'
                    )}
                    onClick={() => removeContact(id)}
                    disabled={removeBusyId === id}
                    aria-label="Удалить из контактов"
                  >
                    {removeBusyId === id ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Trash2 className="h-4 w-4" strokeWidth={1.75} />
                    )}
                  </button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}

      {showContactsSyncPromo && (
        <>
          <ContactsSyncPromoBanner
            onClick={() => setContactPermissionGuideOpen(true)}
            disabled={syncBusy}
          />
          <ContactsPermissionGuideDialog
            open={contactPermissionGuideOpen}
            onOpenChange={setContactPermissionGuideOpen}
            hasConsent={hasConsent}
            onRequestConsent={() => setPwaPhoneBookOpen(true)}
            onImportNow={() =>
              void importFromDevice({
                bypassConsentCheck: true,
                onPermissionDenied: () => setContactPermissionGuideOpen(true),
              })
            }
            syncBusy={syncBusy}
          />
        </>
      )}

      <AlertDialog open={pwaPhoneBookOpen} onOpenChange={handlePhoneBookOpenChange}>
        <AlertDialogContent className="max-w-[min(100%,380px)] rounded-2xl border border-border/60 shadow-2xl">
          <AlertDialogHeader>
            <div className="mx-auto mb-1 flex h-12 w-12 items-center justify-center rounded-2xl bg-muted">
              <Smartphone className="h-6 w-6 text-foreground" strokeWidth={1.75} />
            </div>
            <AlertDialogTitle className="text-center text-base">«LighChat» запрашивает доступ к контактам</AlertDialogTitle>
            <AlertDialogDescription className="text-center text-sm leading-relaxed">
              Чтобы найти знакомых в приложении, мы сравним номера из вашей телефонной книги с номерами в базе LighChat.
              Совпадения будут добавлены в список контактов автоматически. Доступ можно отозвать в настройках системы.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="flex-col gap-2 sm:flex-col sm:space-x-0">
            <Button
              className="h-11 w-full rounded-xl font-semibold"
              disabled={syncBusy}
              onClick={() => void handlePhoneBookAllow()}
            >
              {syncBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Разрешить
            </Button>
            <Button
              type="button"
              variant="outline"
              className="h-11 w-full rounded-xl border-border/60 font-medium shadow-none"
              disabled={syncBusy}
              onClick={() => void handlePhoneBookNotNow()}
            >
              Не сейчас
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <Sheet open={addSheetOpen} onOpenChange={setAddSheetOpen}>
        <SheetContent side="bottom" className={sheetSurfaceClass}>
          <SheetHeader className="text-left">
            <SheetTitle className="text-lg font-semibold">Добавить контакт</SheetTitle>
            <SheetDescription>Поиск по номеру телефона из профиля в LighChat.</SheetDescription>
          </SheetHeader>
          <div className="mt-6 space-y-4">
            <PhoneInput value={phoneInput} onChange={setPhoneInput} placeholder="+7 (900) 000-00-00" className="rounded-xl" />
            <Button
              className="h-12 w-full rounded-2xl text-base font-medium shadow-sm"
              onClick={handleAddByPhone}
              disabled={searchBusy || normalizePhoneDigits(phoneInput).length < 11}
            >
              {searchBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Добавить
            </Button>
          </div>
        </SheetContent>
      </Sheet>
    </div>
  );
}
