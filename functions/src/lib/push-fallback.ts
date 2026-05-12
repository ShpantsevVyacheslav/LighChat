/**
 * Push fallback для Windows/Linux Flutter-десктопа.
 *
 * Эти платформы не имеют нативного `firebase_messaging` SDK, поэтому
 * клиент (`PushFallbackService` в mobile/app) слушает Firestore коллекцию
 * `users/{uid}/incomingNotifications` и эмиттит локальные уведомления.
 *
 * Эта функция дублирует FCM-payload в Firestore для каждого получателя,
 * у которого среди зарегистрированных устройств есть хотя бы одно
 * `desktop` (поле `users/{uid}.devicePlatforms` или
 * `users/{uid}/devices/{deviceId}.platform`). Вызывайте её _параллельно_
 * с обычным `messaging.sendEachForMulticast(...)` (не вместо).
 *
 * Документы автоматически собираются TTL-rule в `firestore.rules` через
 * 7 дней; клиент помечает доставленные как `delivered: true`.
 */

import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

export interface PushFallbackEntry {
  /** UID получателя. */
  uid: string;
  /** Заголовок уведомления (как FCM `notification.title` / `data.title`). */
  title: string;
  /** Тело уведомления. */
  body: string;
  /** Дополнительный data-payload (то же, что в FCM `data`). */
  data?: Record<string, string>;
}

/**
 * Пишет одну запись в `users/{uid}/incomingNotifications` для каждого
 * получателя из `entries`, у которого зарегистрировано хотя бы одно
 * desktop-устройство. Делается batch'ем (≤500 записей за коммит).
 */
export async function mirrorPushToFirestore(
  db: admin.firestore.Firestore,
  entries: PushFallbackEntry[],
): Promise<void> {
  if (entries.length === 0) return;

  // Фильтр: только пользователи с хотя бы одним desktop-устройством.
  // Поле `desktopDeviceCount` поддерживается триггером `onDeviceWrite`
  // (или вычисляется ad-hoc если триггера ещё нет).
  const eligible = await filterDesktopRecipients(db, entries);
  if (eligible.length === 0) return;

  let batch = db.batch();
  let inBatch = 0;
  const commits: Promise<unknown>[] = [];

  for (const entry of eligible) {
    const ref = db
      .collection("users")
      .doc(entry.uid)
      .collection("incomingNotifications")
      .doc();
    batch.set(ref, {
      title: entry.title,
      body: entry.body,
      data: entry.data ?? {},
      delivered: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // TTL helper: документы старше 7 дней удаляются Firestore TTL policy
      // на поле expireAt (см. firestore.rules / firebase.json).
      expireAt: admin.firestore.Timestamp.fromMillis(
        Date.now() + 7 * 24 * 60 * 60 * 1000,
      ),
    });
    inBatch += 1;
    if (inBatch >= 450) {
      commits.push(batch.commit());
      batch = db.batch();
      inBatch = 0;
    }
  }
  if (inBatch > 0) commits.push(batch.commit());

  try {
    await Promise.all(commits);
  } catch (e) {
    logger.error("[push-fallback] mirror failed", e);
  }
}

async function filterDesktopRecipients(
  db: admin.firestore.Firestore,
  entries: PushFallbackEntry[],
): Promise<PushFallbackEntry[]> {
  const uniqueUids = Array.from(new Set(entries.map((e) => e.uid)));
  // Чтение `users/{uid}.devicePlatforms` массивом — простая эвристика;
  // если поле отсутствует, считаем что десктопа нет.
  const refs = uniqueUids.map((uid) => db.collection("users").doc(uid));
  const snaps = await db.getAll(...refs);
  const desktopSet = new Set<string>();
  for (const snap of snaps) {
    const platforms = snap.get("devicePlatforms");
    if (!Array.isArray(platforms)) continue;
    const hasDesktop = platforms.some(
      (p) => typeof p === "string" && /^(windows|linux|macos|desktop)$/i.test(p),
    );
    if (hasDesktop) desktopSet.add(snap.id);
  }
  return entries.filter((e) => desktopSet.has(e.uid));
}
