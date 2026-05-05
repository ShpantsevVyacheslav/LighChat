'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { MockChatHeader, MockChatInput } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';
import { getFeaturesContent } from '../features-content';

/**
 * Чат с исчезающими сообщениями: обычные баблы (шапка/мета как в реальном
 * UI), а старые сообщения в верхней части тают через `animate-feat-fade-vanish`.
 * Никаких выдуманных пилюль «таймер 24ч» в шапке или внизу — в реальном
 * LighChat TTL живёт в меню по long-press, а в чате визуально отмечается
 * только тем, что старые сообщения исчезают.
 */
export function MockDisappearing({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name={t.teamDesign} status={t.disappearingStatus} />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        {/* Старые тающие сообщения (вверху) */}
        <div className="animate-feat-fade-vanish">
          <MockMessageBubble side="outgoing" text={t.disappearingMsg4} time="09:18" animateIn={false} />
        </div>
        <div className="animate-feat-fade-vanish" style={{ animationDelay: '600ms' }}>
          <MockMessageBubble side="incoming" text={t.disappearingMsg3} time="09:16" animateIn={false} />
        </div>
        {/* Свежие — обычные */}
        <MockMessageBubble side="outgoing" text={t.disappearingMsg2} time="09:15" delayMs={0} />
        <MockMessageBubble side="incoming" text={t.disappearingMsg1} time="09:14" delayMs={250} />
      </div>
      {!compact ? <MockChatInput placeholder={t.peerHello} /> : null}
    </div>
  );
}
