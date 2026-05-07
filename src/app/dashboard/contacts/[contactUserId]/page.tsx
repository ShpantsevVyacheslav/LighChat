import type { Metadata } from 'next';

import { adminDb } from '@/firebase/admin';
import { ContactProfileClient } from '@/components/contacts/ContactProfileClient';

type PublicContactPreview = {
  name: string;
  username: string;
  avatar: string | null;
};

function normalizeUsernameToken(raw: string): string {
  return raw.trim().replace(/^@/, '').toLowerCase();
}

async function resolvePublicContactPreview(
  contactToken: string
): Promise<PublicContactPreview | null> {
  const token = contactToken.trim();
  if (!token) return null;

  // 1) UID path (legacy and still supported).
  const byUid = await adminDb.collection('users').doc(token).get();
  if (byUid.exists) {
    const data = byUid.data() ?? {};
    const name = typeof data.name === 'string' ? data.name.trim() : '';
    const usernameRaw = typeof data.username === 'string' ? data.username.trim() : '';
    const username = normalizeUsernameToken(usernameRaw);
    if (name) {
      return {
        name,
        username,
        avatar:
          (typeof data.avatarThumb === 'string' && data.avatarThumb.trim()) ||
          (typeof data.avatar === 'string' && data.avatar.trim()) ||
          null,
      };
    }
  }

  // 2) Username slug via public registration index.
  const normalized = normalizeUsernameToken(token);
  if (!normalized) return null;
  const idxSnap = await adminDb.collection('registrationIndex').doc(`u_${normalized}`).get();
  const uid = typeof idxSnap.data()?.uid === 'string' ? idxSnap.data()?.uid.trim() : '';
  if (uid) {
    const userSnap = await adminDb.collection('users').doc(uid).get();
    if (userSnap.exists) {
      const data = userSnap.data() ?? {};
      const name = typeof data.name === 'string' ? data.name.trim() : '';
      const usernameRaw = typeof data.username === 'string' ? data.username.trim() : '';
      const username = normalizeUsernameToken(usernameRaw || normalized);
      if (name) {
        return {
          name,
          username,
          avatar:
            (typeof data.avatarThumb === 'string' && data.avatarThumb.trim()) ||
            (typeof data.avatar === 'string' && data.avatar.trim()) ||
            null,
        };
      }
    }
  }

  // 3) Defensive fallback for stale index.
  const byUsername = await adminDb
    .collection('users')
    .where('username', '==', normalized)
    .limit(1)
    .get();
  if (byUsername.empty) return null;
  const data = byUsername.docs[0]?.data() ?? {};
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  const usernameRaw = typeof data.username === 'string' ? data.username.trim() : '';
  const username = normalizeUsernameToken(usernameRaw || normalized);
  if (!name) return null;
  return {
    name,
    username,
    avatar:
      (typeof data.avatarThumb === 'string' && data.avatarThumb.trim()) ||
      (typeof data.avatar === 'string' && data.avatar.trim()) ||
      null,
  };
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ contactUserId: string }>;
}): Promise<Metadata> {
  const { contactUserId } = await params;
  const profile = await resolvePublicContactPreview(contactUserId).catch(() => null);
  const title = profile
    ? `${profile.name} (@${profile.username || 'user'}) · LighChat`
    : 'Contact profile · LighChat';
  const description = profile
    ? `Open ${profile.name}'s LighChat profile and start chatting in one tap.`
    : 'Open a LighChat profile and start chatting in one tap.';
  const image = profile?.avatar ?? 'https://lighchat.online/brand/lighchat-mark-app-icon.png';
  const canonical = `https://lighchat.online/dashboard/contacts/${encodeURIComponent(contactUserId)}`;

  return {
    title,
    description,
    robots: { index: false, follow: true },
    alternates: { canonical },
    openGraph: {
      type: 'website',
      title,
      description,
      url: canonical,
      siteName: 'LighChat',
      images: [{ url: image }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [image],
    },
  };
}

export default async function ContactProfilePage({
  params,
}: {
  params: Promise<{ contactUserId: string }>;
}) {
  const { contactUserId } = await params;
  return <ContactProfileClient contactUserId={contactUserId} />;
}
