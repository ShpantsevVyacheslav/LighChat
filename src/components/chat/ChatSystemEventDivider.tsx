'use client';

/**
 * Phase 8 — рендер system-event маркера E2EE v2 в timeline чата.
 *
 * Используется только для сообщений с `systemEvent`: bubble заменяется
 * компактной центрированной плашкой. Если тип события неизвестен — показываем
 * generic-строку «Системное событие», чтобы старый клиент, увидев новый
 * forward-compatible type, не падал.
 */

import { Lock, LockOpen, Shield, Smartphone, Fingerprint, RefreshCw } from 'lucide-react';
import type { ChatSystemEvent } from '@/lib/types';
import { cn } from '@/lib/utils';

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
    default:
      return Lock;
  }
}

function renderText(event: ChatSystemEvent): string {
  const actor = event.data?.actorName ?? 'Пользователь';
  const device = event.data?.deviceLabel ?? 'устройство';
  switch (event.type) {
    case 'e2ee.v2.enabled':
      return 'Сквозное шифрование включено';
    case 'e2ee.v2.disabled':
      return 'Сквозное шифрование отключено';
    case 'e2ee.v2.epoch.rotated':
      return 'Ключ шифрования обновлён';
    case 'e2ee.v2.device.added':
      return `${actor} добавил устройство «${device}»`;
    case 'e2ee.v2.device.revoked':
      return `${actor} отозвал устройство «${device}»`;
    case 'e2ee.v2.fingerprint.changed':
      return `Отпечаток безопасности у ${actor} изменился`;
    default:
      return 'Системное событие';
  }
}

export function ChatSystemEventDivider({
  event,
  className,
}: {
  event: ChatSystemEvent;
  className?: string;
}) {
  const Icon = pickIcon(event.type);
  const label = renderText(event);
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
