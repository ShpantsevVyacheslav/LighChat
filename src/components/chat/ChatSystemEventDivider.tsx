'use client';

/**
 * Phase 8 — рендер system-event маркера E2EE v2 в timeline чата.
 *
 * Используется только для сообщений с `systemEvent`: bubble заменяется
 * компактной центрированной плашкой. Если тип события неизвестен — показываем
 * generic-строку «Системное событие», чтобы старый клиент, увидев новый
 * forward-compatible type, не падал.
 */

import { Lock, LockOpen, Shield, Smartphone, Fingerprint, RefreshCw, Swords } from 'lucide-react';
import type { ChatSystemEvent } from '@/lib/types';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

function pickIcon(type: ChatSystemEvent['type']) {
  switch (type) {
    case 'e2ee.v2.enabled':
      return Lock;
    case 'e2ee.v2.disabled':
      return LockOpen;
    case 'e2ee.v2.epoch.rotated':
      return RefreshCw;
    case 'e2ee.v2.device.added':
      return Smartphone;
    case 'e2ee.v2.device.revoked':
      return Shield;
    case 'e2ee.v2.fingerprint.changed':
      return Fingerprint;
    case 'gameLobbyCreated':
    case 'gameStarted':
      return Swords;
    default:
      return Lock;
  }
}

function renderText(event: ChatSystemEvent, t: (key: string) => string): string {
  const actor = event.data?.actorName ?? t('chat.systemEvent.fallbackActor');
  const device = event.data?.deviceLabel ?? t('chat.systemEvent.fallbackDevice');
  switch (event.type) {
    case 'e2ee.v2.enabled':
      return t('chat.systemEvent.e2eeEnabled');
    case 'e2ee.v2.disabled':
      return t('chat.systemEvent.e2eeDisabled');
    case 'e2ee.v2.epoch.rotated':
      return t('chat.systemEvent.keyRotated');
    case 'e2ee.v2.device.added':
      return t('chat.systemEvent.deviceAdded').replace('{actor}', actor).replace('{device}', device);
    case 'e2ee.v2.device.revoked':
      return t('chat.systemEvent.deviceRevoked').replace('{actor}', actor).replace('{device}', device);
    case 'e2ee.v2.fingerprint.changed':
      return t('chat.systemEvent.fingerprintChanged').replace('{actor}', actor);
    case 'gameLobbyCreated':
      return event.data?.gameType === 'durak' ? t('chat.systemEvent.durakCreated') : t('chat.systemEvent.gameCreated');
    case 'gameStarted':
      return event.data?.gameType === 'durak' ? t('chat.systemEvent.durakStarted') : t('chat.systemEvent.gameStarted');
    default:
      return t('chat.systemEvent.fallback');
  }
}

export function ChatSystemEventDivider({
  event,
  className,
}: {
  event: ChatSystemEvent;
  className?: string;
}) {
  const { t } = useI18n();
  const Icon = pickIcon(event.type);
  const label = renderText(event, t);
  return (
    <div
      className={cn(
        'flex items-center justify-center my-2 px-4',
        className
      )}
      data-testid="chat-system-event"
      data-event-type={event.type}
    >
      <div className="flex items-center gap-1.5 text-xs text-muted-foreground bg-muted/50 rounded-full px-3 py-1">
        <Icon className="h-3 w-3" aria-hidden />
        <span>{label}</span>
      </div>
    </div>
  );
}
