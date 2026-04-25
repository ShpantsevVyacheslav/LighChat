import type { Firestore } from "firebase/firestore";
import {
  collection,
  deleteField,
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
import type { User, UserContactLocalProfile } from "@/lib/types";
import { buildContactDisplayName } from "@/lib/contact-display-name";
import { phoneLookupVariants } from "@/lib/phone-utils";
import { registrationPhoneKey } from "@/lib/registration-index-keys";

export async function findUserByPhoneInFirestore(
  firestore: Firestore,
  rawPhone: string
): Promise<User | null> {
  const regKey = registrationPhoneKey(rawPhone);
  if (regKey) {
    const idxSnap = await getDoc(doc(firestore, "registrationIndex", regKey));
    const uid = idxSnap.data()?.uid;
    if (typeof uid === "string" && uid.trim()) {
      const userSnap = await getDoc(doc(firestore, "users", uid.trim()));
      if (userSnap.exists()) {
        return { id: userSnap.id, ...userSnap.data() } as User;
      }
    }
  }

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
    [`contactProfiles.${contactUserId}`]: deleteField(),
  });
}

export async function upsertContactProfile(
  firestore: Firestore,
  ownerId: string,
  contactUserId: string,
  profile: Pick<UserContactLocalProfile, "firstName" | "lastName">
): Promise<void> {
  const owner = ownerId.trim();
  const contactId = contactUserId.trim();
  const firstName = (profile.firstName ?? "").trim();
  const lastName = (profile.lastName ?? "").trim();
  if (!owner || !contactId || !firstName) return;

  const displayName = buildContactDisplayName({ firstName, lastName });
  const ref = doc(firestore, "userContacts", owner);
  await setDoc(
    ref,
    {
      contactIds: arrayUnion(contactId),
    },
    { merge: true }
  );

  await updateDoc(ref, {
    [`contactProfiles.${contactId}.firstName`]: firstName,
    [`contactProfiles.${contactId}.lastName`]: lastName || deleteField(),
    [`contactProfiles.${contactId}.displayName`]: displayName,
    [`contactProfiles.${contactId}.updatedAt`]: new Date().toISOString(),
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
