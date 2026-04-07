import type { User } from "@/lib/types";

export type ProfileFieldKey = "email" | "phone" | "bio" | "dateOfBirth";

/**
 * Видимость полей профиля для других пользователей (клиентская фильтрация).
 * Если флаг в `privacySettings` не задан — считаем `true` (как раньше).
 */
export function isProfileFieldVisibleToOthers(subject: User | null | undefined, field: ProfileFieldKey): boolean {
  const p = subject?.privacySettings;
  if (!p) return true;
  switch (field) {
    case "email":
      return p.showEmailToOthers !== false;
    case "phone":
      return p.showPhoneToOthers !== false;
    case "bio":
      return p.showBioToOthers !== false;
    case "dateOfBirth":
      return p.showDateOfBirthToOthers !== false;
    default:
      return true;
  }
}
