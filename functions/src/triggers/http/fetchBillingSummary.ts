import {
  onCall,
  HttpsError,
  type CallableRequest,
} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { BigQuery } from "@google-cloud/bigquery";

import { assertCallerIsAdmin } from "../../lib/admin-claims";

/**
 * Читает суммы из **Cloud Billing Export → BigQuery**.
 *
 * Запуск требует ручной настройки в GCP Console:
 *   1. Cloud Billing → Billing export → BigQuery export.
 *   2. SA Cloud Functions (`*@appspot.gserviceaccount.com` или
 *      Workload Identity) должен иметь `roles/bigquery.dataViewer`
 *      на target-dataset и `roles/bigquery.jobUser` на project.
 *   3. Конфиг (projectId/dataset/tableId) пишется админом в
 *      `platformSettings/main.billing` через UI.
 *
 * Cloud Billing REST API мы НЕ вызываем — он бьёт по квотам и не даёт
 * SKU-разбивки в одной таблице. BigQuery-экспорт — стандартный путь
 * Google для отчётов о биллинге.
 *
 * Возможные коды ошибок `error`:
 *  - `not_configured` — `platformSettings/main.billing` отсутствует.
 *  - `bad_request` — bad input.
 *  - `query_failed` — BigQuery вернул ошибку (см. логи).
 */

type BillingConfig = {
  projectId: string;
  dataset: string;
  tableId: string;
};

type BillingItem = {
  service: string;
  cost: number;
  currency: string;
};

export type FetchBillingSummaryResult =
  | {
      ok: true;
      items: BillingItem[];
      total: { cost: number; currency: string };
      periodFrom: string;
      periodTo: string;
      tableFullyQualified: string;
    }
  | { ok: false; error: string; details?: string };

const db = admin.firestore();

function isIsoDate(s: unknown): s is string {
  return typeof s === "string" && !Number.isNaN(Date.parse(s));
}

function isIdent(s: string): boolean {
  return /^[A-Za-z][A-Za-z0-9_-]*$/.test(s);
}

async function loadBillingConfig(): Promise<BillingConfig | null> {
  const snap = await db.collection("platformSettings").doc("main").get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};
  const billing = (data.billing ?? {}) as Partial<BillingConfig>;
  if (
    typeof billing.projectId !== "string" ||
    typeof billing.dataset !== "string" ||
    typeof billing.tableId !== "string"
  ) {
    return null;
  }
  if (
    !isIdent(billing.projectId) ||
    !isIdent(billing.dataset) ||
    !isIdent(billing.tableId)
  ) {
    // SECURITY: значения идут в SQL как backticked identifiers; режем
    // что-либо за пределами `[A-Za-z][A-Za-z0-9_-]*` чтобы исключить
    // SQL-injection через имя таблицы.
    return null;
  }
  return {
    projectId: billing.projectId,
    dataset: billing.dataset,
    tableId: billing.tableId,
  };
}

export const fetchBillingSummary = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (
    request: CallableRequest<{ from?: string; to?: string }>,
  ): Promise<FetchBillingSummaryResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }
    await assertCallerIsAdmin(request.auth.token, db);

    const fromIso = request.data?.from;
    const toIso = request.data?.to;
    if (!isIsoDate(fromIso) || !isIsoDate(toIso)) {
      return { ok: false, error: "bad_request", details: "from/to must be ISO dates" };
    }

    const cfg = await loadBillingConfig();
    if (!cfg) {
      return { ok: false, error: "not_configured" };
    }

    const tableFq = `\`${cfg.projectId}.${cfg.dataset}.${cfg.tableId}\``;
    const sql = `
      SELECT
        service.description AS service,
        SUM(cost) AS cost,
        currency
      FROM ${tableFq}
      WHERE usage_start_time >= @from
        AND usage_start_time < @to
      GROUP BY service, currency
      ORDER BY cost DESC
    `;

    const bq = new BigQuery({ projectId: cfg.projectId });
    try {
      const [rows] = await bq.query({
        query: sql,
        params: { from: fromIso, to: toIso },
        types: { from: "TIMESTAMP", to: "TIMESTAMP" },
      });

      const items: BillingItem[] = rows.map((r: Record<string, unknown>) => ({
        service: typeof r.service === "string" ? r.service : "unknown",
        cost: Number(r.cost) || 0,
        currency: typeof r.currency === "string" ? r.currency : "USD",
      }));

      const totalCurrency = items[0]?.currency ?? "USD";
      const total = {
        cost: items.reduce((s, i) => s + i.cost, 0),
        currency: totalCurrency,
      };

      return {
        ok: true,
        items,
        total,
        periodFrom: fromIso,
        periodTo: toIso,
        tableFullyQualified: `${cfg.projectId}.${cfg.dataset}.${cfg.tableId}`,
      };
    } catch (e) {
      logger.error("[fetchBillingSummary] BigQuery query failed", {
        error: String(e),
        projectId: cfg.projectId,
        dataset: cfg.dataset,
        tableId: cfg.tableId,
      });
      return { ok: false, error: "query_failed", details: String(e) };
    }
  },
);
