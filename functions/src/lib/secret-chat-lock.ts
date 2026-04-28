import { randomBytes, pbkdf2Sync, timingSafeEqual } from "crypto";

const PIN_SALT_BYTES = 16;
const PIN_HASH_BYTES = 32;
const PIN_PBKDF2_ITERATIONS = 600_000;

export function isValidFourDigitPin(pin: string): boolean {
  return /^\d{4}$/.test(pin);
}

export function newPinSaltB64(): string {
  return randomBytes(PIN_SALT_BYTES).toString("base64");
}

export function derivePinHashB64(pin: string, saltB64: string): string {
  const salt = Buffer.from(saltB64, "base64");
  const out = pbkdf2Sync(pin, salt, PIN_PBKDF2_ITERATIONS, PIN_HASH_BYTES, "sha256");
  return out.toString("base64");
}

export function constantTimeEqualsB64(aB64: string, bB64: string): boolean {
  const a = Buffer.from(aB64, "base64");
  const b = Buffer.from(bB64, "base64");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

