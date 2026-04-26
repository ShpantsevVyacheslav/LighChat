import type { User } from '@/lib/types';

/** Нормализует `users.blockedUserIds` из Firestore. */
export function normalizeBlockedUserIds(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return [
    ...new Set(
      raw.filter((x): x is string => typeof x === 'string' && x.trim().length > 0).map((x) => x.trim()),
    ),
  ];
}

/**
 * Личный чат: либо viewer заблокировал partner, либо partner заблокировал viewer
 * (второе известно только если доступен документ partner с полем blockedUserIds).
 */
export function isEitherBlockingFromUserIds(
  viewerId: string,
  viewerBlockedIds: string[] | undefined,
  partnerId: string,
  partnerBlockedIds: string[] | undefined | null,
): boolean {
  if (normalizeBlockedUserIds(viewerBlockedIds).includes(partnerId)) return true;
  if (partnerBlockedIds == null) return false;
  return normalizeBlockedUserIds(partnerBlockedIds).includes(viewerId);
}

export function isEitherBlockingFromUsers(viewer: User, partner: User): boolean {
  return isEitherBlockingFromUserIds(
    viewer.id,
    viewer.blockedUserIds,
    partner.id,
    partner.blockedUserIds ?? null,
  );
}

/** Текст для композера: кто кого заблокировал (если известно). */
export function directChatComposerBlockedHint(
  viewerId: string,
  viewerBlockedIds: string[] | undefined,
  partnerId: string,
  partnerBlockedIds: string[] | undefined | null,
): string {
  if (normalizeBlockedUserIds(viewerBlockedIds).includes(partnerId)) {
    return 'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в разделе «Заблокированные» в профиле.';
  }
  if (partnerBlockedIds != null && normalizeBlockedUserIds(partnerBlockedIds).includes(viewerId)) {
    return 'Пользователь ограничил с вами общение. Отправка недоступна.';
  }
  return 'Общение недоступно.';
}
