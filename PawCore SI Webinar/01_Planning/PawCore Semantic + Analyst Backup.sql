-- PawCore Semantic Views + Cortex Analyst Services (Backup Script)
-- Safe to run; objects are created or replaced. Use as a fallback if you prefer not to configure via UI.

-- 0) Context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PAWCORE_INTELLIGENCE_WH;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;

/*
1) Semantic View: Sales
   Combines core sales and supporting tables for NLQ over revenue/variance by region/product.
*/
CREATE OR REPLACE SEMANTIC VIEW PAWCORE_SALES_SEMANTIC_VIEW
TABLES (
  SALES    AS PAWCORE_SALES PRIMARY KEY (DATE, REGION, PRODUCT),
  DEVICES  AS DEVICE_SALES_BY_REGION PRIMARY KEY (DATE, REGION, DEVICE_TYPE),
  EMAILS   AS EMAIL_CAMPAIGNS PRIMARY KEY (CAMPAIGN_ID),
  ENHANCED AS ENHANCED_SALES_DATA PRIMARY KEY (SALE_ID)
);

/*
2) Semantic View: Operations
   Exposes team signals (Slack) and customer signals (Reviews) for NLQ summarisation.
*/
CREATE OR REPLACE SEMANTIC VIEW PAWCORE_OPERATIONS_SEMANTIC_VIEW
TABLES (
  SLACK   AS SLACK_MESSAGES PRIMARY KEY (MESSAGE_ID),
  REVIEWS AS CUSTOMER_REVIEWS PRIMARY KEY (REVIEW_ID)
);

/*
3) Cortex Analyst services
   Each service binds to a semantic view. Adjust names if needed.
*/
CREATE OR REPLACE CORTEX ANALYST SERVICE Analyst_PawCore_Sales
ON PAWCORE_SALES_SEMANTIC_VIEW
WAREHOUSE = PAWCORE_INTELLIGENCE_WH;

CREATE OR REPLACE CORTEX ANALYST SERVICE Analyst_PawCore_Operations
ON PAWCORE_OPERATIONS_SEMANTIC_VIEW
WAREHOUSE = PAWCORE_INTELLIGENCE_WH;

/*
4) Optional: Agent that uses both Analyst services
   You can create this via UI; this is a programmatic fallback.
*/
USE SCHEMA AGENTS;

CREATE OR REPLACE AGENT PAWCORE_BI_AGENT
WITH PROFILE='{"display_name":"PawCore BI Agent","description":"Answers sales and operations questions using PawCore semantic views."}'
FROM SPECIFICATION $$
{
  "models": { "orchestration": "snowflake-arctic-2.0" },
  "instructions": "You are the PawCore BI Agent. Use the provided tools to answer questions with tables and concise charts when helpful. Avoid citations.",
  "tools": [
    { "tool_spec": { "type": "cortex_analyst_text_to_sql", "name": "Sales Analyst",      "parameters": { "cortex_analyst_service": "Analyst_PawCore_Sales" } } },
    { "tool_spec": { "type": "cortex_analyst_text_to_sql", "name": "Operations Analyst", "parameters": { "cortex_analyst_service": "Analyst_PawCore_Operations" } } }
  ]
}
$$;

-- End of backup script
