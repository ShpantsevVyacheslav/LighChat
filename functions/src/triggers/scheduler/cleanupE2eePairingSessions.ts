import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Phase 6: scheduled-clean up of expired E2EE v2 QR-pairing sessions.
 *
 * Коллекция `users/{uid}/e2eePairingSessions/{sessionId}` хранит
 * эфемерные документы с TTL 10 минут (см.
 * `docs/arcitecture/07-e2ee-v2-protocol.md` §5.3). Клиент нормально
 * удаляет их при ручном completion/reject, но мусор остаётся при crash'е,
 * потере сети или если пользователь просто закрыл экран.
 *
 * Раз в 5 минут (частота выбрана компромиссно: быстрее чистим → меньше
 * истекших документов при каждой сессии; медленнее → меньше quota на
 * запросы collectionGroup) проходимся по всем `e2eePairingSessions`
 * через collectionGroup-запрос и удаляем те, у которых `expiresAt` уже в
 * прошлом.
 *
 * Ограничения:
 *  - batch на 200 документов максимум — достаточно для штатного потока
 *    (ожидаемо ≤10 активных сессий в минуту), переходит на следующий
 *    запуск, если остались;
 *  - ошибки по индивидуальным документам не ломают цикл (try/catch).
 */
export const cleanupE2eePairingSessions = onSchedule({
  schedule: "every 5 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const nowIso = new Date().toISOString();
  try {
    const snap = await db
      .collectionGroup("e2eePairingSessions")
      .where("expiresAt", "<", nowIso)
      .limit(200)
      .get();

    if (snap.empty) {
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();

    logger.log(
      `[cleanupE2eePairingSessions] Deleted ${snap.size} expired pairing sessions.`
    );
  } catch (err) {
    logger.error("[cleanupE2eePairingSessions] Cleanup failed:", err);
  }
});
