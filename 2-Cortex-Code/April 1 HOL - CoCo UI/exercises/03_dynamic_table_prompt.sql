-- ========================================================================
-- Exercise 3: Dynamic Table Pipeline
-- ========================================================================
-- The setup script (00_setup.sql) pre-builds this Dynamic Table so the
-- showcase query works even if CoCo's output needs adjustment.
--
-- Paste the prompt below into the CoCo panel to rebuild it with CoCo,
-- then verify with the query at the bottom.
-- ========================================================================

-- COCO PROMPT:
-- -----------------------------------------------------------------------
Create a Dynamic Table called SUPPORT_OPS_DASHBOARD in PAWCORE_ANALYTICS.SUPPORT using warehouse PAWCORE_DEMO_WH with a target lag of 1 minute. Aggregate by region: total ticket count, critical ticket count, average customer rating, count of low battery events where battery_level < 0.20, and average SNOWFLAKE.CORTEX.SENTIMENT score from customer review text. Add a READINESS_STATUS column: flag as 'SUPPORT_READY' when critical tickets are 25 or fewer and average sentiment is above 0.5, otherwise 'AT_RISK'. Join SUPPORT.SUPPORT_TICKETS, SUPPORT.CUSTOMER_REVIEWS, and DEVICE_DATA.TELEMETRY.
-- -----------------------------------------------------------------------


-- ========================================================================
-- VERIFY: After CoCo creates the table, run this first
-- ========================================================================
SELECT * FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD ORDER BY REGION;

-- Expected: APAC SUPPORT_READY, Americas AT_RISK, EMEA AT_RISK
-- If all three regions show identical sentiment scores (~-0.78) and AT_RISK,
-- the join created row duplication. Run the corrected version below.


-- ========================================================================
-- CORRECTED VERSION (run if CoCo's output shows bad sentiment scores)
-- Uses CTEs to pre-aggregate each source before joining — no row duplication
-- ========================================================================
CREATE OR REPLACE DYNAMIC TABLE PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD
  TARGET_LAG = '1 minute'
  WAREHOUSE = PAWCORE_DEMO_WH
  REFRESH_MODE = AUTO
  INITIALIZE = ON_CREATE
AS
WITH device_region AS (
    SELECT DISTINCT DEVICE_ID, REGION
    FROM PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY
),
ticket_agg AS (
    SELECT
        REGION,
        COUNT(DISTINCT TICKET_ID)                                                AS TOTAL_TICKET_COUNT,
        COUNT(DISTINCT CASE WHEN PRIORITY = 'Critical' THEN TICKET_ID END)       AS CRITICAL_TICKET_COUNT
    FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS
    GROUP BY REGION
),
review_agg AS (
    SELECT
        d.REGION,
        AVG(r.RATING)                                           AS AVG_CUSTOMER_RATING,
        AVG(SNOWFLAKE.CORTEX.SENTIMENT(r.REVIEW_TEXT))         AS AVG_SENTIMENT_SCORE
    FROM PAWCORE_ANALYTICS.SUPPORT.CUSTOMER_REVIEWS r
    JOIN device_region d ON r.DEVICE_ID = d.DEVICE_ID
    GROUP BY d.REGION
),
telemetry_agg AS (
    SELECT
        REGION,
        COUNT(DISTINCT CASE WHEN BATTERY_LEVEL < 0.20 THEN DEVICE_ID END)  AS LOW_BATTERY_EVENT_COUNT
    FROM PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY
    GROUP BY REGION
)
SELECT
    t.REGION,
    t.TOTAL_TICKET_COUNT,
    t.CRITICAL_TICKET_COUNT,
    r.AVG_CUSTOMER_RATING,
    tel.LOW_BATTERY_EVENT_COUNT,
    r.AVG_SENTIMENT_SCORE,
    CASE
        WHEN t.CRITICAL_TICKET_COUNT <= 25
         AND r.AVG_SENTIMENT_SCORE > 0.5
        THEN 'SUPPORT_READY'
        ELSE 'AT_RISK'
    END AS READINESS_STATUS
FROM ticket_agg t
JOIN review_agg r      ON t.REGION = r.REGION
JOIN telemetry_agg tel ON t.REGION = tel.REGION;


-- ========================================================================
-- SHOWCASE: After the table is created, query the live dashboard
-- ========================================================================
SELECT * FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD ORDER BY REGION;

-- Expected: APAC SUPPORT_READY, Americas AT_RISK, EMEA AT_RISK
