const LIGHCHAT_WEB_HOST = 'lighchat.online';
const LIGHCHAT_WEB_HOST_WWW = 'www.lighchat.online';

function normalizeUsernameToken(raw: string | null | undefined): string {
  return String(raw ?? '').trim().replace(/^@/, '').toLowerCase();
}

function looksLikeUserIdToken(token: string): boolean {
  const v = token.trim();
  if (!v) return false;
  if (v.startsWith('tg_') || v.startsWith('ya_')) return true;
  // Firebase UID in this project is usually >= 20 chars mixed-case/digits.
  return /^[A-Za-z0-9_-]{20,}$/.test(v);
}

export function buildProfileShareUrl(
  userId: string,
  username?: string | null
): string {
  const uid = userId.trim();
  if (!uid) return `https://${LIGHCHAT_WEB_HOST}/dashboard/contacts`;
  const normalizedUsername = normalizeUsernameToken(username);
  if (!normalizedUsername) {
    return `https://${LIGHCHAT_WEB_HOST}/dashboard/contacts/${encodeURIComponent(uid)}`;
  }
  return `https://${LIGHCHAT_WEB_HOST}/dashboard/contacts/${encodeURIComponent(normalizedUsername)}`;
}

export function buildProfileQrPayload(params: { userId: string; username?: string | null }): string {
  const uid = params.userId.trim();
  if (!uid) return '';
  const username = normalizeUsernameToken(params.username);
  const url = new URL(buildProfileShareUrl(uid, username));
  if (username) url.searchParams.set('u', username);
  return url.toString();
}

export type ProfileQrTarget = {
  userId: string | null;
  username: string | null;
};

export function extractProfileTargetFromQrPayload(payload: string): ProfileQrTarget {
  const empty: ProfileQrTarget = { userId: null, username: null };
  const raw = payload.trim();
  if (!raw) return empty;

  const compact = raw.replace(/\s+/g, '');
  if (compact.startsWith('lighchat_profile:')) {
    const uid = compact.slice('lighchat_profile:'.length).trim();
    return { userId: uid || null, username: null };
  }

  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    return empty;
  }

  const queryUid = parsed.searchParams.get('uid') ?? parsed.searchParams.get('userId');
  const queryUsername = parsed.searchParams.get('u') ?? parsed.searchParams.get('username');
  const normalizedQueryUsername = normalizeUsernameToken(queryUsername);

  if (queryUid && queryUid.trim()) {
    return {
      userId: decodeURIComponent(queryUid.trim()),
      username: normalizedQueryUsername || null,
    };
  }

  const protocol = parsed.protocol.toLowerCase();
  if (protocol === 'lighchat:' && parsed.hostname.toLowerCase() === 'profile') {
    const path = parsed.pathname.replace(/^\/+/, '').trim();
    if (path) return { userId: decodeURIComponent(path), username: null };
  }

  const host = parsed.hostname.toLowerCase();
  const segments = parsed.pathname.split('/').filter(Boolean);
  if (
    (host === LIGHCHAT_WEB_HOST || host === LIGHCHAT_WEB_HOST_WWW) &&
    segments.length >= 3 &&
    segments[0] === 'dashboard' &&
    segments[1] === 'contacts'
  ) {
    const token = decodeURIComponent(segments[2] ?? '').trim();
    if (!token) return empty;
    if (looksLikeUserIdToken(token)) {
      return {
        userId: token,
        username: normalizedQueryUsername || null,
      };
    }
    return {
      userId: null,
      username: normalizeUsernameToken(token) || normalizedQueryUsername || null,
    };
  }

  if (segments.length >= 3 && segments[0] === 'contacts' && segments[1] === 'user') {
    const uid = decodeURIComponent(segments[2] ?? '').trim();
    if (uid) return { userId: uid, username: null };
  }

  return empty;
}

export function extractProfileUserIdFromQrPayload(payload: string): string | null {
  return extractProfileTargetFromQrPayload(payload).userId;
}
