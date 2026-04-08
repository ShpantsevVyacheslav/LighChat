import type { User } from '@/lib/types';

/**
 * Снимок участника в документе чата (денормализация).
 */
export type ParticipantAvatarSnap = {
  avatar?: string;
  avatarThumb?: string;
};

type AvatarSource = Pick<User, 'avatar' | 'avatarThumb'> | ParticipantAvatarSnap | null | undefined;

/**
 * URL круглого превью для списков, шапки чата, «пузырей» и т.д.
 * Если `avatarThumb` нет — падаем обратно на полный `avatar` (старые данные).
 */
export function userAvatarListUrl(user?: AvatarSource): string {
  if (!user) return '';
  const t = user.avatarThumb?.trim();
  if (t) return t;
  return user.avatar ?? '';
}

/**
 * Аватар для круглых миниатюр: сначала живой `User`, иначе снимок из `participantInfo`.
 */
export function participantListAvatarUrl(live?: AvatarSource, snap?: ParticipantAvatarSnap): string {
  const fromLive = userAvatarListUrl(live);
  if (fromLive) return fromLive;
  const t = snap?.avatarThumb?.trim();
  if (t) return t;
  return snap?.avatar ?? '';
}
