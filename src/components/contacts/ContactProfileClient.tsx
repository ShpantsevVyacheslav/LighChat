'use client';

import { useEffect, useRef, useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';

import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import { autoEnableE2eeForNewDirectChat } from '@/lib/e2ee';
import { useSettings } from '@/hooks/use-settings';
import type { PlatformSettingsDoc, User } from '@/lib/types';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';

import { useI18n } from '@/hooks/use-i18n';
import { Button } from '@/components/ui/button';

export function ContactProfileClient({ contactUserId }: { contactUserId: string }) {
  const router = useRouter();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { privacySettings } = useSettings();
  const { t } = useI18n();
  const [failed, setFailed] = useState<string | null>(null);
  const [opening, setOpening] = useState(false);
  const startedRef = useRef(false);

  const contactRef = useMemoFirebase(
    () =>
      firestore && contactUserId
        ? doc(firestore, 'users', contactUserId)
        : null,
    [firestore, contactUserId]
  );
  const { data: contactUser, isLoading } = useDoc<User>(contactRef);

  useEffect(() => {
    if (!isLoading && !contactUser) {
      setFailed(t('contacts.profile.notFound'));
    }
  }, [isLoading, contactUser]);

  useEffect(() => {
    if (startedRef.current) return;
    if (!firestore || !currentUser || !contactUser || isLoading) return;
    if (!canStartDirectChat(currentUser, contactUser)) {
      setFailed(t('contacts.profile.cannotOpenChat'));
      return;
    }

    startedRef.current = true;
    setOpening(true);

    (async () => {
      try {
        const id = await createOrOpenDirectChat(firestore, currentUser, contactUser);
        let platformWants = false;
        try {
          const ps = await getDoc(doc(firestore, 'platformSettings', 'main'));
          const p = ps.data() as PlatformSettingsDoc | undefined;
          platformWants = !!p?.e2eeDefaultForNewDirectChats;
        } catch {
          /* ignore */
        }
        await autoEnableE2eeForNewDirectChat(firestore, id, currentUser.id, {
          userWants: privacySettings.e2eeForNewDirectChats === true,
          platformWants,
        });
        router.replace(
          buildDashboardChatOpenUrl(id, {
            openProfile: true,
            profileUserId: contactUserId,
            profileSource: 'contacts',
          })
        );
      } catch (e) {
        console.error('[ContactProfileClient] open chat/profile failed', e);
        startedRef.current = false;
        setFailed(t('contacts.profile.openFailed'));
      } finally {
        setOpening(false);
      }
    })();
  }, [
    firestore,
    currentUser,
    contactUser,
    isLoading,
    contactUserId,
    privacySettings.e2eeForNewDirectChats,
    router,
  ]);

  if (!currentUser) return null;

  return (
    <div className="mx-auto flex w-full max-w-xl flex-col px-4 py-8">
      <div className="rounded-3xl border border-border/60 bg-background/70 p-6 text-center shadow-sm backdrop-blur-xl">
        {failed ? (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">{failed}</p>
            <div className="flex items-center justify-center gap-2">
              <Button
                type="button"
                variant="ghost"
                onClick={() => router.push('/dashboard/contacts')}
              >
                {t('contacts.profile.toContacts')}
              </Button>
              <Button
                type="button"
                onClick={() =>
                  router.push(`/dashboard/contacts/${encodeURIComponent(contactUserId)}/edit`)
                }
              >
                {t('contacts.profile.editContact')}
              </Button>
            </div>
          </div>
        ) : (
          <div className="flex min-h-[180px] flex-col items-center justify-center gap-3">
            <Loader2 className="h-7 w-7 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              {opening || isLoading ? t('contacts.profile.openingProfile') : t('contacts.profile.preparing')}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
