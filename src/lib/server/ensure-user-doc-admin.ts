import { adminDb } from "@/firebase/admin";

const DICEBEAR_AVATAR_HOST = "api.dicebear.com";

function isDicebearPlaceholderAvatar(avatar: string | undefined): boolean {
  const u = String(avatar ?? "").trim().toLowerCase();
  if (!u) return true;
  try {
    return new URL(u).hostname === DICEBEAR_AVATAR_HOST;
  } catch {
    return false;
  }
}

export async function ensureUserDocExistsAdmin(opts: {
  uid: string;
  displayName: string;
  email?: string | undefined;
  avatarUrl?: string | undefined;
  dateOfBirth?: string | null | undefined;
}): Promise<void> {
  const { uid, displayName, email, avatarUrl, dateOfBirth } = opts;
  if (!uid) return;

  const ref = adminDb.doc(`users/${uid}`);
  const now = new Date().toISOString();

  try {
    await adminDb.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return;

      const avatar =
        avatarUrl && avatarUrl.trim().length > 0
          ? avatarUrl.trim().slice(0, 2048)
          : `https://api.dicebear.com/7.x/avataaars/svg?seed=${uid}`;

      tx.set(ref, {
        id: uid,
        name: displayName || "Новый пользователь",
        username: "",
        phone: "",
        email: (email ?? "").trim().toLowerCase(),
        avatar,
        role: "worker",
        bio: "",
        dateOfBirth: dateOfBirth ?? null,
        createdAt: now,
        deletedAt: null,
        online: true,
        lastSeen: now,
      });
    });
  } catch (e) {
    console.warn("[ensure-user-doc-admin] ensure users/%s failed", uid, e);
    return;
  }

  // For the case where the doc existed: optionally patch missing basics.
  try {
    const snap = await ref.get();
    if (!snap.exists) return;
    const data = snap.data() ?? {};
    if ((data as any).deletedAt) return;

    const patch: Record<string, unknown> = {};
    const nameNow = String((data as any).name ?? "").trim();
    if (!nameNow || nameNow === "Новый пользователь" || nameNow === "Yandex") {
      patch.name = displayName || "Новый пользователь";
    }

    const emailNow = String((data as any).email ?? "").trim().toLowerCase();
    const nextEmail = String(email ?? "").trim().toLowerCase();
    if (!emailNow && nextEmail) patch.email = nextEmail;

    const avatarNow = String((data as any).avatar ?? "").trim();
    const nextAvatar = String(avatarUrl ?? "").trim();
    if (nextAvatar && (isDicebearPlaceholderAvatar(avatarNow) || !avatarNow)) {
      patch.avatar = nextAvatar.slice(0, 2048);
    }

    const dobNow = (data as any).dateOfBirth;
    const nextDob = dateOfBirth ?? null;
    if ((dobNow == null || String(dobNow).trim() === "") && nextDob) {
      patch.dateOfBirth = nextDob;
    }

    if (Object.keys(patch).length > 0) {
      await ref.set(patch, { merge: true });
    }
  } catch (e) {
    console.warn("[ensure-user-doc-admin] users/%s patch skipped", uid, e);
  }
}

