/**
 * Registration profile schemas: email+password flow and Google profile completion.
 * Messages are injected for i18n (same keys as mobile preference model on web).
 */

import * as z from "zod";

import { isNormalizedUsernameTokenAllowed } from "@/lib/username-candidate";

export type RegisterProfileValidationMessages = {
  usernameMin: string;
  usernameMax: string;
  usernameRegex: string;
  usernameRefine: string;
  phoneFull: string;
  dateOfBirthInvalid: string;
  nameMin: string;
  emailInvalid: string;
  bioMax: string;
  passwordMin: string;
  passwordsMismatch: string;
};

export function createGoogleProfileFormSchema(m: RegisterProfileValidationMessages) {
  const usernameSchema = z
    .string()
    .trim()
    .min(3, { message: m.usernameMin })
    .max(30, { message: m.usernameMax })
    .regex(/^@?[a-zA-Z0-9_.]+$/, { message: m.usernameRegex })
    .refine((s) => isNormalizedUsernameTokenAllowed(s.replace(/^@/, "")), {
      message: m.usernameRefine,
    });

  const phoneSchema = z.string().refine((val) => val.replace(/\D/g, "").length === 11, {
    message: m.phoneFull,
  });

  const dateOfBirthSchema = z
    .string()
    .optional()
    .refine((val) => {
      if (!val) return true;
      const year = new Date(val).getFullYear();
      const currentYear = new Date().getFullYear();
      return year >= 1920 && year <= currentYear;
    }, { message: m.dateOfBirthInvalid });

  return z.object({
    name: z.string().trim().min(2, { message: m.nameMin }),
    username: usernameSchema,
    phone: phoneSchema,
    email: z.string().email({ message: m.emailInvalid }),
    dateOfBirth: dateOfBirthSchema,
    bio: z.string().max(200, { message: m.bioMax }).optional(),
  });
}

export function createEmailPasswordRegistrationSchema(m: RegisterProfileValidationMessages) {
  return createGoogleProfileFormSchema(m)
    .extend({
      password: z.string().min(6, { message: m.passwordMin }),
      confirmPassword: z.string(),
    })
    .refine((data) => data.password === data.confirmPassword, {
      message: m.passwordsMismatch,
      path: ["confirmPassword"],
    });
}

export type GoogleProfileFormValues = z.infer<ReturnType<typeof createGoogleProfileFormSchema>>;
export type EmailPasswordRegistrationValues = z.infer<ReturnType<typeof createEmailPasswordRegistrationSchema>>;
