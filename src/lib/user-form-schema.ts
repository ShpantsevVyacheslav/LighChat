/**
 * Zod schema for admin / profile user form with injectable validation messages (i18n).
 */

import * as z from "zod";
import type { UserRole } from "@/lib/types";
import { ROLES } from "@/lib/constants";
import { isNormalizedUsernameTokenAllowed, normalizeUsernameCandidate } from "@/lib/username-candidate";

/** ДД.ММ.ГГГГ → yyyy-MM-dd (same rules as profile form). */
export function profileDisplayDateToIso(display: string | undefined): string | undefined {
  if (!display?.trim()) return undefined;
  const raw = display.trim();
  const m = raw.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
  if (!m) return undefined;
  const y = Number(m[3]);
  const mo = Number(m[2]);
  const d = Number(m[1]);
  const dt = new Date(Date.UTC(y, mo - 1, d, 12));
  if (Number.isNaN(dt.getTime())) return undefined;
  const year = dt.getUTCFullYear();
  const currentYear = new Date().getFullYear();
  if (year < 1920 || year > currentYear) return undefined;
  return `${m[3]}-${m[2]}-${m[1]}`;
}

export type UserFormValidationMessages = {
  nameMin: string;
  usernameMax: string;
  emailInvalid: string;
  bioMax: string;
  roleRequired: string;
  avatarUrlInvalid: string;
  avatarThumbUrlInvalid: string;
  passwordMinCreate: string;
  passwordMinEdit: string;
  passwordsMismatch: string;
  usernameRules: string;
  phoneFull: string;
  dateOfBirthInvalid: string;
};

export type UserFormSchemaContext = {
  isEditing: boolean;
  isProfilePage: boolean;
};

export function createUserFormSchema(m: UserFormValidationMessages, ctx: UserFormSchemaContext) {
  const base = z.object({
    name: z.string().min(2, { message: m.nameMin }),
    username: z.string().max(30, { message: m.usernameMax }),
    email: z.string().email({ message: m.emailInvalid }),
    phone: z.string().optional(),
    dateOfBirth: z.string().optional(),
    bio: z.string().max(200, { message: m.bioMax }).optional(),
    password: z.string().optional(),
    confirmPassword: z.string().optional(),
    role: z.enum(Object.keys(ROLES) as [UserRole, ...UserRole[]], { required_error: m.roleRequired }),
    avatar: z.string().url({ message: m.avatarUrlInvalid }).optional().or(z.literal("")),
    avatarThumb: z.string().url({ message: m.avatarThumbUrlInvalid }).optional().or(z.literal("")),
  });

  return base.superRefine((data, zctx) => {
    if (!ctx.isEditing && (!data.password || data.password.length < 6)) {
      zctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: m.passwordMinCreate,
        path: ["password"],
      });
    }
    if (ctx.isEditing && data.password && data.password.length > 0 && data.password.length < 6) {
      zctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: m.passwordMinEdit,
        path: ["password"],
      });
    }
    if (ctx.isProfilePage && data.password && data.password.length >= 6) {
      if ((data.confirmPassword ?? "") !== data.password) {
        zctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: m.passwordsMismatch,
          path: ["confirmPassword"],
        });
      }
    }

    const normU = normalizeUsernameCandidate(data.username ?? "");
    if (normU.length > 0) {
      if (!isNormalizedUsernameTokenAllowed(normU)) {
        zctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: m.usernameRules,
          path: ["username"],
        });
      }
    }

    if (ctx.isProfilePage) {
      const digits = (data.phone ?? "").replace(/\D/g, "");
      if (digits.length > 0 && digits.length !== 11) {
        zctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: m.phoneFull,
          path: ["phone"],
        });
      }
      if (data.dateOfBirth?.trim()) {
        if (!profileDisplayDateToIso(data.dateOfBirth)) {
          zctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: m.dateOfBirthInvalid,
            path: ["dateOfBirth"],
          });
        }
      }
    }
  });
}

export type UserFormValues = z.infer<ReturnType<typeof createUserFormSchema>>;
