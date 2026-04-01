-- ========================================================================
-- Exercise 3: Dynamic Table Pipeline
-- ========================================================================
-- Paste the prompt below into the CoCo panel.
-- CoCo will generate and execute the Dynamic Table definition.
-- ========================================================================

-- COCO PROMPT:
-- -----------------------------------------------------------------------
Create a Dynamic Table called SUPPORT_OPS_DASHBOARD in PAWCORE_ANALYTICS.SUPPORT using warehouse PAWCORE_DEMO_WH with a target lag of 1 minute. Aggregate by region: total ticket count, critical ticket count, average customer rating, count of low battery events where battery_level < 0.20, and average SNOWFLAKE.CORTEX.SENTIMENT score from customer review text. Add a READINESS_STATUS column: flag as 'SUPPORT_READY' when critical tickets are under 20 and average sentiment is above 0, otherwise 'AT_RISK'. Join SUPPORT.SUPPORT_TICKETS, SUPPORT.CUSTOMER_REVIEWS, and DEVICE_DATA.TELEMETRY.
-- -----------------------------------------------------------------------


-- ========================================================================
-- SHOWCASE: After the table is created, run these steps
-- ========================================================================

-- Step 1: Query the live dashboard
SELECT * FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD ORDER BY REGION;


-- Step 2: Live flip — insert 25 critical tickets for APAC into the source table
-- (breaches the 20 critical ticket threshold, flipping APAC from SUPPORT_READY to AT_RISK)
INSERT INTO PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS
    (TICKET_ID, DEVICE_ID, REGION, PRIORITY, STATUS, CREATED_AT, RESOLVED_AT)
SELECT
    'SIM-' || SEQ4(),
    d.DEVICE_ID,
    'APAC',
    'Critical',
    'Open',
    CURRENT_TIMESTAMP(),
    NULL
FROM PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY d
WHERE d.REGION = 'APAC'
LIMIT 25;

-- Wait ~60 seconds, then re-query — APAC will flip to AT_RISK
SELECT * FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD ORDER BY REGION;


-- ========================================================================
-- CLEANUP: Reset before next demo run
-- ========================================================================
DELETE FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS WHERE TICKET_ID LIKE 'SIM-%';
