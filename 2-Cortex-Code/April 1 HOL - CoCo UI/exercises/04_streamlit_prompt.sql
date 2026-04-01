-- ========================================================================
-- Exercise 4: Streamlit Application: Support Ops Dashboard
-- ========================================================================

-- STEP 1: Create the app shell first
-- -----------------------------------------------------------------------
-- In Snowsight: Projects > Streamlit > + Streamlit App
-- Name: Support_Ops_Dashboard
-- Database: PAWCORE_ANALYTICS  |  Schema: SUPPORT  |  Warehouse: PAWCORE_DEMO_WH
-- Click Create. The editor opens with default placeholder code.

-- STEP 2: CoCo PROMPT (paste into CoCo while the editor is open)
-- -----------------------------------------------------------------------

-- Build a Streamlit dashboard that reads from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD. Use get_active_session() to query the table. Include a header with the title "PawCore Support Ops Dashboard", regional readiness cards with green background for SUPPORT_READY and red for AT_RISK, a bar chart comparing TOTAL_TICKET_COUNT vs CRITICAL_TICKET_COUNT by region, and a risk section that calls out any AT_RISK region with a summary of what's driving it.

-- Replace the default placeholder code with CoCo's output and click Run.

-- STEP 3: Iterate with CoCo (optional)
-- -----------------------------------------------------------------------

-- Add a sidebar dropdown to filter by region. When a region is selected, query PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS and show the top 5 most critical open tickets for that region in a table below the chart.
