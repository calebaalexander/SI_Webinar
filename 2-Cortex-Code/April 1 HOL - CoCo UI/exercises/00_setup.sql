-- ========================================================================
-- PawCore Setup Script: Quick Reference
-- ========================================================================
-- Full setup script is at: 2-Cortex-Code/setup/CoCo_PawCore_Setup.sql
--
-- INSTRUCTIONS:
-- 1. Open a SQL worksheet in Snowsight
-- 2. Copy the FULL setup script from the link above and paste it here
-- 3. Click "Run All" or ask CoCo: "Execute this setup script"
-- 4. The script takes ~2-3 minutes and creates:
--    - PAWCORE_ANALYTICS database with 6 schemas
--    - 7 tables loaded with demo data
--    - Cortex Search Service for document search
--    - Roles and grants
--
-- VERIFY:
-- After setup, run this in CoCo or your worksheet:

SELECT 'TELEMETRY' as table_name, COUNT(*) as row_count FROM PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY
UNION ALL
SELECT 'QUALITY_LOGS', COUNT(*) FROM PAWCORE_ANALYTICS.MANUFACTURING.QUALITY_LOGS
UNION ALL
SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM PAWCORE_ANALYTICS.SUPPORT.CUSTOMER_REVIEWS
UNION ALL
SELECT 'SLACK_MESSAGES', COUNT(*) FROM PAWCORE_ANALYTICS.SUPPORT.SLACK_MESSAGES
UNION ALL
SELECT 'SUPPORT_TICKETS', COUNT(*) FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS
UNION ALL
SELECT 'V2_BETA_FEEDBACK', COUNT(*) FROM PAWCORE_ANALYTICS.SUPPORT.V2_BETA_FEEDBACK
UNION ALL
SELECT 'PARSED_CONTENT', COUNT(*) FROM PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT;

-- Expected row counts:
-- TELEMETRY:         ~21,000
-- QUALITY_LOGS:      ~800+
-- CUSTOMER_REVIEWS:  ~1,500+
-- SLACK_MESSAGES:    ~37
-- SUPPORT_TICKETS:   ~240
-- V2_BETA_FEEDBACK:  ~120
-- PARSED_CONTENT:    1+
