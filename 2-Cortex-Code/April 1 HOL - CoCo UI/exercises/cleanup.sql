-- ========================================================================
-- Cleanup — Remove objects created during the lab
-- ========================================================================
-- Run this to remove only the objects YOU created during the exercises.
-- The shared PawCore data and setup objects are preserved.
-- ========================================================================

USE ROLE ACCOUNTADMIN;

-- Exercise 3: Dynamic Table
DROP DYNAMIC TABLE IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD;

-- Exercise 5: Semantic View
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS;

-- Exercise 4: Streamlit App
DROP STREAMLIT IF EXISTS PAWCORE_ANALYTICS.SUPPORT."Support Ops Dashboard";

-- Exercise 5: Cortex Agent
DROP CORTEX AGENT IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_SUPPORT_OPS_AGENT;

-- Exercise 2: Notebook
DROP NOTEBOOK IF EXISTS PAWCORE_ANALYTICS.SUPPORT."Support Ops Readiness Analysis";


-- ========================================================================
-- FULL TEARDOWN (only if no other demos depend on this data)
-- ========================================================================
-- Uncomment and run these lines to remove EVERYTHING:
--
-- DROP DATABASE IF EXISTS PAWCORE_ANALYTICS;
-- DROP WAREHOUSE IF EXISTS PAWCORE_DEMO_WH;
-- DROP API INTEGRATION IF EXISTS github_api;
