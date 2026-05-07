'use client';

import { useEffect, useMemo, useState } from 'react';
import { doc } from 'firebase/firestore';
import { Loader2, Lock, ShieldCheck } from 'lucide-react';

import { useDoc, useFirestore, useMemoFirebase, useConversationsByDocumentIds } from '@/firebase';
import type { User, UserChatIndex } from '@/lib/types';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  hasSecretVaultPin,
  isSecretPinLockedError,
  setSecretChatPin,
  verifySecretVaultPin,
} from '@/lib/secret-chat/secret-chat-callables';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';

type UserSecretChatsIndex = {
  conversationIds?: string[];
};

type SecretChatsInboxDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  currentUser: User;
  allUsers: User[];
  onOpenConversation: (conversationId: string) => void;
};

const SECRET_VAULT_PIN_KEY = 'lighchat.secretVault.pin.v1';

function readSavedVaultPin(): string | null {
  if (typeof window === 'undefined') return null;
  const raw = window.localStorage.getItem(SECRET_VAULT_PIN_KEY);
  const pin = (raw ?? '').trim();
  return /^\d{4}$/.test(pin) ? pin : null;
}

function writeSavedVaultPin(pin: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(SECRET_VAULT_PIN_KEY, pin);
}

function clearSavedVaultPin(): void {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(SECRET_VAULT_PIN_KEY);
}

