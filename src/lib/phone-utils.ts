/**
 * Нормализация телефона для сравнения и варианты строк для поиска в Firestore
 * (в БД номер может храниться как +7900…, 7900…, 8900…).
 */

export function normalizePhoneDigits(input: string): string {
  let d = input.replace(/\D/g, "");
  if (d.startsWith("8") && d.length === 11) d = "7" + d.slice(1);
  if (d.length === 10) d = "7" + d;
  return d;
}

/** Типичные строки в `users.phone` при регистрации / маске ввода. */
function ruPhoneFormattedVariants(tail10: string): string[] {
  if (tail10.length !== 10) return [];
  const a = tail10.slice(0, 3);
  const b = tail10.slice(3, 6);
  const c = tail10.slice(6, 8);
  const e = tail10.slice(8, 10);
  return [
    `+7 (${a}) ${b}-${c}-${e}`,
    `+7(${a})${b}-${c}-${e}`,
    `+7 ${a} ${b}-${c}-${e}`,
    `8 (${a}) ${b}-${c}-${e}`,
    `8(${a})${b}-${c}-${e}`,
    `+8 (${a}) ${b}-${c}-${e}`,
  ];
}

/** Уникальные варианты поля `users.phone` для последовательных запросов (точное совпадение в Firestore). */
export function phoneLookupVariants(input: string): string[] {
  const d = normalizePhoneDigits(input);
  if (d.length < 10) return [];
  const tail10 = d.length >= 11 ? d.slice(-10) : d;
  if (tail10.length !== 10) return [];
  const ru = "7" + tail10;
  const raw = new Set<string>();
  raw.add("+" + ru);
  raw.add(ru);
  raw.add("8" + tail10);
  raw.add("+8" + tail10);
  raw.add(tail10);
  for (const v of ruPhoneFormattedVariants(tail10)) raw.add(v);
  try {
    raw.add(applyPhoneMask("+" + ru));
  } catch {
    /* ignore */
  }
  return [...raw];
}

/** Маска ввода (как в `PhoneInput`) — для админ-форм. */
export function applyPhoneMask(value: string): string {
  const digits = value.replace(/\D/g, "");
  const d = digits.startsWith("8")
    ? "7" + digits.slice(1)
    : digits.startsWith("7")
      ? digits
      : "7" + digits;

  let result = "+7";
  if (d.length > 1) result += "(" + d.slice(1, 4);
  if (d.length >= 4) result += ")";
  if (d.length > 4) result += d.slice(4, 7);
  if (d.length > 7) result += "-" + d.slice(7, 9);
  if (d.length > 9) result += "-" + d.slice(9, 11);

  return result;
}

/**
 * Нормализует значение из Firestore/регистрации к виду для `PhoneInput` / полей с маской:
 * всегда `+` и до 11 цифр, чтобы `PhoneInput` корректно показал маску.
 */
export function phoneFormValueFromStored(raw: string | undefined): string {
  if (!raw?.trim()) return "";
  const d = normalizePhoneDigits(raw);
  if (d.length < 10) return raw.trim();
  return `+${d.slice(0, 11)}`;
}

/** Значение телефона для форм / API: «+» и до 11 цифр (как из `PhoneInput`). */
export function phoneStorageFromFormatted(formatted: string): string {
  const d = formatted.replace(/\D/g, "").slice(0, 11);
  if (!d) return "";
  return `+${d}`;
}

/** Отображение номера в таблицах. */
export function formatPhoneNumberForDisplay(phone: string): string {
  if (!phone?.trim()) return "—";
  return applyPhoneMask(phone);
}
