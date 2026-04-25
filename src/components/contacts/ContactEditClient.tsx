'use client';

import { useEffect, useMemo, useState } from 'react';
import { Loader2 } from 'lucide-react';
import { doc } from 'firebase/firestore';
import { useRouter } from 'next/navigation';

import { useAuth } from '@/hooks/use-auth';
import { useContactDisplayNames } from '@/hooks/use-contact-display-names';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { splitNameForContactForm } from '@/lib/contact-display-name';
import { upsertContactProfile } from '@/lib/contacts-client-actions';
import type { User } from '@/lib/types';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { userAvatarListUrl } from '@/lib/user-avatar-display';

export function ContactEditClient({ contactUserId }: { contactUserId: string }) {
  const router = useRouter();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { contactProfiles } = useContactDisplayNames(currentUser?.id);

  const contactRef = useMemoFirebase(
    () =>
      firestore && contactUserId
        ? doc(firestore, 'users', contactUserId)
        : null,
    [firestore, contactUserId]
  );
  const { data: contactUser, isLoading } = useDoc<User>(contactRef);

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [busy, setBusy] = useState(false);
  const [seeded, setSeeded] = useState(false);

  const localProfile = contactProfiles[contactUserId];
  const fallbackName = (contactUser?.name ?? '').trim();

  useEffect(() => {
    if (seeded) return;
    if (!contactUser && !localProfile) return;
    const seedFromLocalFirst = (localProfile?.firstName ?? '').trim();
    const seedFromLocalLast = (localProfile?.lastName ?? '').trim();
    if (seedFromLocalFirst || seedFromLocalLast) {
      setFirstName(seedFromLocalFirst);
      setLastName(seedFromLocalLast);
      setSeeded(true);
      return;
    }
    const split = splitNameForContactForm(
      (localProfile?.displayName ?? '').trim() || fallbackName
    );
    setFirstName(split.firstName);
    setLastName(split.lastName);
    setSeeded(true);
  }, [seeded, contactUser, localProfile, fallbackName]);

  const canSave = useMemo(
    () => firstName.trim().length > 0 && !busy && !!currentUser && !!firestore,
    [firstName, busy, currentUser, firestore]
  );

  const save = async () => {
    if (!canSave || !currentUser || !firestore) return;
    setBusy(true);
    try {
      await upsertContactProfile(firestore, currentUser.id, contactUserId, {
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      });
      router.replace(`/dashboard/contacts/${encodeURIComponent(contactUserId)}`);
    } finally {
      setBusy(false);
    }
  };

  if (!currentUser) return null;

  return (
    <div className="mx-auto flex w-full max-w-xl flex-col px-4 py-5">
      <div className="mb-6 flex items-center justify-between">
        <Button
          type="button"
          variant="ghost"
          className="rounded-full"
          onClick={() =>
            router.push(`/dashboard/contacts/${encodeURIComponent(contactUserId)}`)
          }
          disabled={busy}
        >
          Отмена
        </Button>
        <Button type="button" className="rounded-full" disabled={!canSave} onClick={save}>
          {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Готово
        </Button>
      </div>

      <div className="rounded-3xl border border-border/60 bg-background/70 p-6 shadow-sm backdrop-blur-xl">
        {isLoading ? (
          <div className="flex min-h-[220px] items-center justify-center">
            <Loader2 className="h-7 w-7 animate-spin text-muted-foreground" />
          </div>
        ) : !contactUser ? (
          <p className="py-14 text-center text-sm text-muted-foreground">
            Пользователь недоступен.
          </p>
        ) : (
          <div className="space-y-5">
            <div className="flex items-center gap-4">
              <Avatar className="h-16 w-16 ring-1 ring-black/5 dark:ring-white/10">
                <AvatarImage src={userAvatarListUrl(contactUser)} alt={contactUser.name} />
                <AvatarFallback className="text-lg font-semibold">
                  {contactUser.name.charAt(0)}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0">
                <p className="truncate text-sm font-medium text-muted-foreground">Редактирование контакта</p>
                <p className="truncate text-base font-semibold">{contactUser.name}</p>
              </div>
            </div>

            <div className="space-y-3">
              <Input
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                placeholder="Имя"
                disabled={busy}
                className="h-11 rounded-xl"
              />
              <Input
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                placeholder="Фамилия"
                disabled={busy}
                className="h-11 rounded-xl"
              />
              <p className="text-xs text-muted-foreground">
                Это имя будет видно только вам: в чатах, поиске и списке контактов.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
