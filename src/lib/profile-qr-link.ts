const LIGHCHAT_WEB_HOST = 'lighchat.online';
const LIGHCHAT_WEB_HOST_WWW = 'www.lighchat.online';

export function buildProfileShareUrl(userId: string): string {
  const uid = userId.trim();
  if (!uid) return `https://${LIGHCHAT_WEB_HOST}/dashboard/contacts`;
  return `https://${LIGHCHAT_WEB_HOST}/dashboard/contacts/${encodeURIComponent(uid)}`;
}

export function buildProfileQrPayload(params: { userId: string; username?: string | null }): string {
  const uid = params.userId.trim();
  if (!uid) return '';
  const url = new URL(buildProfileShareUrl(uid));
  const username = (params.username ?? '').trim().replace(/^@/, '');
  if (username) url.searchParams.set('u', username);
  return url.toString();
}

export function extractProfileUserIdFromQrPayload(payload: string): string | null {
  const raw = payload.trim();
  if (!raw) return null;

  const compact = raw.replace(/\s+/g, '');
  if (compact.startsWith('lighchat_profile:')) {
    const uid = compact.slice('lighchat_profile:'.length).trim();
    return uid || null;
  }

  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    return null;
  }

  const fromQuery = parsed.searchParams.get('uid') ?? parsed.searchParams.get('userId');
  if (fromQuery && fromQuery.trim()) {
    return decodeURIComponent(fromQuery.trim());
  }

  const protocol = parsed.protocol.toLowerCase();
  if (protocol === 'lighchat:' && parsed.hostname.toLowerCase() === 'profile') {
    const path = parsed.pathname.replace(/^\/+/, '').trim();
    if (path) return decodeURIComponent(path);
  }

  const host = parsed.hostname.toLowerCase();
  const segments = parsed.pathname.split('/').filter(Boolean);
  if (
    (host === LIGHCHAT_WEB_HOST || host === LIGHCHAT_WEB_HOST_WWW) &&
    segments.length >= 3 &&
    segments[0] === 'dashboard' &&
    segments[1] === 'contacts'
  ) {
    return decodeURIComponent(segments[2] ?? '');
  }

  if (segments.length >= 3 && segments[0] === 'contacts' && segments[1] === 'user') {
    return decodeURIComponent(segments[2] ?? '');
  }

  return null;
}
