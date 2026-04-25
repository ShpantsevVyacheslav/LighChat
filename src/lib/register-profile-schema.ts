/**
 * Схемы полей регистрации: полный поток (email+пароль) и дополнение профиля после Google.
 */

import * as z from "zod";

import { isNormalizedUsernameTokenAllowed } from "@/lib/username-candidate";

const usernameSchema = z
  .string()
  .trim()
  .min(3, { message: "Логин должен содержать не менее 3 символов." })
  .max(30, { message: "Логин не должен превышать 30 символов." })
  .regex(/^@?[a-zA-Z0-9_.]+$/, { message: "Только латиница, цифры, _ и ." })
  .refine(
    (s) => isNormalizedUsernameTokenAllowed(s.replace(/^@/, "")),
    { message: "Некорректный логин (точка не в начале/конце, без ..)." },
  );

const phoneSchema = z
  .string()
  .refine((val) => val.replace(/\D/g, "").length === 11, {
    message: "Введите полный номер телефона.",
  });

const dateOfBirthSchema = z
  .string()
  .optional()
  .refine((val) => {
    if (!val) return true;
    const year = new Date(val).getFullYear();
    const currentYear = new Date().getFullYear();
    return year >= 1920 && year <= currentYear;
  }, { message: "Некорректная дата рождения." });

/** Общие поля (email + регистрация / Google). Имя обязательно, мин. 2 символа после trim. */
export const googleProfileFormSchema = z.object({
  name: z
    .string()
    .trim()
    .min(2, { message: "Укажите имя (не менее 2 символов)." }),
  username: usernameSchema,
  phone: phoneSchema,
  email: z.string().email({ message: "Неверный формат email." }),
  dateOfBirth: dateOfBirthSchema,
  bio: z.string().max(200, { message: "Не более 200 символов." }).optional(),
});

/** Регистрация по email и паролю. */
export const emailPasswordRegistrationSchema = googleProfileFormSchema
  .extend({
    password: z
      .string()
      .min(6, { message: "Пароль должен содержать не менее 6 символов." }),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Пароли не совпадают.",
    path: ["confirmPassword"],
  });
