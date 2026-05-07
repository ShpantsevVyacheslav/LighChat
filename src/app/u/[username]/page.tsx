import type { Metadata } from 'next';
import Link from 'next/link';

import { adminDb } from '@/firebase/admin';

type PublicContactPreview = {
  name: string;
  username: string;
  avatar: string | null;
};

function normalizeUsernameToken(raw: string): string {
  return raw.trim().replace(/^@/, '').toLowerCase();
}

async function resolveByUsername(usernameToken: string): Promise<PublicContactPreview | null> {
  const normalized = normalizeUsernameToken(usernameToken);
  if (!normalized) return null;

  const idxSnap = await adminDb.collection('registrationIndex').doc(`u_${normalized}`).get();
  const uid = typeof idxSnap.data()?.uid === 'string' ? idxSnap.data()?.uid.trim() : '';

  let userSnap = uid ? await adminDb.collection('users').doc(uid).get() : null;
  if (!userSnap || !userSnap.exists) {
    const fallback = await adminDb
      .collection('users')
      .where('username', '==', normalized)
      .limit(1)
      .get();
    if (!fallback.empty) userSnap = fallback.docs[0] ?? null;
  }
  if (!userSnap || !userSnap.exists) return null;

  const data = userSnap.data() ?? {};
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  const usernameRaw = typeof data.username === 'string' ? data.username.trim() : '';
  if (!name) return null;

  return {
    name,
    username: normalizeUsernameToken(usernameRaw || normalized),
    avatar:
      (typeof data.avatarThumb === 'string' && data.avatarThumb.trim()) ||
      (typeof data.avatar === 'string' && data.avatar.trim()) ||
      null,
  };
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ username: string }>;
}): Promise<Metadata> {
  const { username } = await params;
  const profile = await resolveByUsername(username).catch(() => null);
  const title = profile
    ? `${profile.name} (@${profile.username || 'user'}) · LighChat`
    : 'Contact profile · LighChat';
  const description = profile
    ? `Open ${profile.name}'s LighChat profile and start chatting in one tap.`
    : 'Open a LighChat profile and start chatting in one tap.';
  const image = profile?.avatar ?? 'https://lighchat.online/brand/lighchat-mark-app-icon.png';
  const canonical = `https://lighchat.online/u/${encodeURIComponent(username)}`;

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

export default async function PublicContactPage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;
  const profile = await resolveByUsername(username).catch(() => null);
  const normalized = normalizeUsernameToken(profile?.username || username);
  const dashboardLink = `/dashboard/contacts/${encodeURIComponent(normalized)}`;

  return (
    <main className="min-h-dvh bg-background px-6 py-12 text-foreground">
      <div className="mx-auto flex w-full max-w-xl flex-col items-center rounded-3xl border border-border/60 bg-background/70 p-8 text-center shadow-sm backdrop-blur-xl">
        {profile?.avatar ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profile.avatar}
            alt={profile.name}
            className="mb-4 h-20 w-20 rounded-full object-cover"
          />
        ) : null}
        <h1 className="text-2xl font-bold">
          {profile ? profile.name : 'LighChat Contact'}
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          @{profile?.username || normalized || 'user'}
        </p>
        <p className="mt-4 text-sm text-muted-foreground">
          Open this profile in LighChat to start chatting.
        </p>
        <Link
          href={dashboardLink}
          className="mt-6 inline-flex rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground"
        >
          Open in LighChat
        </Link>
      </div>
    </main>
  );
}
