-- ========================================================================
-- Exercise 2: Snowflake Notebook — Support Ops Analysis
-- ========================================================================
-- This exercise uses a STARTER NOTEBOOK with partially working cells.
-- You'll upload it to Snowflake, then use CoCo to fix and upgrade it.
-- ========================================================================

-- STEP 1: Upload the starter notebook
-- -----------------------------------------------------------------------
-- 1. Download "support_ops_starter.ipynb" from this exercises/ folder
-- 2. In Snowsight, go to Projects > Notebooks
-- 3. Click the dropdown arrow next to "+ Notebook" and select "Import .ipynb file"
-- 4. Upload support_ops_starter.ipynb
-- 5. Set the location to PAWCORE_ANALYTICS.SUPPORT
-- 6. Set the warehouse to PAWCORE_DEMO_WH
-- 7. Click "Create"

-- STEP 2: Run all cells and observe the issues
-- -----------------------------------------------------------------------
-- Cell 1 (Ticket Volume): Works correctly
-- Cell 2 (Customer Reviews): ERROR - wrong schema and wrong column name
-- Cell 3 (Telemetry): Runs but returns NO RESULTS - filters too restrictive
-- Cell 4 (Sentiment): Works but INCOMPLETE - just counts, no actual AI sentiment
-- Cell 5 (Readiness): PLACEHOLDER - just says TODO

-- STEP 3: Use CoCo to fix the broken cells
-- -----------------------------------------------------------------------
-- For Cell 2 (schema/column error):
--   In the CoCo panel, type:
--   "Fix this error"
--
-- For Cell 3 (no results):
--   In the CoCo panel, type:
--   "Cell 3 returned no results. The filters are too restrictive. Fix the query so it returns data."

-- STEP 4: Use CoCo to upgrade the incomplete cells
-- -----------------------------------------------------------------------
-- For Cell 4 (sentiment stub), paste this into CoCo:

-- Upgrade Cell 4 to use SNOWFLAKE.CORTEX.SENTIMENT on the review_text
-- column from CUSTOMER_REVIEWS. Show average sentiment score per region
-- and flag regions where avg sentiment is below -0.1 as AT_RISK.

-- For Cell 5 (readiness placeholder), paste this into CoCo:

-- Rewrite Cell 5 as a composite readiness score. Join ticket counts,
-- sentiment scores, and telemetry anomalies by region. Flag each region
-- as SUPPORT_READY when critical tickets are under 20 and sentiment
-- is positive. Show all metrics side by side.
