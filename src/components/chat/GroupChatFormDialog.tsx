'use client';

import React, { useState } from 'react';
import type { User, Conversation } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { GroupChatFormPanel } from '@/components/chat/GroupChatFormPanel';

export function GroupChatFormDialog({
  open,
  onOpenChange,
  allUsers,
  contactIds = [],
  currentUser,
  onGroupCreated,
  initialData,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  allUsers: User[];
  contactIds?: string[];
  currentUser: User;
  onGroupCreated: (conversationId: string) => void;
  initialData?: Conversation | null;
}) {
  const { t } = useI18n();
  const [busy, setBusy] = useState(false);

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!next && busy) return;
        onOpenChange(next);
      }}
    >
      <DialogContent className="flex h-[90vh] max-h-[90dvh] flex-col rounded-2xl border-none p-0 shadow-2xl sm:max-w-md">
        <DialogHeader className="flex-shrink-0 bg-muted/30 p-6 pb-4">
          <DialogTitle>{initialData ? t('chat.groupFormDialog.manageGroup') : t('chat.groupFormDialog.createGroup')}</DialogTitle>
            </DialogHeader>
        <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
        <GroupChatFormPanel
          open={open}
          allUsers={allUsers}
          contactIds={contactIds}
          currentUser={currentUser}
          initialData={initialData ?? null}
          onBusyChange={setBusy}
          onCancel={() => onOpenChange(false)}
          onGroupCreated={(id) => {
            onGroupCreated(id);
            onOpenChange(false);
          }}
        />
              </div>
      </DialogContent>
    </Dialog>
  );
}
