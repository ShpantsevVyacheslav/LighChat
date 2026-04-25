import type { ActionCodeSettings, User as FirebaseUser } from "firebase/auth";
import { verifyBeforeUpdateEmail } from "firebase/auth";

export type RequestEmailChangeResult =
  | { ok: true }
  | { ok: false; code?: string; message: string };

function isFirebaseVerifyNewEmailBeforeChangeError(error: unknown): boolean {
  const code = (error as { code?: string })?.code;
  const message = String((error as { message?: string })?.message ?? "")
    .toLowerCase()
    .trim();
  return (
    code === "auth/operation-not-allowed" &&
    (message.includes("verify") || message.includes("подтверд"))
  );
}

/**
 * Запросить смену email через обязательную верификацию нового адреса.
 * В Firebase Auth это корректный путь: `updateEmail()` часто отклоняется политикой
 * «verify new email before change».
 */
export async function requestVerifiedEmailChange(opts: {
  firebaseUser: FirebaseUser;
  newEmail: string;
  actionCodeSettings: ActionCodeSettings;
}): Promise<RequestEmailChangeResult> {
  const { firebaseUser, newEmail, actionCodeSettings } = opts;
  const emailTrim = newEmail.trim();
  if (!emailTrim) return { ok: false, message: "Email не задан." };

  try {
    await verifyBeforeUpdateEmail(firebaseUser, emailTrim, actionCodeSettings);
    return { ok: true };
  } catch (e: unknown) {
    const code = (e as { code?: string })?.code;
    if (isFirebaseVerifyNewEmailBeforeChangeError(e)) {
      // Если политика включена, этот путь и должен работать; возвращаем как обычную ошибку.
      return { ok: false, code, message: "Смена email запрещена политикой Firebase Auth." };
    }
    return {
      ok: false,
      code,
      message: String((e as { message?: string })?.message ?? "Не удалось отправить письмо подтверждения email."),
    };
  }
}

