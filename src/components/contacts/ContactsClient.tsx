'use client';
import { useI18n } from '@/hooks/use-i18n';

import React, { useMemo, useState, useCallback, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase, useUsersByDocumentIds, useUser as useFirebaseUser } from '@/firebase';
import { doc } from 'firebase/firestore';
import type { User, UserContactsIndex } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Input } from '@/components/ui/input';
import {
  UserPlus,
  Loader2,
  Trash2,
  Smartphone,
  QrCode,
  Camera,
  Upload,
  AlertCircle as AlertCircleIcon,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  findUserByPhoneInFirestore,
  findUserByIdInFirestore,
  findUserByUsernameInFirestore,
  addContactId,
  removeContactId,
  saveDeviceContactsConsent,
  dismissPhoneBookOffer,
} from '@/lib/contacts-client-actions';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { resolveContactDisplayName } from '@/lib/contact-display-name';
import { isPwaDisplayMode } from '@/lib/pwa-display-mode';
import { cn } from '@/lib/utils';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogCancel,
} from '@/components/ui/alert-dialog';
import { ContactsSyncPromoBanner } from '@/components/contacts/ContactsSyncPromoBanner';
import { ContactsPermissionGuideDialog } from '@/components/contacts/ContactsPermissionGuideDialog';
import { extractProfileTargetFromQrPayload } from '@/lib/profile-qr-link';
import { logger } from '@/lib/logger';

type ContactPickerNavigator = Navigator & {
  contacts?: {
    select: (props: string[], opts?: { multiple?: boolean }) => Promise<Array<{ tel?: string[] }>>;
  };
};

type BarcodeDetectorCtorLike = new (opts?: { formats?: string[] }) => {
  detect: (source: ImageBitmapSource) => Promise<unknown>;
};

function getBarcodeDetectorCtor(): BarcodeDetectorCtorLike | null {
  if (typeof window === 'undefined') return null;
  const maybeCtor = (window as unknown as { BarcodeDetector?: BarcodeDetectorCtorLike }).BarcodeDetector;
  return typeof maybeCtor === 'function' ? maybeCtor : null;
}

function pickRawQrValue(detected: unknown): string | null {
  if (!Array.isArray(detected)) return null;
  for (const item of detected) {
    if (!item || typeof item !== 'object') continue;
    const raw = (item as { rawValue?: unknown }).rawValue;
    if (typeof raw === 'string' && raw.trim()) return raw.trim();
  }
  return null;
}

/** Кнопка-иконка в духе iOS: стекло без яркой обводки. */
const glassIconButtonClass = cn(
  'inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-[0.95rem]',
  'bg-white/45 shadow-sm backdrop-blur-xl ring-1 ring-black/[0.05]',
  'transition-all hover:bg-white/60 active:scale-[0.96]',
  'dark:bg-white/[0.09] dark:ring-white/[0.06] dark:shadow-[0_2px_20px_rgba(0,0,0,0.25)] dark:hover:bg-white/[0.14]'
);

/** Панель подтверждения в том же стеклянном ключе, что и кнопки контактов. */
const contactRemoveDialogSurfaceClass = cn(
  'max-w-[min(100%,380px)] gap-5 rounded-[1.35rem] border border-white/30 p-6 shadow-[0_24px_80px_-20px_rgba(0,0,0,0.55)]',
  'bg-background/[0.72] backdrop-blur-2xl backdrop-saturate-150',
  'dark:border-white/[0.12] dark:bg-white/[0.08] dark:shadow-[0_28px_90px_-24px_rgba(0,0,0,0.75)]'
);

const contactRemoveDialogOverlayClass = 'bg-black/45 backdrop-blur-md';

type PhoneCountryPreset = {
  country: string;
  dialCode: string;
  hint: string;
  minDigits: number;
  maxDigits: number;
};

const PHONE_COUNTRY_PRESETS: PhoneCountryPreset[] = [
  { country: 'countryRussia', dialCode: '+7', hint: '(999) 123-45-67', minDigits: 10, maxDigits: 10 },
  { country: 'countryKazakhstan', dialCode: '+7', hint: '(777) 123-45-67', minDigits: 10, maxDigits: 10 },
  { country: 'countryBelarus', dialCode: '+375', hint: '29 123 45 67', minDigits: 9, maxDigits: 9 },
  { country: 'countryUkraine', dialCode: '+380', hint: '50 123 45 67', minDigits: 9, maxDigits: 9 },
  { country: 'countryUSA', dialCode: '+1', hint: '(555) 123-4567', minDigits: 10, maxDigits: 10 },
  { country: 'countryUK', dialCode: '+44', hint: '7400 123456', minDigits: 10, maxDigits: 10 },
];

