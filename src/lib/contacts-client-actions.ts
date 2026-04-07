import type { Firestore } from "firebase/firestore";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  setDoc,
  updateDoc,
  where,
  arrayUnion,
  arrayRemove,
} from "firebase/firestore";
import type { User } from "@/lib/types";
import { phoneLookupVariants } from "@/lib/phone-utils";

export async function findUserByPhoneInFirestore(
  firestore: Firestore,
  rawPhone: string
): Promise<User | null> {
  const variants = phoneLookupVariants(rawPhone);
  if (variants.length === 0) return null;
  const usersRef = collection(firestore, "users");
  for (const phone of variants) {
    const q = query(usersRef, where("phone", "==", phone), limit(1));
    const snap = await getDocs(q);
    if (!snap.empty) {
      const d = snap.docs[0];
      return { id: d.id, ...d.data() } as User;
    }
  }
  return null;
}

export async function addContactId(
  firestore: Firestore,
  ownerId: string,
  contactUserId: string
): Promise<void> {
  const ref = doc(firestore, "userContacts", ownerId);
  await setDoc(
    ref,
    {
      contactIds: arrayUnion(contactUserId),
    },
    { merge: true }
  );
}

export async function removeContactId(
  firestore: Firestore,
  ownerId: string,
  contactUserId: string
): Promise<void> {
  const ref = doc(firestore, "userContacts", ownerId);
  const snap = await getDoc(ref);
  if (!snap.exists) return;
  await updateDoc(ref, {
    contactIds: arrayRemove(contactUserId),
  });
}

export async function saveDeviceContactsConsent(
  firestore: Firestore,
  ownerId: string,
  granted: boolean
): Promise<void> {
  const ref = doc(firestore, "userContacts", ownerId);
  await setDoc(
    ref,
    {
      deviceSyncConsentAt: granted ? new Date().toISOString() : null,
    },
    { merge: true }
  );
}

/** «Не сейчас» в диалоге импорта контактов (PWA) — больше не показывать предложение автоматически. */
export async function dismissPhoneBookOffer(
  firestore: Firestore,
  ownerId: string
): Promise<void> {
  const ref = doc(firestore, "userContacts", ownerId);
  await setDoc(
    ref,
    {
      phoneBookOfferDismissedAt: new Date().toISOString(),
    },
    { merge: true }
  );
}
