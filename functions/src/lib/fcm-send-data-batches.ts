import type { Messaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import { stableDataKey } from "./push-notification-policy";

const FCM_MULTICAST_LIMIT = 500;

export function groupPayloadsByData(
  items: Array<{ tokens: string[]; data: Record<string, string> }>
): Map<string, { data: Record<string, string>; tokens: string[] }> {
  const map = new Map<string, { data: Record<string, string>; tokens: string[] }>();
  for (const item of items) {
    const key = stableDataKey(item.data);
    const cur = map.get(key);
    if (!cur) {
      map.set(key, { data: { ...item.data }, tokens: [...item.tokens] });
    } else {
      cur.tokens.push(...item.tokens);
    }
  }
  return map;
}

export async function sendDataMulticastGrouped(
  messaging: Messaging,
  items: Array<{ tokens: string[]; data: Record<string, string> }>
): Promise<void> {
  const grouped = groupPayloadsByData(items);
  for (const { data, tokens } of grouped.values()) {
    const unique = [...new Set(tokens.filter((t) => typeof t === "string" && t.length > 0))];
    for (let i = 0; i < unique.length; i += FCM_MULTICAST_LIMIT) {
      const chunk = unique.slice(i, i + FCM_MULTICAST_LIMIT);
      try {
        const res = await messaging.sendEachForMulticast({ data, tokens: chunk });
        if (res.failureCount > 0) {
          logger.warn("FCM partial failure", { failureCount: res.failureCount, batchSize: chunk.length });
        }
      } catch (e) {
        logger.error("FCM sendEachForMulticast error", e);
      }
    }
  }
}
