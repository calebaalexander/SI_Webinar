-- ========================================================================
-- Exercise 5: Semantic View & Intelligence Agent
-- ========================================================================
-- Two prompts: one for the Semantic View, one for the Cortex Agent.
-- ========================================================================

-- STEP 1: SEMANTIC VIEW
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a semantic view called SUPPORT_OPS in PAWCORE_ANALYTICS.SEMANTIC
-- over these tables: SUPPORT.SUPPORT_TICKETS, SUPPORT.CUSTOMER_REVIEWS,
-- DEVICE_DATA.TELEMETRY, and SUPPORT.SLACK_MESSAGES.
-- Define these metrics: total_tickets, critical_ticket_count,
-- average_customer_rating, low_battery_event_count (battery_level < 0.20),
-- and average_sentiment_score using SNOWFLAKE.CORTEX.SENTIMENT on review text.
-- Set up joins between tables on device_id and region.
-- Do not include a data_type field.
-- -----------------------------------------------------------------------


-- STEP 2: CORTEX AGENT
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a Cortex Agent called PAWCORE_SUPPORT_OPS_AGENT in
-- PAWCORE_ANALYTICS.SEMANTIC. Use the SUPPORT_OPS semantic view.
-- Give it these instructions: respond concisely with bullet points,
-- always include a regional breakdown when relevant, and highlight EMEA
-- specifically when ticket volume or sentiment is a concern.
-- Grant usage to PUBLIC role.
-- -----------------------------------------------------------------------


-- STEP 3: TEST IN SNOWFLAKE INTELLIGENCE
-- 1. Navigate to AI & ML > Agents > Snowflake Intelligence tab
-- 2. Click "Add existing agent"
-- 3. Search for PAWCORE_SUPPORT_OPS_AGENT, select it, confirm
-- 4. Switch to Snowflake Intelligence and try these questions:

-- "Which region has the highest support ticket load and what's driving it?"
-- "Is there a correlation between low battery events and critical support tickets?"
-- "What is EMEA's average sentiment score compared to APAC?"
