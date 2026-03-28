-- ========================================================================
-- Exercise 4: Streamlit Application — Support Ops Dashboard
-- ========================================================================
-- This exercise uses a SHELL APP. You'll create the Streamlit app with
-- the shell code, then use CoCo to write the actual dashboard.
-- ========================================================================

-- STEP 1: Create the Streamlit app shell
-- -----------------------------------------------------------------------
-- 1. In Snowsight, go to Projects > Streamlit
-- 2. Click "+ Streamlit App"
-- 3. Name it "Support Ops Dashboard"
-- 4. Set location to PAWCORE_ANALYTICS.SUPPORT
-- 5. Set warehouse to PAWCORE_DEMO_WH
-- 6. Click "Create"
-- 7. Replace the default code with the contents of streamlit_shell.py
--    from this exercises/ folder

-- STEP 2: Ask CoCo to build the dashboard
-- -----------------------------------------------------------------------
-- In the CoCo panel (while viewing the Streamlit editor), paste this:

-- Build out this Streamlit dashboard. Read from the
-- SUPPORT_OPS_DASHBOARD dynamic table in PAWCORE_ANALYTICS.SUPPORT.
--
-- Add these sections:
-- 1. Regional readiness cards with color coding:
--    green for SUPPORT_READY = TRUE, red for SUPPORT_READY = FALSE
-- 2. A bar chart comparing total_tickets vs critical_tickets by region
-- 3. A metrics table with all columns including avg_sentiment,
--    low_battery_events, and low_rating_count
-- 4. A Risk Assessment section that flags regions where
--    critical_tickets are high or avg_sentiment is negative
--
-- Use the Snowpark session (already set up in the code) for data access.

-- STEP 3: Iterate with CoCo (optional)
-- -----------------------------------------------------------------------
-- Once the dashboard is running, ask CoCo to enhance it:

-- Add a sidebar dropdown to filter by region. When a region is selected,
-- show the top 5 most critical support tickets from
-- PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS for that region.
