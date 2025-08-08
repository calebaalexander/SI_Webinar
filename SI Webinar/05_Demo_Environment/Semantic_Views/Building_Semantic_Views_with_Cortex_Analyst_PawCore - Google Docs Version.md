Building Semantic Views with Cortex Analyst — PawCore Systems (Google Docs Version)

This step-by-step guide explains how to build, verify, and use Semantic Views for PawCore Systems sales and operations data, then connect them to Cortex Analyst for natural language analytics.

Audience: Snowflake admins, data engineers, and BI leads preparing the PawCore demo or customer environments.

1) Prerequisites

- Snowflake account with admin privileges
- Roles and objects created by: SI Webinar/05_Demo_Environment/Setup_Scripts/01_Account_Setup.sql
  - Role: PAWCORE_WEBINAR_ROLE
  - Warehouse: PAWCORE_INTELLIGENCE_WH
  - Database/Schema: PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA
  - Stage and file format: INTERNAL_DATA_STAGE, CSV_FORMAT
- PawCore CSVs uploaded to the internal stage:
  - pawcore_sales.csv
  - pawcore_slack.csv
- Session context to use during setup: PAWCORE_WEBINAR_ROLE, PAWCORE_INTELLIGENCE_WH, PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA

2) Load Structured Data (Sales and Team Communications)

Run the loader script: SI Webinar/05_Demo_Environment/Setup_Scripts/02_Data_Loading.sql

Key objects created and loaded:
- Fact table: PAWCORE_SALES
- Communications table: TEAM_COMMUNICATIONS
- Dimensions: PRODUCT_DIM, REGION_DIM, CUSTOMER_DIM

Verification: Use the row-count checks and sample queries at the end of the loader to confirm data is present.

3) Create the Sales Semantic View

Purpose: Enable natural language queries over sales performance by product, region, and customer.

Run: SI Webinar/05_Demo_Environment/Semantic_Views/01_Sales_Semantic_View.sql

It defines:
- Tables: PAWCORE_SALES, PRODUCT_DIM, REGION_DIM, CUSTOMER_DIM
- Relationships: Sales to Products, Regions, Customers
- Facts: ACTUAL_SALES, FORECAST_SALES, VARIANCE, INVENTORY_UNITS_AVAILABLE, MARKETING_ENGAGEMENT_SCORE
- Dimensions: Sale date, product attributes, region, customer
- Metrics: Total revenue, total forecast, total variance, total units, revenue growth, inventory turnover, average engagement score

Verification: Check PAWCORE_SALES_SEMANTIC_VIEW appears in INFORMATION_SCHEMA and shows created successfully.

4) Create the Operations Semantic View

Purpose: Enable natural language queries over team collaboration, projects, and departments.

Run: SI Webinar/05_Demo_Environment/Semantic_Views/02_Operations_Semantic_View.sql

It defines:
- Tables: TEAM_COMMUNICATIONS, PROJECT_DIM, DEPARTMENT_DIM, TEAM_MEMBER_DIM
- Relationships: Communications to Projects, Departments, Members; Team Members to Departments
- Facts: Message length, reactions, replies, project duration
- Dimensions: Date, channel, message text, project metadata, department, team member
- Metrics: Total messages, average message length, total reactions, engagement rate, active and completed projects, average project duration, total departments, total team members

Verification: Check PAWCORE_OPERATIONS_SEMANTIC_VIEW appears in INFORMATION_SCHEMA and shows created successfully.

5) Grant Access to Semantic Views

Ensure the demo role can query both views by granting SELECT on the semantic views to PAWCORE_WEBINAR_ROLE.

6) Connect to Cortex Analyst

Run the Analyst services script: SI Webinar/05_Demo_Environment/Cortex_Services/02_Analyst_Services.sql

This creates domain services such as:
- Analyst_PawCore_Sales_Performance (uses PAWCORE_SALES_SEMANTIC_VIEW)
- Analyst_PawCore_Financial_Data, Analyst_PawCore_Marketing_Metrics, Analyst_PawCore_Regional_Analysis, Analyst_PawCore_Product_Analysis (as defined in the script)

Verify services show READY in Snowflake and that PAWCORE_WEBINAR_ROLE has usage.

7) Smoke Test with Natural Language Prompts

Sales, trends, and accuracy:
- Show Q4 2024 sales by region and product with variance to forecast.
- Which regions had the highest forecast accuracy last quarter?
- Trend actual versus forecast sales by month with a line chart.

Product and customer insights:
- Compare revenue and units for PetTracker, HealthMonitor, and SmartCollar across regions.
- Top 10 customers by revenue and their segments.

Operations and collaboration:
- How many total messages, replies, and reactions per Slack channel last month?
- List active projects and average project duration by department.

8) Troubleshooting Checklist

No results or missing data:
- Confirm CSVs are in INTERNAL_DATA_STAGE and 02_Data_Loading.sql completed without errors.
- Check row counts in PAWCORE_SALES and TEAM_COMMUNICATIONS.

Semantic view errors:
- Re-run 01_Sales_Semantic_View.sql and 02_Operations_Semantic_View.sql under SNOWFLAKE_INTELLIGENCE_ADMIN_RL.
- Ensure the referenced tables and columns exist in BUSINESS_DATA.

Permissions:
- Confirm GRANT SELECT on the semantic views to PAWCORE_WEBINAR_ROLE was applied.
- Verify current session role and USE context.

Analyst service readiness:
- In Services, ensure services show READY, not INITIALIZING.
- If stuck, restart the service and retry.

Performance:
- Start or scale PAWCORE_INTELLIGENCE_WH.
- Avoid running heavy parallel loads during testing.

9) Appendix — Object Reference

Core role and compute:
- Role: PAWCORE_WEBINAR_ROLE
- Warehouse: PAWCORE_INTELLIGENCE_WH

Database layout:
- PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA

Tables:
- PAWCORE_SALES, TEAM_COMMUNICATIONS
- PRODUCT_DIM, REGION_DIM, CUSTOMER_DIM
- PROJECT_DIM, DEPARTMENT_DIM, TEAM_MEMBER_DIM

Semantic Views:
- PAWCORE_SALES_SEMANTIC_VIEW
- PAWCORE_OPERATIONS_SEMANTIC_VIEW

Services (Analyst examples):
- Analyst_PawCore_Sales_Performance
- Analyst_PawCore_Regional_Analysis
- Analyst_PawCore_Marketing_Metrics
- Analyst_PawCore_Product_Analysis

Files and paths:
- Loader: SI Webinar/05_Demo_Environment/Setup_Scripts/02_Data_Loading.sql
- Sales SV: SI Webinar/05_Demo_Environment/Semantic_Views/01_Sales_Semantic_View.sql
- Ops SV: SI Webinar/05_Demo_Environment/Semantic_Views/02_Operations_Semantic_View.sql
- Analyst: SI Webinar/05_Demo_Environment/Cortex_Services/02_Analyst_Services.sql

This version is formatted for Google Docs: no markdown headers, no code blocks, and plain, copy-ready sectioning.
