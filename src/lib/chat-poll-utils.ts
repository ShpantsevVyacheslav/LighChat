import type { Conversation, MeetingPoll, User } from '@/lib/types';

/** Участники чата как User[] для отображения голосов (как в конференциях). */
export function conversationMembersAsUsers(conversation: Conversation, allUsers: User[]): User[] {
  return conversation.participantIds.map((id) => {
    const u = allUsers.find((x) => x.id === id);
    if (u) return u;
    const info = conversation.participantInfo[id];
    return {
      id,
      name: info?.name || 'Участник',
      username: '',
      email: '',
      avatar: info?.avatar || '',
      phone: '',
      role: 'worker' as const,
      deletedAt: null,
      createdAt: '',
    } as User;
  });
}

export function canModerateChatPoll(
  conversation: Conversation,
  currentUserId: string,
  poll: MeetingPoll
): boolean {
  if (poll.creatorId === currentUserId) return true;
  if (!conversation.isGroup) return false;
  if (conversation.createdByUserId === currentUserId) return true;
  return (conversation.adminIds || []).includes(currentUserId);
}
