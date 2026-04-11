'use client';

import { ChatForwardSheet } from '@/components/chat/ChatForwardSheet';

/**
 * Маршрут пересылки: UI — шторка (`ChatForwardSheet`), данные сообщений из sessionStorage `forwardMessages`.
 */
export default function ForwardPage() {
  return <ChatForwardSheet />;
}
