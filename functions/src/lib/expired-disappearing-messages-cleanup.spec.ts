import { describe, expect, it } from "vitest";
import {
  isConversationMessageDocPath,
  isConversationThreadMessageDocPath,
} from "./expired-disappearing-messages-cleanup";

describe("expired disappearing messages cleanup path guards", () => {
  it("matches only top-level conversation messages", () => {
    expect(isConversationMessageDocPath("conversations/c1/messages/m1")).toBe(true);
    expect(isConversationMessageDocPath("meetings/m1/messages/x")).toBe(false);
    expect(isConversationMessageDocPath("conversations/c1/messages/m1/thread/t1")).toBe(false);
  });

  it("matches only conversation thread messages", () => {
    expect(isConversationThreadMessageDocPath("conversations/c1/messages/m1/thread/t1")).toBe(true);
    expect(isConversationThreadMessageDocPath("conversations/c1/messages/m1")).toBe(false);
    expect(isConversationThreadMessageDocPath("meetings/m1/messages/x/thread/t1")).toBe(false);
  });
});
