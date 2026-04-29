import type { Conversation, User } from '@/lib/types';
import { chatUserDisplayName } from '@/lib/chat-user-search';

/**
 * Снимок участника для `conversations.participantInfo` при записи в Firestore.
 * Убирает поля со значением `undefined` — иначе `setDoc` / `updateDoc` падают.
 */
export function participantInfoEntryForWrite(
  user: Pick<User, 'name' | 'avatar' | 'avatarThumb'>
): Conversation['participantInfo'][string] {
  const entry: Conversation['participantInfo'][string] = {
    name: chatUserDisplayName({ id: '', username: '', email: '', ...user }),
    avatar: user.avatar ?? '',
  };
  const thumb = user.avatarThumb?.trim();
  if (thumb) {
    entry.avatarThumb = thumb;
  }
  return entry;
}
