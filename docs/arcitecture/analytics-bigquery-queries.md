# Аналитика поверх `analyticsEvents` в BigQuery

После установки Firebase Extension `firestore-bigquery-export@0.3.2` в проект `project-72b24` коллекция `analyticsEvents` зеркалируется в:

- **Table** `project-72b24.firestore_export.analytics_events_raw_changelog` — полная история (append-only), partitioned by DAY.
- **View** `project-72b24.firestore_export.analytics_events_raw_latest` — последнее состояние каждого документа.

## Схема исходной таблицы

Каждая строка в `*_changelog` имеет колонки:

| Колонка | Тип | Описание |
|---|---|---|
| `timestamp` | TIMESTAMP | Когда документ был записан/обновлён в Firestore |
| `event_id` | STRING | Уникальный id mirror-операции (не наш `analytics.event_name`) |
| `document_name` | STRING | Полный путь `projects/.../analyticsEvents/{auto_id}` |
| `document_id` | STRING | Auto-id Firestore документа |
| `operation` | STRING | `CREATE` / `UPDATE` / `DELETE` / `IMPORT` |
| `data` | JSON | **Весь** Firestore-документ как JSON-строка |

Полезная нагрузка лежит **внутри** `data` (JSON). Структура:

```json
{
  "event": "page_view",
  "params": { "screen_name": "/dashboard/chat/[id]", "platform": "web", ... },
  "platform": "web",
  "uid": "5edHRxyQKWZEk4M2iQ3lBjDKKdd2",
  "ts": "2026-05-16T12:34:56.789Z",
  "createdAt": "...",
  "source": "web_client"
}
```

Поля внутри `data` извлекаются через `JSON_VALUE(data, '$.field')` (скалары) или
`JSON_QUERY(data, '$.params')` (вложенные объекты).

---

## SQL-запросы для Looker Studio Custom Data Sources

### 1. Daily Active Users (DAU) — за 30 дней

```sql
SELECT
  DATE(timestamp) AS day,
  COUNT(DISTINCT JSON_VALUE(data, '$.uid')) AS dau
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND operation IN ('CREATE', 'IMPORT')
  AND JSON_VALUE(data, '$.uid') IS NOT NULL
GROUP BY day
ORDER BY day
```

В Looker — Time Series chart, X = `day`, Y = `dau`.

### 2. Top events за неделю

```sql
SELECT
  JSON_VALUE(data, '$.event') AS event,
  COUNT(*) AS occurrences,
  COUNT(DISTINCT JSON_VALUE(data, '$.uid')) AS unique_users
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND operation IN ('CREATE', 'IMPORT')
GROUP BY event
ORDER BY occurrences DESC
LIMIT 50
```

Table в Looker — Bar chart по `occurrences`.

### 3. Top pages (page_view) за неделю

```sql
SELECT
  JSON_VALUE(data, '$.params.screen_name') AS screen_name,
  COUNT(*) AS views,
  COUNT(DISTINCT JSON_VALUE(data, '$.uid')) AS unique_viewers,
  AVG(CAST(JSON_VALUE(data, '$.params.time_on_prev_ms') AS INT64)) AS avg_time_on_prev_ms
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND JSON_VALUE(data, '$.event') = 'page_view'
  AND operation IN ('CREATE', 'IMPORT')
GROUP BY screen_name
ORDER BY views DESC
LIMIT 30
```

### 4. Acquisition funnel: landing → signup → first chat → first message

```sql
WITH user_first_events AS (
  SELECT
    JSON_VALUE(data, '$.uid') AS uid,
    MIN(IF(JSON_VALUE(data, '$.event') = 'landing_view', timestamp, NULL)) AS ts_landing,
    MIN(IF(JSON_VALUE(data, '$.event') = 'sign_up_success', timestamp, NULL)) AS ts_signup,
    MIN(IF(JSON_VALUE(data, '$.event') = 'chat_opened', timestamp, NULL)) AS ts_first_chat,
    MIN(IF(JSON_VALUE(data, '$.event') = 'message_sent', timestamp, NULL)) AS ts_first_message
  FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
  WHERE
    timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
    AND operation IN ('CREATE', 'IMPORT')
    AND JSON_VALUE(data, '$.uid') IS NOT NULL
  GROUP BY uid
)
SELECT
  COUNTIF(ts_landing IS NOT NULL) AS step_1_landing,
  COUNTIF(ts_signup IS NOT NULL) AS step_2_signup,
  COUNTIF(ts_first_chat IS NOT NULL) AS step_3_first_chat,
  COUNTIF(ts_first_message IS NOT NULL) AS step_4_first_message,
  ROUND(SAFE_DIVIDE(COUNTIF(ts_signup IS NOT NULL), COUNTIF(ts_landing IS NOT NULL)) * 100, 1) AS landing_to_signup_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(ts_first_chat IS NOT NULL), COUNTIF(ts_signup IS NOT NULL)) * 100, 1) AS signup_to_chat_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(ts_first_message IS NOT NULL), COUNTIF(ts_first_chat IS NOT NULL)) * 100, 1) AS chat_to_message_pct
FROM user_first_events
```

В Looker — Scorecard для каждого шага + переходы в %.

### 5. Cohort retention (по дням от первого визита)

