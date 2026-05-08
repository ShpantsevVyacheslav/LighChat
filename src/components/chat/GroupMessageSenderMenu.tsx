'use client';

import type { ReactNode } from 'react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { UserCircle2, MessageCircle } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

export type GroupMessageSenderMenuProps = {
  senderId: string;
  currentUserId: string;
  disabled?: boolean;
  onOpenProfile: (userId: string) => void;
  onWritePrivate: (userId: string) => void | Promise<void>;
  children: ReactNode;
};

/**
 * Меню по клику на аватар/имя отправителя в групповом чате (не своё сообщение).
 * stopPropagation у триггера — чтобы не срабатывало выделение сообщений и жесты строки.
 */
export function GroupMessageSenderMenu({
  senderId,
  currentUserId,
  disabled,
  onOpenProfile,
  onWritePrivate,
  children,
}: GroupMessageSenderMenuProps) {
  const { t } = useI18n();

  if (disabled || senderId === currentUserId) {
    return <>{children}</>;
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>{children}</DropdownMenuTrigger>
      <DropdownMenuContent
        align="start"
        side="bottom"
        className="min-w-[11rem]"
        onCloseAutoFocus={(e) => e.preventDefault()}
      >
        <DropdownMenuItem className="cursor-pointer" onSelect={() => onOpenProfile(senderId)}>
          <UserCircle2 className="mr-2 h-4 w-4" />
          {t('chat.groupSenderMenu.openProfile')}
        </DropdownMenuItem>
        <DropdownMenuItem
          className="cursor-pointer"
          onSelect={() => {
            void Promise.resolve(onWritePrivate(senderId)).catch((err) => {
              console.error('[GroupMessageSenderMenu] onWritePrivate failed', err);
            });
          }}
        >
          <MessageCircle className="mr-2 h-4 w-4" />
          {t('chat.groupSenderMenu.writePrivate')}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
