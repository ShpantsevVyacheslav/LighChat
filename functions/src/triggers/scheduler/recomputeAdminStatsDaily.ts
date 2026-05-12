import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

import { recomputeAdminStats } from "../http/adminRecomputeStats";

/**
 * Ежедневный пересчёт `admin/stats` для AdminOverviewScreen.
 * Расписание: `0 3 * * *` UTC (03:00 UTC = 06:00 MSK). Лёгкий часовой
 * слот без нагрузки на серверы.
 */
export const recomputeAdminStatsDaily = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "UTC",
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    try {
      const result = await recomputeAdminStats();
      logger.log("[admin-stats-daily] success", result);
    } catch (e) {
      logger.error("[admin-stats-daily] failed", e);
      // не rethrow — scheduler сам ретраит по политике, но эта таска
      // best-effort: лучше пропустить день, чем спамить retry'ями.
    }
  },
);
