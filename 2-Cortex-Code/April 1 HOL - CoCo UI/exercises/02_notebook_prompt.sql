-- ========================================================================
-- Exercise 2: Snowflake Notebook — Support Ops Analysis
-- ========================================================================
-- Upload support_ops_starter.ipynb into Snowflake Workspaces:
--   1. In Snowsight, open Workspaces from the left sidebar
--   2. Click + Add new → Upload Files
--   3. Select support_ops_starter.ipynb from this exercises/ folder
--   4. Open it, set database to PAWCORE_ANALYTICS, schema to SUPPORT,
--      pick warehouse PAWCORE_DEMO_WH, and rename it to:
--      Support Ops Readiness Analysis
--
-- Then paste the prompt below into the CoCo panel:
-- ========================================================================

-- COCO PROMPT:
-- -----------------------------------------------------------------------
Improve this notebook. Pull in ticket counts, critical ticket counts, and average resolution time from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS. Add SNOWFLAKE.CORTEX.SENTIMENT on review text as a feature. Replace the model with a RandomForestRegressor. Add a final cell flagging each region as SUPPORT_READY or AT_RISK based on predicted rating and sentiment score.
-- -----------------------------------------------------------------------