```sql
WITH first_seen AS (
  SELECT
    JSON_VALUE(data, '$.uid') AS uid,
    MIN(DATE(timestamp)) AS cohort_date
  FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
  WHERE
    operation IN ('CREATE', 'IMPORT')
    AND JSON_VALUE(data, '$.uid') IS NOT NULL
  GROUP BY uid
),
activity AS (
  SELECT
    JSON_VALUE(data, '$.uid') AS uid,
    DATE(timestamp) AS activity_date
  FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
  WHERE
    operation IN ('CREATE', 'IMPORT')
    AND JSON_VALUE(data, '$.uid') IS NOT NULL
)
SELECT
  fs.cohort_date,
  DATE_DIFF(a.activity_date, fs.cohort_date, DAY) AS day_offset,
  COUNT(DISTINCT a.uid) AS users
FROM first_seen fs
INNER JOIN activity a USING (uid)
WHERE fs.cohort_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND DATE_DIFF(a.activity_date, fs.cohort_date, DAY) BETWEEN 0 AND 30
GROUP BY cohort_date, day_offset
ORDER BY cohort_date, day_offset
```

В Looker — Pivot table: rows = `cohort_date`, columns = `day_offset`, values = `users`. Получишь классическую retention heatmap.

### 6. Per-user event timeline — для саппорта/дебага

```sql
SELECT
  timestamp,
  JSON_VALUE(data, '$.event') AS event,
  JSON_VALUE(data, '$.platform') AS platform,
  JSON_VALUE(data, '$.params.screen_name') AS screen_name,
  JSON_QUERY(data, '$.params') AS all_params
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  JSON_VALUE(data, '$.uid') = @user_id  -- параметризованный запрос
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND operation IN ('CREATE', 'IMPORT')
ORDER BY timestamp DESC
LIMIT 500
```

В Looker — Table chart. Параметр `@user_id` задаётся через Looker filter control.

### 7. Platform breakdown (web vs PWA vs mobile)

```sql
SELECT
  JSON_VALUE(data, '$.platform') AS platform,
  COUNT(DISTINCT JSON_VALUE(data, '$.uid')) AS unique_users,
  COUNT(*) AS events
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND operation IN ('CREATE', 'IMPORT')
GROUP BY platform
ORDER BY unique_users DESC
```

Pie chart в Looker.

### 8. Feature adoption: secret chats / E2EE / voice messages

```sql
SELECT
  DATE(timestamp) AS day,
  COUNTIF(JSON_VALUE(data, '$.event') = 'secret_chat_enabled') AS secret_chats_enabled,
  COUNTIF(JSON_VALUE(data, '$.event') = 'e2ee_pairing_completed') AS e2ee_pairings,
  COUNTIF(JSON_VALUE(data, '$.event') = 'voice_message_recorded') AS voice_messages,
  COUNTIF(JSON_VALUE(data, '$.event') = 'pwa_installed') AS pwa_installs
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND operation IN ('CREATE', 'IMPORT')
GROUP BY day
ORDER BY day
```

Multi-series Time Series в Looker.

### 9. Error tracking: e2ee_failure по стадиям

```sql
SELECT
  JSON_VALUE(data, '$.params.stage') AS stage,
  JSON_VALUE(data, '$.params.error_code') AS error_code,
  COUNT(*) AS occurrences,
  COUNT(DISTINCT JSON_VALUE(data, '$.uid')) AS affected_users
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND JSON_VALUE(data, '$.event') = 'e2ee_failure'
  AND operation IN ('CREATE', 'IMPORT')
GROUP BY stage, error_code
ORDER BY occurrences DESC
```

---

## Looker Studio — как использовать

1. **Открыть**: https://lookerstudio.google.com → **+ Create → Data source**.
2. **Connector**: BigQuery → My Projects → `project-72b24` → `firestore_export` →
   - Для быстрых отчётов на актуальном snapshot: **view `analytics_events_raw_latest`**.
   - Для исторических queries: **table `analytics_events_raw_changelog`**.
3. **Custom Query** (рекомендуется): нажми вкладку **Custom Query** в BigQuery connector → вставь любой SQL из этого файла → **Connect**.
4. Каждый Custom Query становится отдельным data source — на его основе строишь графики.
5. Один Looker Dashboard может иметь много data sources одновременно — миксуй.

## Что показать на первом дашборде «LighChat Product Analytics»

1. **Header row (Scorecards)**:
   - Total events (last 7d)
   - DAU today
   - WAU
   - MAU
   - Unique users this month

2. **Engagement section**:
   - DAU time series (query #1)
   - Top events bar chart (query #2)
   - Platform pie (query #7)

3. **Acquisition section**:
   - Funnel scorecards (query #4)
   - Top pages table (query #3)

4. **Retention section**:
   - Cohort retention pivot/heatmap (query #5)

5. **Feature adoption section**:
   - Multi-series chart (query #8)

6. **Errors section**:
   - E2EE failures table (query #9)

7. **Support section**:
   - User timeline table с filter control по uid (query #6)

## Стоимость

BigQuery $5/TB scanned. Каждый из этих queries scanет максимум ~100 MB на наших объёмах → доли цента. Looker Studio тулит кэширование, по умолчанию dashboard перестраивается раз в 12 часов. Можно настроить cache до 12h или real-time (дороже).

Для нашего масштаба общий cost: **меньше $1/мес**.

## Когда понадобится — Materialized Views

Если запросы по `JSON_VALUE` начнут тормозить (например при объёме > 100M событий), создай materialized view с распарсенными колонками:

```sql
CREATE MATERIALIZED VIEW `project-72b24.firestore_export.analytics_events_parsed`
PARTITION BY DATE(timestamp)
CLUSTER BY event, platform
AS SELECT
  timestamp,
  document_id,
  JSON_VALUE(data, '$.event') AS event,
  JSON_VALUE(data, '$.platform') AS platform,
  JSON_VALUE(data, '$.uid') AS uid,
  JSON_QUERY(data, '$.params') AS params,
  data
FROM `project-72b24.firestore_export.analytics_events_raw_changelog`
WHERE operation IN ('CREATE', 'IMPORT')
```

Тогда все queries будут на чистых столбцах без JSON-парсинга. Производительность +×10, стоимость scanning -×10.
