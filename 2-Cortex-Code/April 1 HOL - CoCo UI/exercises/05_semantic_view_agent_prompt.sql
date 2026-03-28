-- ========================================================================
-- Exercise 5: Semantic View & Intelligence Agent
-- ========================================================================
-- Two prompts: one for the Semantic View, one for the Cortex Agent.
-- ========================================================================

-- STEP 1 — SEMANTIC VIEW
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a Cortex Analyst semantic view called
-- PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS for support operations analysis.
--
-- Include these tables:
-- 1. SUPPORT.SUPPORT_TICKETS — ticket volume, severity, and status by region
-- 2. SUPPORT.CUSTOMER_REVIEWS — customer ratings and review text
-- 3. DEVICE_DATA.TELEMETRY — device sensor readings and battery levels
-- 4. SUPPORT.V2_BETA_FEEDBACK — beta tester feedback on V2
--
-- Define metrics: total_tickets, critical_ticket_count, avg_rating,
-- avg_battery_level, low_battery_event_count, avg_beta_rating.
--
-- IMPORTANT: Do NOT use "data_type" in the YAML — it is not a valid
-- semantic view field and will cause parsing errors. Continue autonomously.
-- -----------------------------------------------------------------------


-- STEP 2 — CORTEX AGENT
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a Cortex Agent PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_SUPPORT_OPS_AGENT
-- using model 'claude-haiku-4-5' with tools for
-- PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS semantic view and the Cortex Search
-- service PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH. Run
-- SHOW CORTEX SEARCH SERVICES IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC to confirm
-- it exists. If the search service doesn't exist, STOP and tell me — the
-- setup script should have created it. Do NOT create it yourself. Add
-- orchestration and response instructions so the agent knows its role, uses
-- the right tool for each question type, and responds concisely with bullet
-- points and regional breakdowns. Grant USAGE on the agent to PUBLIC.
-- Continue autonomously.
-- -----------------------------------------------------------------------


-- STEP 3 — TEST IN SNOWFLAKE INTELLIGENCE
-- 1. Navigate to AI & ML > Agents > Snowflake Intelligence tab
-- 2. Click "Add existing agent"
-- 3. Search for PAWCORE_SUPPORT_OPS_AGENT, select it, confirm
-- 4. Switch to Snowflake Intelligence and try these questions:

-- "Which region has the highest support ticket load and what's driving it?"
-- "Is there a correlation between low battery events and critical support tickets?"
-- "What are beta testers saying about V2?"
