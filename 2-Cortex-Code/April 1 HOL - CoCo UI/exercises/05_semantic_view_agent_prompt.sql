-- ========================================================================
-- Exercise 5: Semantic View & Intelligence Agent
-- ========================================================================
-- Two prompts: one for the Semantic View, one for the Cortex Agent.
-- ========================================================================

-- STEP 1: SEMANTIC VIEW
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a semantic view PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS over these tables:
-- PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS
-- PAWCORE_ANALYTICS.SUPPORT.CUSTOMER_REVIEWS
-- PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY
-- PAWCORE_ANALYTICS.SUPPORT.SLACK_MESSAGES
--
-- Metrics:
-- total_tickets — count of tickets
-- critical_ticket_count — count where priority = 'Critical'
-- average_customer_rating — average of the rating column
-- low_battery_event_count — count of telemetry rows where battery_level < 0.20
-- average_sentiment_score — average of SNOWFLAKE.CORTEX.SENTIMENT(review_text)
--
-- Relationships: Join tickets and reviews to telemetry on (device_id, region).
-- slack_messages has no shared join key — include it as a standalone table.
--
-- Exclude data_type from dimensions.
-- -----------------------------------------------------------------------


-- STEP 2: CORTEX AGENT
-- Copy this prompt into CoCo:
-- -----------------------------------------------------------------------
-- Create a Cortex Agent called PAWCORE_SUPPORT_OPS_AGENT in
-- PAWCORE_ANALYTICS.SEMANTIC. Attach the
-- PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS semantic view as a Cortex Analyst
-- tool. Use these response instructions: respond concisely with bullet points,
-- always include a regional breakdown when relevant, and highlight EMEA
-- specifically when ticket volume or sentiment is a concern.
-- Grant USAGE on the agent to the PUBLIC role.
-- -----------------------------------------------------------------------


-- STEP 3: TEST IN SNOWFLAKE INTELLIGENCE
-- 1. Navigate to AI & ML > Agents > Snowflake Intelligence tab
-- 2. Click "Add existing agent"
-- 3. Search for PAWCORE_SUPPORT_OPS_AGENT, select it, confirm
-- 4. Switch to Snowflake Intelligence and try these questions:

-- "Which region has the highest support ticket load and what's driving it?"
-- "Is there a correlation between low battery events and critical support tickets?"
-- "What is EMEA's average sentiment score compared to APAC?"
