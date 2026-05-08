'use client';

/**
 * Phase 8 — компонент для отображения отпечатка безопасности собеседника в DM.
 *
 * Логика:
 *  - Получает `userId` участника и вычисляет fingerprint из активных v2-устройств
 *    (`users/{uid}/e2eeDevices/*`).
 *  - 64-символьный hex разбивается на группы по 4 символа (читаемо).
 *  - Используется как доп. info в `ChatParticipantProfile` / диалогах «Шифрование».
 *    При совпадении с отпечатком, который видит собеседник на своей стороне,
 *    E2EE-канал доверенный (см. §9.3 RFC).
 *
 * Ожидает `firestore` из `useFirestore`. Загрузка асинхронная; пока фетчим —
 * показываем skeleton (в `ChatSystemEventDivider` не нуждается).
 */

import { useEffect, useState } from 'react';
import { Fingerprint, Loader2 } from 'lucide-react';
import type { Firestore } from 'firebase/firestore';
import { useI18n } from '@/hooks/use-i18n';

import { computeUserFingerprintV2, listActiveE2eeDevicesV2 } from '@/lib/e2ee';
import { cn } from '@/lib/utils';

function formatFingerprintHex(hex: string): string {
  const normalized = hex.toLowerCase();
  const groups: string[] = [];
  for (let i = 0; i < normalized.length; i += 4) {
    groups.push(normalized.slice(i, i + 4));
  }
  return groups.join(' ');
}

export type E2eeFingerprintBadgeProps = {
  firestore: Firestore;
  userId: string;
  /** Display-имя пользователя (для подписи). */
  userLabel?: string;
  className?: string;
};

export function E2eeFingerprintBadge({
  firestore,
  userId,
  userLabel,
  className,
}: E2eeFingerprintBadgeProps) {
  const { t } = useI18n();
  const [fp, setFp] = useState<string | null>(null);
  const [devicesCount, setDevicesCount] = useState<number | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    (async () => {
      try {
        const devices = await listActiveE2eeDevicesV2(firestore, userId);
        if (cancelled) return;
        setDevicesCount(devices.length);
        if (devices.length === 0) {
          setFp(null);
        } else {
          const hex = await computeUserFingerprintV2(devices);
          if (!cancelled) setFp(hex);
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : String(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firestore, userId]);

  if (loading) {
    return (
      <div
        className={cn(
          'flex items-center gap-2 text-xs text-muted-foreground',
          className
        )}
      >
        <Loader2 className="h-3 w-3 animate-spin" aria-hidden />
        <span>{t('chat.e2eeFingerprint.loading')}</span>
      </div>
    );
  }

  if (error) {
    return (
      <div
        className={cn('text-xs text-destructive', className)}
        data-testid="e2ee-fingerprint-error"
      >
        {t('chat.e2eeFingerprint.error')}: {error}
      </div>
    );
  }

  if (!fp || !devicesCount) {
    return (
      <div
        className={cn('text-xs text-muted-foreground', className)}
        data-testid="e2ee-fingerprint-empty"
      >
        {t('chat.e2eeFingerprint.noDevices').replace('{user}', userLabel ?? t('chat.userLabel'))}
      </div>
    );
  }

  return (
    <div
      className={cn('flex items-start gap-2', className)}
      data-testid="e2ee-fingerprint-badge"
    >
      <Fingerprint className="h-4 w-4 text-muted-foreground mt-0.5" aria-hidden />
      <div className="space-y-0.5">
        <div className="text-xs text-muted-foreground">
          {t('chat.e2eeFingerprint.label')} {userLabel ? `• ${userLabel}` : ''}{' '}
          <span className="opacity-60">({devicesCount} {t('chat.e2eeFingerprint.devicesShort')})</span>
        </div>
        <code
          className="block text-xs font-mono tracking-tight break-all select-all"
          aria-label="E2EE fingerprint"
        >
          {formatFingerprintHex(fp)}
        </code>
      </div>
    </div>
  );
}