function maskPhoneDigitsByHint(digits: string, hint: string): string {
  const clean = digits.replace(/\D/g, '');
  if (!clean) return '';
  let di = 0;
  let out = '';
  for (const ch of hint) {
    if (/\d/.test(ch)) {
      if (di >= clean.length) break;
      out += clean[di] ?? '';
      di += 1;
    } else if (di > 0) {
      out += ch;
    }
  }
  if (di < clean.length) out += clean.slice(di);
  return out;
}

export function ContactsClient() {
  const { t } = useI18n();
  const { user: currentUser } = useAuth();
  const { user: firebaseUser } = useFirebaseUser();
  const ownerUid = firebaseUser?.uid ?? null;
  const firestore = useFirestore();
  const router = useRouter();
  const { toast } = useToast();

  const [phoneInput, setPhoneInput] = useState('');
  const [phoneCountryCode, setPhoneCountryCode] = useState('+7');
  const [searchBusy, setSearchBusy] = useState(false);
  const [removeBusyId, setRemoveBusyId] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const [addSheetOpen, setAddSheetOpen] = useState(false);
  const [qrDialogOpen, setQrDialogOpen] = useState(false);
  const [qrPayloadInput, setQrPayloadInput] = useState('');
  const [qrBusy, setQrBusy] = useState(false);
  const [qrCameraError, setQrCameraError] = useState<string | null>(null);
  const [pwaPhoneBookOpen, setPwaPhoneBookOpen] = useState(false);
  const [contactPermissionGuideOpen, setContactPermissionGuideOpen] = useState(false);
  /** Подтверждение удаления из списка контактов. */
  const [contactPendingRemove, setContactPendingRemove] = useState<{ id: string; name: string } | null>(null);
  const skipDismissOnCloseRef = useRef(false);
  const qrVideoRef = useRef<HTMLVideoElement | null>(null);
  const qrFileInputRef = useRef<HTMLInputElement | null>(null);
  const qrLoopRef = useRef<number | null>(null);
  const qrStreamRef = useRef<MediaStream | null>(null);
  const qrHandlingRef = useRef(false);
  const qrLastScanAtRef = useRef(0);

  const contactsRef = useMemoFirebase(() => {
    if (!firestore || !ownerUid) return null;
    return doc(firestore, 'userContacts', ownerUid);
  }, [firestore, ownerUid]);

  const { data: contactsIndex, isLoading: loadingContacts, error: contactsDocError } =
    useDoc<UserContactsIndex>(contactsRef);

  const contactIds = useMemo(() => contactsIndex?.contactIds ?? [], [contactsIndex?.contactIds]);
  const contactProfiles = useMemo(
    () => contactsIndex?.contactProfiles ?? {},
    [contactsIndex?.contactProfiles]
  );

  const { usersById, isLoading: loadingUsers } = useUsersByDocumentIds(firestore, contactIds);

  const contactRows = useMemo(() => {
    if (contactIds.length === 0) return [];
    return contactIds.map((id) => {
      const user = usersById.get(id) ?? null;
      const fallbackName = (user?.name ?? '').trim() || t('contacts.fallbackUserName');
      return {
        id,
        user,
        displayName: resolveContactDisplayName(contactProfiles, id, fallbackName),
      };
    });
  }, [contactIds, usersById, contactProfiles]);

  const listLoading =
    !contactsDocError && (loadingContacts || (contactIds.length > 0 && loadingUsers));
  const hasConsent = Boolean(contactsIndex?.deviceSyncConsentAt);

  const contactPickerSupported =
    typeof navigator !== 'undefined' &&
    'contacts' in navigator &&
    typeof (navigator as ContactPickerNavigator).contacts?.select === 'function';

  const selectedPhonePreset = useMemo(
    () =>
      PHONE_COUNTRY_PRESETS.find((p) => p.dialCode === phoneCountryCode) ??
      PHONE_COUNTRY_PRESETS[0],
    [phoneCountryCode]
  );
  const phoneDigits = useMemo(
    () => phoneInput.replace(/\D/g, ''),
    [phoneInput]
  );

  useEffect(() => {
    const userPhone = (currentUser?.phone ?? '').trim();
    if (!userPhone) return;
    const digits = userPhone.replace(/\D/g, '');
    if (!digits) return;
    const byDial = [...PHONE_COUNTRY_PRESETS]
      .sort((a, b) => b.dialCode.length - a.dialCode.length)
      .find((p) => digits.startsWith(p.dialCode.replace(/\D/g, '')));
    if (byDial) setPhoneCountryCode(byDial.dialCode);
  }, [currentUser?.phone]);

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
        toast({ title: t('contacts.noConsentAccess'), variant: 'destructive' });
        return;
      }
      const nav = navigator as ContactPickerNavigator;
      if (!nav.contacts?.select) {
        toast({
          title: t('contacts.unavailable'),
          description: t('contacts.unavailableHint'),
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
          title: t('contacts.syncDone'),
          description: added
            ? t('contacts.syncAddedCount').replace('{count}', String(added))
            : t('contacts.syncNoMatches'),
        });
      } catch (e) {
        if ((e as Error).name === 'AbortError' || (e as Error).name === 'NotAllowedError') {
          if (opts?.onPermissionDenied) {
            opts.onPermissionDenied();
          } else {
            toast({ title: t('contacts.accessCancelled') });
          }
        } else {
          logger.error('contacts', 'import contacts failed', e);
          toast({ title: t('contacts.importError'), variant: 'destructive' });
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

  const handleResolvedContactCandidate = useCallback(
    (foundUser: User) => {
      if (!currentUser || !ownerUid) return false;
      const normalizedId = foundUser.id.trim();
      if (!normalizedId) return false;

      if (normalizedId === ownerUid) {
        toast({ title: t('contacts.cannotAddSelf'), variant: 'destructive' });
        return false;
      }

      if (!canStartDirectChat(currentUser, foundUser)) {
        toast({
          title: t('contacts.unavailable'),
          description: t('contacts.unavailablePolicy'),
          variant: 'destructive',
        });
        return false;
      }

      setPhoneInput('');
      setQrPayloadInput('');
      setQrDialogOpen(false);
      setAddSheetOpen(false);

      if (contactIds.includes(normalizedId)) {
        toast({ title: t('contacts.alreadyInContacts'), description: t('contacts.alreadyInContactsHint') });
        router.push(`/dashboard/contacts/${encodeURIComponent(normalizedId)}`);
        return true;
      }

      toast({ title: t('contacts.userFound'), description: t('contacts.userFoundHint') });
      router.push(`/dashboard/contacts/${encodeURIComponent(normalizedId)}/edit`);
      return true;
    },
    [currentUser, ownerUid, toast, contactIds, router]
  );

  const handleAddByQrPayload = useCallback(
    async (payload: string): Promise<boolean> => {
      if (!firestore || !ownerUid || !currentUser) return false;
      const target = extractProfileTargetFromQrPayload(payload);
      if (!target.userId && !target.username) {
        toast({
          title: t('contacts.qrNotRecognized'),
          description: t('contacts.qrNotRecognizedHint'),
          variant: 'destructive',
        });
        return false;
      }

      setQrBusy(true);
      try {
        let found = target.userId
          ? await findUserByIdInFirestore(firestore, target.userId)
          : null;
        if (!found && target.username) {
          found = await findUserByUsernameInFirestore(firestore, target.username);
        }
        if (!found) {
          toast({
            title: t('contacts.profileNotFound'),
            description: t('contacts.profileNotFoundHint'),
            variant: 'destructive',
          });
          return false;
        }
        return handleResolvedContactCandidate(found);
      } catch (e) {
        logger.error('contacts', 'qr payload processing failed', e);
        toast({
          title: t('contacts.qrError'),
          description: t('contacts.qrProcessError'),
          variant: 'destructive',
        });
        return false;
      } finally {
        setQrBusy(false);
        qrHandlingRef.current = false;
      }
    },
    [firestore, ownerUid, currentUser, toast, handleResolvedContactCandidate]
  );

  const stopQrCamera = useCallback(() => {
    if (qrLoopRef.current != null) {
      window.cancelAnimationFrame(qrLoopRef.current);
      qrLoopRef.current = null;
    }
    if (qrStreamRef.current) {
      for (const track of qrStreamRef.current.getTracks()) track.stop();
      qrStreamRef.current = null;
    }
    if (qrVideoRef.current) {
      qrVideoRef.current.pause();
      qrVideoRef.current.srcObject = null;
    }
  }, []);

  const startQrCamera = useCallback(async () => {
    const Detector = getBarcodeDetectorCtor();
    if (!Detector) {
      setQrCameraError(t('contacts.cameraUnavailableHint'));
      return;
    }
    if (!navigator.mediaDevices?.getUserMedia) {
      setQrCameraError(t('contacts.cameraNoMediaHint'));
      return;
    }

    stopQrCamera();
    setQrCameraError(null);
    qrLastScanAtRef.current = 0;

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: 'environment' } },
      });
      qrStreamRef.current = stream;

      const video = qrVideoRef.current;
      if (!video) {
        stopQrCamera();
        setQrCameraError(t('contacts.cameraPreviewError'));
        return;
      }

      video.srcObject = stream;
      await video.play().catch(() => undefined);

      const detector = new Detector({ formats: ['qr_code'] });
      const loop = async () => {
        const videoEl = qrVideoRef.current;
        if (!videoEl) return;
        const now = Date.now();
        if (
          !qrHandlingRef.current &&
          now - qrLastScanAtRef.current >= 220 &&
          videoEl.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA
        ) {
          qrLastScanAtRef.current = now;
          try {
            const found = await detector.detect(videoEl);
            const payload = pickRawQrValue(found);
            if (payload) {
              setQrPayloadInput(payload);
              qrHandlingRef.current = true;
              const success = await handleAddByQrPayload(payload);
              if (success) return;
            }
          } catch {
            // Ignore intermittent detection errors, keep scanning.
          }
        }
        qrLoopRef.current = window.requestAnimationFrame(() => {
          void loop();
        });
      };

      qrLoopRef.current = window.requestAnimationFrame(() => {
        void loop();
      });
    } catch (e) {
      logger.error('contacts', 'camera open failed', e);
      setQrCameraError(t('contacts.cameraOpenFailed'));
      stopQrCamera();
    }
  }, [handleAddByQrPayload, stopQrCamera]);

  const handleQrImageUpload = useCallback(
    async (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0] ?? null;
      event.target.value = '';
      if (!file) return;

      const Detector = getBarcodeDetectorCtor();
      if (!Detector) {
        toast({
          title: t('contacts.qrUploadUnavailable'),
          description: t('contacts.qrUploadUnavailableHint'),
          variant: 'destructive',
        });
        return;
      }

      try {
        const bitmap = await createImageBitmap(file);
        try {
          const detector = new Detector({ formats: ['qr_code'] });
          const found = await detector.detect(bitmap);
          const payload = pickRawQrValue(found);
          if (!payload) {
            toast({
              title: t('contacts.qrNotFoundInImage'),
              description: t('contacts.qrNotFoundInImageHint'),
              variant: 'destructive',
            });
            return;
          }
          setQrPayloadInput(payload);
          await handleAddByQrPayload(payload);
        } finally {
          bitmap.close();
        }
      } catch (e) {
        logger.error('contacts', 'qr image process failed', e);
        toast({
          title: t('contacts.imageProcessError'),
          description: t('contacts.imageProcessErrorHint'),
          variant: 'destructive',
        });
      }
    },
    [handleAddByQrPayload, toast]
  );

  useEffect(() => {
    if (!qrDialogOpen) {
      stopQrCamera();
      qrHandlingRef.current = false;
      return;
    }
    void startQrCamera();
    return () => stopQrCamera();
  }, [qrDialogOpen, startQrCamera, stopQrCamera]);

  const handleAddByPhone = async () => {
    if (!firestore || !currentUser || !ownerUid) return;
    const digits = phoneInput.replace(/\D/g, '').slice(0, selectedPhonePreset.maxDigits);
    if (digits.length < selectedPhonePreset.minDigits) {
      toast({ title: t('contacts.phoneEnterFull'), variant: 'destructive' });
      return;
    }
    const lookupPhone = `${phoneCountryCode}${digits}`;
    setSearchBusy(true);
    try {
      const found = await findUserByPhoneInFirestore(firestore, lookupPhone);
      if (!found) {
        toast({
          title: t('contacts.userNotFound'),
          description: t('contacts.userNotFoundHint'),
        });
        return;
      }
      handleResolvedContactCandidate(found);
    } catch (e) {
      logger.error('contacts', 'search by phone failed', e);
      toast({ title: t('contacts.errorGeneric'), description: t('contacts.addContactError'), variant: 'destructive' });
    } finally {
      setSearchBusy(false);
    }
  };

  const performRemoveContact = async (otherId: string) => {
    if (!firestore || !currentUser || !ownerUid) return;
    setRemoveBusyId(otherId);
    try {
      await removeContactId(firestore, ownerUid, otherId);
      toast({ title: t('contacts.contactRemoved') });
    } catch (e) {
      logger.error('contacts', 'remove contact failed', e);
      toast({ title: t('contacts.removeError'), variant: 'destructive' });
    } finally {
      setRemoveBusyId(null);
    }
  };

  const handleConfirmRemoveContact = async () => {
    if (!contactPendingRemove) return;
    const { id } = contactPendingRemove;
    await performRemoveContact(id);
    setContactPendingRemove(null);
  };

  const handlePhoneBookAllow = async () => {
    if (!firestore || !ownerUid) return;
    skipDismissOnCloseRef.current = true;
    setPwaPhoneBookOpen(false);
    try {
      await saveDeviceContactsConsent(firestore, ownerUid, true);
      await importFromDevice({ bypassConsentCheck: true });
    } catch (e) {
      logger.error('contacts', 'phone book allow → import failed', e);
      toast({ title: t('contacts.errorGeneric'), description: t('contacts.importExecutionError'), variant: 'destructive' });
    } finally {
      skipDismissOnCloseRef.current = false;
    }
  };

  const handlePhoneBookNotNow = async () => {
    if (!firestore || !ownerUid) return;
    try {
      await dismissPhoneBookOffer(firestore, ownerUid);
    } catch (e) {
      logger.error('contacts', 'dismiss phone book offer failed', e);
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
      void dismissPhoneBookOffer(firestore, ownerUid).catch((e) =>
        logger.error('contacts', 'dismiss phone book offer (cleanup) failed', e),
      );
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
          <AlertTitle>{t('contacts.noAccessTitle')}</AlertTitle>
          <AlertDescription className="text-sm">
            {t('contacts.noAccessDescription')}
          </AlertDescription>
        </Alert>
      )}

      <header className="mb-5 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-2xl font-semibold tracking-tight">{t('contacts.pageTitle')}</h1>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {listLoading ? t('contacts.loading') : contactRows.length === 0 ? t('contacts.emptyList') : t('contacts.countInList').replace('{count}', String(contactRows.length))}
          </p>
        </div>
        <button
          type="button"
          className={glassIconButtonClass}
          onClick={() => setAddSheetOpen(true)}
          aria-label={t('contacts.addContactAria')}
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
          {t('contacts.emptyHint')}{' '}
          <UserPlus className="mx-0.5 inline h-4 w-4 align-text-bottom" strokeWidth={1.75} />
          {isPwaDisplayMode() &&
            contactPickerSupported &&
            !hasConsent &&
            !contactsIndex?.phoneBookOfferDismissedAt && (
              <>{t('contacts.emptyPhoneBookHint')}</>
            )}
        </p>
      ) : (
        <ul className="divide-y divide-border/40 dark:divide-white/10">
          {contactRows.map(({ id, user: u, displayName }) => (
            <li key={id}>
              <div className="flex items-center gap-3 py-3">
                <button
                  type="button"
                  className="flex min-w-0 flex-1 items-center gap-3 text-left"
                  onClick={() => router.push(`/dashboard/contacts/${encodeURIComponent(id)}`)}
                  aria-label={t('contacts.openContactAria').replace('{name}', displayName)}
                >
                  <Avatar className="h-11 w-11 shrink-0 ring-1 ring-black/5 dark:ring-white/10">
                    {u ? <AvatarImage src={userAvatarListUrl(u)} alt="" /> : null}
                    <AvatarFallback className="text-sm font-medium">
                      {displayName.charAt(0) || '?'}
                    </AvatarFallback>
                  </Avatar>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium leading-tight">{displayName}</p>
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
                </button>
                <div className="flex shrink-0 items-center gap-1 pl-2">
                  <button
                    type="button"
                    className={cn(
                      glassIconButtonClass,
                      'h-9 w-9 rounded-[0.75rem] text-destructive hover:text-destructive'
                    )}
                    onClick={() =>
                      setContactPendingRemove({
                        id,
                        name: (displayName.trim() || t('contacts.fallbackContactName')).slice(0, 120),
                      })
                    }
                    disabled={removeBusyId === id}
                    aria-label={t('contacts.removeAria')}
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

      <AlertDialog
        open={contactPendingRemove !== null}
        onOpenChange={(open) => {
          if (!open) setContactPendingRemove(null);
        }}
      >
        <AlertDialogContent overlayClassName={contactRemoveDialogOverlayClass} className={contactRemoveDialogSurfaceClass}>
          <AlertDialogHeader className="space-y-2 text-left">
            <div className="mb-0.5 flex h-12 w-12 items-center justify-center rounded-2xl bg-destructive/15 ring-1 ring-destructive/25">
              <Trash2 className="h-5 w-5 text-destructive" strokeWidth={1.75} aria-hidden />
            </div>
            <AlertDialogTitle className="text-base font-semibold">{t('contacts.removeDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription className="text-sm leading-relaxed text-muted-foreground">
              {t('contacts.removeDialogDescription').replace('{name}', contactPendingRemove?.name ?? '')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="mt-1 flex-col gap-2 sm:flex-col sm:space-x-0">
            <Button
              type="button"
              variant="destructive"
              className="h-11 w-full rounded-xl font-semibold shadow-sm"
              disabled={!!contactPendingRemove && removeBusyId === contactPendingRemove.id}
              onClick={() => void handleConfirmRemoveContact()}
            >
              {contactPendingRemove && removeBusyId === contactPendingRemove.id ? (
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
              ) : (
                t('contacts.removeButton')
              )}
            </Button>
            <AlertDialogCancel
              type="button"
              className={cn(
                'mt-0 h-11 w-full rounded-xl border border-white/35 bg-white/30 font-semibold backdrop-blur-xl',
                'hover:bg-white/45 dark:border-white/[0.14] dark:bg-white/[0.08] dark:hover:bg-white/[0.12]'
              )}
              disabled={!!contactPendingRemove && removeBusyId === contactPendingRemove.id}
            >
              {t('contacts.cancelButton')}
            </AlertDialogCancel>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={pwaPhoneBookOpen} onOpenChange={handlePhoneBookOpenChange}>
        <AlertDialogContent className="max-w-[min(100%,380px)] rounded-2xl border border-border/60 shadow-2xl">
          <AlertDialogHeader>
            <div className="mx-auto mb-1 flex h-12 w-12 items-center justify-center rounded-2xl bg-muted">
              <Smartphone className="h-6 w-6 text-foreground" strokeWidth={1.75} />
            </div>
            <AlertDialogTitle className="text-center text-base">{t('contacts.phoneBookDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription className="text-center text-sm leading-relaxed">
              {t('contacts.phoneBookDialogDescription')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="flex-col gap-2 sm:flex-col sm:space-x-0">
            <Button
              className="h-11 w-full rounded-xl font-semibold"
              disabled={syncBusy}
              onClick={() => void handlePhoneBookAllow()}
            >
              {syncBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {t('contacts.phoneBookAllow')}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="h-11 w-full rounded-xl border-border/60 font-medium shadow-none"
              disabled={syncBusy}
              onClick={() => void handlePhoneBookNotNow()}
            >
              {t('contacts.phoneBookNotNow')}
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <Sheet open={addSheetOpen} onOpenChange={setAddSheetOpen}>
        <SheetContent side="bottom" className={sheetSurfaceClass}>
          <SheetHeader className="text-left">
            <SheetTitle className="text-lg font-semibold">{t('contacts.addSheetTitle')}</SheetTitle>
            <SheetDescription>{t('contacts.addSheetDescription')}</SheetDescription>
          </SheetHeader>
          <div className="mt-6 space-y-4">
            <div className="flex items-center gap-2">
              <select
                value={phoneCountryCode}
                onChange={(e) => {
                  const dial = e.target.value;
                  setPhoneCountryCode(dial);
                  const nextPreset =
                    PHONE_COUNTRY_PRESETS.find((p) => p.dialCode === dial) ??
                    PHONE_COUNTRY_PRESETS[0];
                  const nextDigits = phoneInput
                    .replace(/\D/g, '')
                    .slice(0, nextPreset.maxDigits);
                  setPhoneInput(maskPhoneDigitsByHint(nextDigits, nextPreset.hint));
                }}
                className="h-11 min-w-[9.5rem] rounded-xl border border-border bg-background px-3 text-sm"
              >
                {PHONE_COUNTRY_PRESETS.map((preset) => (
                  <option key={`${preset.country}-${preset.dialCode}`} value={preset.dialCode}>
                    {t(`contacts.${preset.country}`)} ({preset.dialCode})
                  </option>
                ))}
              </select>
              <Input
                type="tel"
                value={phoneInput}
                onChange={(e) => {
                  const digits = e.target.value
                    .replace(/\D/g, '')
                    .slice(0, selectedPhonePreset.maxDigits);
                  setPhoneInput(maskPhoneDigitsByHint(digits, selectedPhonePreset.hint));
                }}
                placeholder={selectedPhonePreset.hint}
                className="h-11 rounded-xl"
              />
            </div>
            <Button
              className="h-12 w-full rounded-2xl text-base font-medium shadow-sm"
              onClick={handleAddByPhone}
              disabled={searchBusy || phoneDigits.length < selectedPhonePreset.minDigits}
            >
              {searchBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {t('contacts.addButton')}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="h-12 w-full rounded-2xl text-base font-medium"
              onClick={() => {
                setQrPayloadInput('');
                setQrCameraError(null);
                setQrDialogOpen(true);
              }}
              disabled={searchBusy || qrBusy}
            >
              <QrCode className="mr-2 h-4 w-4" />
              {t('contacts.addByQrButton')}
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      <Dialog
        open={qrDialogOpen}
        onOpenChange={(open) => {
          setQrDialogOpen(open);
          if (!open) {
            setQrPayloadInput('');
            setQrCameraError(null);
          }
        }}
      >
        <DialogContent
          className="max-w-[min(100%,28rem)] rounded-2xl border border-border/60 bg-background/95 p-4 sm:p-5"
          showCloseButton
        >
          <DialogHeader className="space-y-1 text-left">
            <DialogTitle className="text-base">{t('contacts.qrDialogTitle')}</DialogTitle>
            <DialogDescription>
              {t('contacts.qrDialogDescription')}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3">
            <div className="relative overflow-hidden rounded-xl border border-border/60 bg-black/40">
              <video
                ref={qrVideoRef}
                autoPlay
                playsInline
                muted
                className="aspect-video w-full object-cover"
              />
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/25">
                <div className="rounded-full border border-white/30 bg-black/35 px-3 py-1 text-xs font-medium text-white/90">
                  {qrCameraError ? t('contacts.qrCameraUnavailable') : t('contacts.qrScanning')}
                </div>
              </div>
            </div>

            {qrCameraError ? (
              <p className="text-xs text-muted-foreground">{qrCameraError}</p>
            ) : (
              <p className="text-xs text-muted-foreground">
                {t('contacts.qrCameraHint')}
              </p>
            )}

            <div className="flex gap-2">
              <Button
                type="button"
                variant="outline"
                className="h-10 flex-1 rounded-xl"
                onClick={() => qrFileInputRef.current?.click()}
                disabled={qrBusy}
              >
                <Upload className="mr-2 h-4 w-4" />
                {t('contacts.uploadQr')}
              </Button>
              <Button
                type="button"
                variant="outline"
                className="h-10 flex-1 rounded-xl"
                onClick={() => {
                  void startQrCamera();
                }}
                disabled={qrBusy}
              >
                <Camera className="mr-2 h-4 w-4" />
                {t('contacts.restartCamera')}
              </Button>
            </div>

            <Input
              value={qrPayloadInput}
              onChange={(e) => setQrPayloadInput(e.target.value)}
              placeholder="https://lighchat.online/dashboard/contacts/..."
              className="h-11 rounded-xl"
            />
            <Button
              type="button"
              className="h-11 w-full rounded-xl font-semibold"
              disabled={qrBusy || !qrPayloadInput.trim()}
              onClick={() => {
                qrHandlingRef.current = true;
                void handleAddByQrPayload(qrPayloadInput);
              }}
            >
              {qrBusy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {t('contacts.findContact')}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
      <input
        ref={qrFileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleQrImageUpload}
      />
    </div>
  );
}
