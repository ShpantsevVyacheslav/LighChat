import { describe, expect, it } from "vitest";
import * as nodeCrypto from "node:crypto";
import { hashNonceForStorage } from "./requestQrLogin";

/**
 * `confirmQrLogin` сравнивает SHA-256(sessionId|nonce) с тем, что лежит
 * в Firestore — это и есть единственная проверка авторизации сканирующей
 * стороны до выпуска customToken. Логика хэширования должна быть:
 *  - детерминированной (одинаковый вход → одинаковый выход);
 *  - чувствительной к sessionId (ребайнд nonce от другой сессии не должен
 *    проходить);
 *  - совместимой с прямым вычислением SHA-256 на base64.
 */
describe("hashNonceForStorage", () => {
  it("returns a deterministic base64 SHA-256 hash", () => {
    const a = hashNonceForStorage("nonce-aaa", "session-1");
    const b = hashNonceForStorage("nonce-aaa", "session-1");
    expect(a).toBe(b);
    // Длина SHA-256 в base64 без паддинга = 44 символа (включая `=`).
    expect(a.length).toBe(44);
  });

  it("is sensitive to sessionId (replay defense)", () => {
    const a = hashNonceForStorage("nonce-x", "session-A");
    const b = hashNonceForStorage("nonce-x", "session-B");
    expect(a).not.toBe(b);
  });

  it("is sensitive to nonce (different secrets produce different hashes)", () => {
    const a = hashNonceForStorage("nonce-1", "session-X");
    const b = hashNonceForStorage("nonce-2", "session-X");
    expect(a).not.toBe(b);
  });

  it("matches a manual SHA-256 computation over `${sessionId}|${nonce}`", () => {
    const sessionId = "abc-123";
    const nonce = "xyz-456";
    const expected = nodeCrypto
      .createHash("sha256")
      .update(`${sessionId}|${nonce}`, "utf8")
      .digest("base64");
    expect(hashNonceForStorage(nonce, sessionId)).toBe(expected);
  });

  it("does not collide on swap of nonce and sessionId (separator matters)", () => {
    // hash("a|b") != hash("b|a") гарантирует, что подмена местами не даёт
    // тот же хэш — поведение, на котором держится уникальность пары.
    const ab = hashNonceForStorage("a", "b");
    const ba = hashNonceForStorage("b", "a");
    expect(ab).not.toBe(ba);
  });

  it("handles empty inputs without crashing (defence-in-depth)", () => {
    // Вход в callable отбрасывается до этого помощника, но сам он не
    // должен бросать на пустой строке — иначе любая регрессия наверху
    // приведёт к 500 вместо чистого 400.
    expect(() => hashNonceForStorage("", "")).not.toThrow();
    expect(typeof hashNonceForStorage("", "")).toBe("string");
  });
});
