/**
 * Редактирование маски +7(XXX)XX-XX-XX: Backspace/Delete удаляют цифру, даже если каретка на «)», «-» и т.д.
 */

import { applyPhoneMask } from "@/lib/phone-utils";

function buildDigitCountBefore(formatted: string): number[] {
  const arr = new Array(formatted.length + 1).fill(0);
  let c = 0;
  for (let i = 0; i < formatted.length; i++) {
    arr[i] = c;
    if (/\d/.test(formatted[i])) c++;
  }
  arr[formatted.length] = c;
  return arr;
}

/** Каретка сразу после n-й цифры (n — сколько цифр должно быть слева от каретки). */
function caretAfterNDigits(formatted: string, n: number): number {
  if (n <= 0) {
    if (formatted.startsWith("+7(")) return 3;
    if (formatted.startsWith("+7")) return Math.min(2, formatted.length);
    return 0;
  }
  let seen = 0;
  for (let i = 0; i < formatted.length; i++) {
    if (/\d/.test(formatted[i])) {
      seen++;
      if (seen === n) return i + 1;
    }
  }
  return formatted.length;
}

function digitsOnlyMax11(s: string): string {
  return s.replace(/\D/g, "").slice(0, 11);
}

function rebuildDisplayFromDigits(digits: string): string {
  const d = digits.replace(/\D/g, "").slice(0, 11);
  if (d.length === 0) return "";
  if (d === "7") return "+7(";
  return applyPhoneMask(`+${d}`);
}

/**
 * @returns новое отображение и позиция каретки, или null — пусть сработает ввод по умолчанию.
 */
export function tryApplyRuPhoneMaskKeyEdit(
  key: string,
  formatted: string,
  selStart: number,
  selEnd: number
): { display: string; caret: number } | null {
  if (key !== "Backspace" && key !== "Delete") return null;

  const before = buildDigitCountBefore(formatted);
  const d = digitsOnlyMax11(formatted);

  if (key === "Backspace") {
    if (selStart !== selEnd) {
      const low = before[selStart];
      const high = before[selEnd];
      const next = d.slice(0, low) + d.slice(high);
      const display = rebuildDisplayFromDigits(next);
      const caret = caretAfterNDigits(display, low);
      return { display, caret };
    }
    if (selStart <= 0) return null;
    const k = before[selStart];
    if (k <= 0) return null;
    const removeIdx = k - 1;
    const next = d.slice(0, removeIdx) + d.slice(removeIdx + 1);
    const display = rebuildDisplayFromDigits(next);
    const caret = caretAfterNDigits(display, removeIdx);
    return { display, caret };
  }

  /* Delete */
  if (selStart !== selEnd) {
    const low = before[selStart];
    const high = before[selEnd];
    const next = d.slice(0, low) + d.slice(high);
    const display = rebuildDisplayFromDigits(next);
    const caret = caretAfterNDigits(display, low);
    return { display, caret };
  }
  let removeIdx = -1;
  for (let i = selStart; i < formatted.length; i++) {
    if (/\d/.test(formatted[i])) {
      removeIdx = before[i];
      break;
    }
  }
  if (removeIdx < 0) return null;
  const next = d.slice(0, removeIdx) + d.slice(removeIdx + 1);
  const display = rebuildDisplayFromDigits(next);
  const caret = caretAfterNDigits(display, removeIdx);
  return { display, caret };
}
