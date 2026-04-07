/**
 * URL вложений, которые уже отображались в чате в этой сессии вкладки.
 * Позволяет ставить loading="eager" при повторном монтировании после скролла (Virtuoso).
 */
const galleryUrlsLoadedInSession = new Set<string>();

export function markChatGalleryMediaUrlSeen(url: string) {
  if (url) galleryUrlsLoadedInSession.add(url);
}

export function isChatGalleryMediaUrlSeen(url: string): boolean {
  return !!url && galleryUrlsLoadedInSession.has(url);
}
