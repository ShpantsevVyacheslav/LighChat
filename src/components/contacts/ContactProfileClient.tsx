'use client';

import { useEffect, useRef, useState } from 'react';
import { collection, doc, getDoc, getDocs, limit, query, where } from 'firebase/firestore';
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
import { registrationUsernameKey } from '@/lib/registration-index-keys';

import { Button } from '@/components/ui/button';

export function ContactProfileClient({ contactUserId }: { contactUserId: string }) {
  const router = useRouter();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { privacySettings } = useSettings();
  const [failed, setFailed] = useState<string | null>(null);
  const [opening, setOpening] = useState(false);
  const [resolvedUserId, setResolvedUserId] = useState<string>(contactUserId);
  const [resolvingTarget, setResolvingTarget] = useState(true);
  const startedRef = useRef(false);

  useEffect(() => {
    startedRef.current = false;
  }, [contactUserId]);

  useEffect(() => {
    let active = true;
    (async () => {
      if (!firestore) return;
      const token = contactUserId.trim();
      if (!token) {
        if (!active) return;
        setResolvedUserId('');
        setResolvingTarget(false);
        return;
      }
      setResolvingTarget(true);
      setFailed(null);
      let resolved = '';
      try {
        const directSnap = await getDoc(doc(firestore, 'users', token));
        if (!active) return;
        if (directSnap.exists()) {
          resolved = token;
        }
      } catch {
        // `users/{username}` может вернуть permission-denied для несуществующего
        // документа при строгих правилах чтения. Это не финальная ошибка:
        // ниже пробуем lookup через registrationIndex.
      }

      if (!resolved) {
        const regKey = registrationUsernameKey(token);
        if (regKey) {
          try {
            const regSnap = await getDoc(doc(firestore, 'registrationIndex', regKey));
            if (!active) return;
            const uid = typeof regSnap.data()?.uid === 'string' ? regSnap.data()?.uid.trim() : '';
            if (uid) resolved = uid;
          } catch {
            // ignore
          }
        }
      }

      if (!resolved) {
        const normalized = token.replace(/^@/, '').trim().toLowerCase();
        if (normalized) {
          try {
            const q = query(
              collection(firestore, 'users'),
              where('username', '==', normalized),
              limit(1)
            );
            const snap = await getDocs(q);
            if (!active) return;
            const hit = snap.docs[0];
            if (hit?.id) resolved = hit.id;
          } catch {
            // ignore
          }
        }
      }

      if (!resolved && token && !registrationUsernameKey(token)) {
        // Для старых deep-link'ов с uid сохраняем fallback поведение.
        resolved = token;
      }

      if (!active) return;
      setResolvedUserId(resolved);
      setResolvingTarget(false);
    })();
    return () => {
      active = false;
    };
  }, [firestore, contactUserId]);

  const contactRef = useMemoFirebase(
    () =>
      firestore && resolvedUserId
        ? doc(firestore, 'users', resolvedUserId)
        : null,
    [firestore, resolvedUserId]
  );
  const { data: contactUser, isLoading } = useDoc<User>(contactRef);

  useEffect(() => {
    if (!resolvingTarget && !isLoading && !contactUser) {
      setFailed('Контакт не найден или недоступен.');
    }
  }, [resolvingTarget, isLoading, contactUser]);

  useEffect(() => {
    if (startedRef.current) return;
    if (!firestore || !currentUser || !contactUser || isLoading || resolvingTarget) return;
    if (!canStartDirectChat(currentUser, contactUser)) {
      setFailed('Нельзя открыть чат с этим пользователем.');
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
            profileUserId: resolvedUserId,
            profileSource: 'contacts',
          })
        );
      } catch (e) {
        console.error('[ContactProfileClient] open chat/profile failed', e);
        startedRef.current = false;
        setFailed('Не удалось открыть профиль контакта.');
      } finally {
        setOpening(false);
      }
    })();
  }, [
    firestore,
    currentUser,
    contactUser,
    isLoading,
    resolvedUserId,
    privacySettings.e2eeForNewDirectChats,
    router,
    resolvingTarget,
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
                К контактам
              </Button>
              <Button
                type="button"
                onClick={() =>
                  router.push(`/dashboard/contacts/${encodeURIComponent(resolvedUserId || contactUserId)}/edit`)
                }
              >
                Изм. контакт
              </Button>
            </div>
          </div>
        ) : (
          <div className="flex min-h-[180px] flex-col items-center justify-center gap-3">
            <Loader2 className="h-7 w-7 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              {opening || isLoading ? 'Открываем профиль контакта…' : 'Подготовка…'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
