import { describe, expect, it } from "vitest";
import * as admin from "firebase-admin";
import { trySetMessageExpireAtForDisappearing } from "./disappearing-chat-messages";

function fakeMessageRef() {
  const updates: Array<Record<string, unknown>> = [];
  return {
    updates,
    ref: {
      update: async (data: Record<string, unknown>) => {
        updates.push(data);
      },
    } as unknown as admin.firestore.DocumentReference,
  };
}

describe("trySetMessageExpireAtForDisappearing", () => {
  it("sets expireAt from message createdAt plus conversation ttl", async () => {
    const fake = fakeMessageRef();
    await trySetMessageExpireAtForDisappearing({
      db: {} as admin.firestore.Firestore,
      messageRef: fake.ref,
      conversationId: "c1",
      messageId: "m1",
      conversationData: { disappearingMessageTtlSec: 60 },
      messageData: {
        senderId: "u1",
        createdAt: "2026-01-01T00:00:00.000Z",
      },
    });

    expect(fake.updates).toHaveLength(1);
    const expireAt = fake.updates[0].expireAt as admin.firestore.Timestamp;
    expect(expireAt.toMillis()).toBe(Date.parse("2026-01-01T00:01:00.000Z"));
  });

  it("does not set expireAt for system messages", async () => {
    const fake = fakeMessageRef();
    await trySetMessageExpireAtForDisappearing({
      db: {} as admin.firestore.Firestore,
      messageRef: fake.ref,
      conversationId: "c1",
      messageId: "m1",
      conversationData: { disappearingMessageTtlSec: 60 },
      messageData: {
        senderId: "__system__",
        createdAt: "2026-01-01T00:00:00.000Z",
      },
    });

    expect(fake.updates).toHaveLength(0);
  });
});