export function SecretChatsInboxDialog({
  open,
  onOpenChange,
  currentUser,
  allUsers,
  onOpenConversation,
}: SecretChatsInboxDialogProps) {
  const firestore = useFirestore();
  const app = firestore.app;
  const [booting, setBooting] = useState(false);
  const [unlocked, setUnlocked] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasVaultPin, setHasVaultPinState] = useState(false);
  const [pinInput, setPinInput] = useState('');
  const [setupPin, setSetupPin] = useState('');
  const [setupPinConfirm, setSetupPinConfirm] = useState('');

  const secretIdxRef = useMemoFirebase(
    () => (firestore && currentUser.id ? doc(firestore, 'userSecretChats', currentUser.id) : null),
    [firestore, currentUser.id]
  );
  const { data: secretIdx } = useDoc<UserSecretChatsIndex>(secretIdxRef);

  const mainIdxRef = useMemoFirebase(
    () => (firestore && currentUser.id ? doc(firestore, 'userChats', currentUser.id) : null),
    [firestore, currentUser.id]
  );
  const { data: mainIdx } = useDoc<UserChatIndex>(mainIdxRef);

  const secretConversationIds = useMemo(() => {
    const fromSecret = secretIdx?.conversationIds ?? [];
    const fromMain = (mainIdx?.conversationIds ?? []).filter((id) => id.startsWith('sdm_'));
    return Array.from(new Set([...fromSecret, ...fromMain]));
  }, [secretIdx?.conversationIds, mainIdx?.conversationIds]);

  const { data: rawConversations, isLoading: isLoadingConversations } = useConversationsByDocumentIds(
    firestore,
    secretConversationIds
  );

  const conversations = useMemo(() => {
    const list = [...(rawConversations ?? [])];
    list.sort((a, b) => {
      const ta = Date.parse(a.lastMessageTimestamp ?? '') || 0;
      const tb = Date.parse(b.lastMessageTimestamp ?? '') || 0;
      return tb - ta;
    });
    return list;
  }, [rawConversations]);

  useEffect(() => {
    if (!open) {
      setUnlocked(false);
      setError(null);
      setPinInput('');
      setSetupPin('');
      setSetupPinConfirm('');
      return;
    }

    let cancelled = false;
    const run = async () => {
      setBooting(true);
      setError(null);
      try {
        const res = await hasSecretVaultPin(app);
        if (cancelled) return;
        setHasVaultPinState(res.hasPin);

        if (!res.hasPin) {
          setUnlocked(false);
          return;
        }

        const saved = readSavedVaultPin();
        if (!saved) {
          setUnlocked(false);
          return;
        }

        try {
          await verifySecretVaultPin(app, saved);
          if (!cancelled) setUnlocked(true);
        } catch {
          clearSavedVaultPin();
          if (!cancelled) setUnlocked(false);
        }
      } catch {
        if (!cancelled) {
          setError('Не удалось проверить настройки секретного хранилища. Попробуйте снова.');
          setUnlocked(false);
        }
      } finally {
        if (!cancelled) setBooting(false);
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [open, app]);

  const handleUnlock = async (pinOverride?: string) => {
    const pin = (pinOverride ?? pinInput).trim();
    if (!/^\d{4}$/.test(pin)) {
      setError('Введите 4-значный PIN.');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await verifySecretVaultPin(app, pin);
      writeSavedVaultPin(pin);
      setUnlocked(true);
    } catch (e) {
      if (isSecretPinLockedError(e)) {
        setError('Слишком много попыток. Попробуйте позже.');
      } else {
        setError('Неверный PIN или доступ временно недоступен.');
      }
    } finally {
      setBusy(false);
    }
  };

  const handleSetupPin = async () => {
    const first = setupPin.trim();
    const second = setupPinConfirm.trim();
    if (!/^\d{4}$/.test(first)) {
      setError('Новый PIN должен состоять из 4 цифр.');
      return;
    }
    if (first !== second) {
      setError('PIN и подтверждение не совпадают.');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await setSecretChatPin(app, first);
      setHasVaultPinState(true);
      writeSavedVaultPin(first);
      setUnlocked(true);
      setPinInput(first);
    } catch {
      setError('Не удалось установить PIN. Попробуйте ещё раз.');
    } finally {
      setBusy(false);
    }
  };

  const renderLockedState = () => {
    if (!hasVaultPin) {
      return (
        <div className="space-y-4">
          <div className="rounded-lg border p-3 text-sm text-muted-foreground">
            Для входа в список секретных чатов нужно настроить PIN секретного хранилища.
          </div>
          <div className="space-y-2">
            <Label htmlFor="secret-vault-pin-new">Новый PIN (4 цифры)</Label>
            <Input
              id="secret-vault-pin-new"
              type="password"
              inputMode="numeric"
              maxLength={4}
              value={setupPin}
              onChange={(e) => setSetupPin(e.target.value.replace(/\D+/g, '').slice(0, 4))}
              disabled={busy}
              placeholder="••••"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="secret-vault-pin-repeat">Повторите PIN</Label>
            <Input
              id="secret-vault-pin-repeat"
              type="password"
              inputMode="numeric"
              maxLength={4}
              value={setupPinConfirm}
              onChange={(e) => setSetupPinConfirm(e.target.value.replace(/\D+/g, '').slice(0, 4))}
              disabled={busy}
              placeholder="••••"
            />
          </div>
          <Button type="button" className="w-full" onClick={() => void handleSetupPin()} disabled={busy}>
            {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <ShieldCheck className="mr-2 h-4 w-4" />}
            Установить PIN
          </Button>
        </div>
      );
    }

    const savedPin = readSavedVaultPin();

    return (
      <div className="space-y-4">
        <div className="rounded-lg border p-3 text-sm text-muted-foreground">
          Введите PIN, чтобы открыть список секретных чатов.
        </div>
        <div className="space-y-2">
          <Label htmlFor="secret-vault-pin">PIN</Label>
          <Input
            id="secret-vault-pin"
            type="password"
            inputMode="numeric"
            maxLength={4}
            value={pinInput}
            onChange={(e) => setPinInput(e.target.value.replace(/\D+/g, '').slice(0, 4))}
            disabled={busy}
            placeholder="••••"
          />
        </div>
        <div className="flex flex-wrap gap-2">
          <Button type="button" onClick={() => void handleUnlock()} disabled={busy}>
            {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Lock className="mr-2 h-4 w-4" />}
            Разблокировать
          </Button>
          {savedPin ? (
            <Button
              type="button"
              variant="outline"
              disabled={busy}
              onClick={() => {
                setPinInput(savedPin);
                void handleUnlock(savedPin);
              }}
            >
              Использовать сохранённый PIN
            </Button>
          ) : null}
        </div>
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Secret Chats</DialogTitle>
          <DialogDescription>
            Отдельный список секретных диалогов с PIN-защитой.
          </DialogDescription>
        </DialogHeader>

        {booting ? (
          <div className="flex items-center justify-center py-10">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : unlocked ? (
          <div className="max-h-[55vh] space-y-2 overflow-y-auto">
            {isLoadingConversations ? (
              <div className="flex items-center justify-center py-10">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : conversations.length === 0 ? (
              <p className="py-8 text-center text-sm text-muted-foreground">
                Секретных чатов пока нет.
              </p>
            ) : (
              conversations.map((conv) => {
                const otherId = conv.participantIds.find((id) => id !== currentUser.id) ?? currentUser.id;
                const otherUser = allUsers.find((u) => u.id === otherId);
                const info = conv.participantInfo[otherId];
                const displayName =
                  (!conv.isGroup && (otherUser?.name || info?.name)) || conv.name || 'Секретный чат';
                const avatarUrl = conv.isGroup
                  ? conv.photoUrl
                  : participantListAvatarUrl(otherUser, info);
                const initial = (displayName || '?').trim().charAt(0).toUpperCase() || '?';
                const lastTs = conv.lastMessageTimestamp ? new Date(conv.lastMessageTimestamp) : null;

                return (
                  <button
                    key={conv.id}
                    type="button"
                    className="flex w-full items-center gap-3 rounded-xl border p-2 text-left transition-colors hover:bg-muted/40"
                    onClick={() => {
                      onOpenConversation(conv.id);
                      onOpenChange(false);
                    }}
                  >
                    <Avatar className="h-10 w-10">
                      <AvatarImage src={avatarUrl || undefined} alt={displayName} />
                      <AvatarFallback>{initial}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold">{displayName}</p>
                      <p className="truncate text-xs text-muted-foreground">
                        {conv.lastMessageText?.trim() || 'Сообщений пока нет'}
                      </p>
                    </div>
                    <div className="shrink-0 text-[10px] text-muted-foreground">
                      {lastTs ? lastTs.toLocaleString() : ''}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        ) : (
          renderLockedState()
        )}

        {error ? <p className="text-sm text-destructive">{error}</p> : null}
      </DialogContent>
    </Dialog>
  );
}
