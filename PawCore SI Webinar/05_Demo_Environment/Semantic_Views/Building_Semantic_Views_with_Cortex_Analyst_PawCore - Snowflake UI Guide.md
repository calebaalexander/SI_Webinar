Building Semantic Views with Cortex Analyst — PawCore Systems (Snowflake UI Guide)

Purpose
A step-by-step, Snowflake UI–only walkthrough to build Semantic Views for PawCore Systems data and connect them to Cortex Analyst. This follows the same customer-friendly approach as the referenced draft, adapted to PawCore objects.

Audience
Snowflake admins, data engineers, BI leads, sales engineers.

1) Prerequisites
- Role: PAWCORE_WEBINAR_ROLE (or equivalent privileges for creating semantic views and services)
- Warehouse: PAWCORE_INTELLIGENCE_WH
- Database and schema: PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA
- Data staged and loaded: pawcore_sales.csv to PAWCORE_SALES; pawcore_slack.csv to TEAM_COMMUNICATIONS

2) Set Context in Snowflake UI
- Sign in to Snowflake UI
- Top bar: select Role = PAWCORE_WEBINAR_ROLE
- Select Warehouse = PAWCORE_INTELLIGENCE_WH
- Object browser: expand Database = PAWCORE_INTELLIGENCE_DEMO, Schema = BUSINESS_DATA
- Confirm tables are present: PAWCORE_SALES and TEAM_COMMUNICATIONS

3) Create the Sales Semantic View (UI)
Goal: Enable natural language questions over sales performance by date, region, and product using PAWCORE_SALES.

Steps
- Left nav: Data (or Semantic Views) → Create Semantic View
- Choose Start from tables/views
- Select Base table = PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.PAWCORE_SALES
- Name: PAWCORE_SALES_SEMANTIC_VIEW
- Description: Semantic view for PawCore sales analysis across regions and products

Configure fields
- Mark Dimensions (categorical/time):
  - DATE → type Date; synonyms: date, sale date, period
  - REGION → type Text; synonyms: region, territory, market
  - PRODUCT → type Text; synonyms: product, item, device
- Mark Facts (numeric measures):
  - ACTUAL_SALES → type Amount; label Actual Sales
  - FORECAST_SALES → type Amount; label Forecast Sales
  - VARIANCE → type Number; label Variance (Actual minus Forecast)
  - INVENTORY_UNITS_AVAILABLE → type Number; label Inventory Units Available
  - MARKETING_ENGAGEMENT_SCORE → type Number; label Marketing Engagement Score
- Define Metrics (aggregations):
  - Total Revenue = SUM(Actual Sales)
  - Total Forecast = SUM(Forecast Sales)
  - Total Variance = SUM(Variance)
  - Forecast Accuracy = AVG(1 - ABS(Variance) / NULLIF(Forecast Sales, 0))  (label Forecast Accuracy)
  - Avg Engagement = AVG(Marketing Engagement Score)

Business context (optional but recommended)
- Add synonyms to the view title: sales data, revenue data, performance
- Add descriptions to key fields explaining business meaning

Save and Publish
- Click Save
- Click Publish (make the semantic view available to services and users)

4) (Optional) Enrich with Product and Region Dimensions (UI)
If you want richer attributes without SQL, add reference tables and simple relationships by name.

Steps
- Edit PAWCORE_SALES_SEMANTIC_VIEW → Tables → Add table
- Add PRODUCT_DIM and REGION_DIM
- Relationships
  - Map PAWCORE_SALES.PRODUCT → PRODUCT_DIM.PRODUCT_NAME (equality join)
  - Map PAWCORE_SALES.REGION → REGION_DIM.REGION_NAME (equality join)
- Expose attributes as Dimensions
  - PRODUCT_DIM.PRODUCT_CATEGORY (synonyms: category, product type)
  - REGION_DIM.CONTINENT (synonyms: continent, geography)
- Save and Publish

Note
If your environment lacks matching keys, name-based relationships are acceptable for demos. Keys can be added later for production.

5) Create the Operations Semantic View (UI)
Goal: Enable natural language questions over team communications by channel and thread.

Steps
- Create Semantic View → Start from tables/views
- Base table: PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.TEAM_COMMUNICATIONS
- Name: PAWCORE_OPERATIONS_SEMANTIC_VIEW
- Description: Operations and collaboration insights from team communications

Configure fields
- Dimensions
  - SLACK_CHANNEL → type Text; synonyms: channel, slack channel, communication channel
  - THREAD_ID → type Text; synonyms: thread, conversation
  - URL → type URL; synonyms: link, message link
- Derived attribute (optional): Message Length = LENGTH(TEXT) (mark as Number)
- Facts and Metrics
  - Total Messages = COUNT(*)
  - Distinct Threads = COUNT DISTINCT(THREAD_ID)
  - Avg Message Length = AVG(Message Length)

Save and Publish

6) Permissions (UI)
- Open each semantic view
- Go to Permissions (or Share/Grants) tab
- Grant SELECT on PAWCORE_SALES_SEMANTIC_VIEW and PAWCORE_OPERATIONS_SEMANTIC_VIEW to PAWCORE_WEBINAR_ROLE

7) Create Cortex Analyst Services (UI)
Goal: Expose the semantic views to natural language queries.

Steps
- Left nav: AI & ML → Cortex Analyst → New Service
- Service name: Analyst_PawCore_Sales_Performance
- Attach semantic view: PAWCORE_SALES_SEMANTIC_VIEW
- Add instructions (optional):
  - Focus on business-friendly responses and concise charts
  - Avoid raw reference markers; summarize document references naturally
- Save and Start the service

Repeat
- Create Analyst_PawCore_Operations for the operations view

8) Validate in UI with Natural Language
In the Analyst service playground, ask:
- Show Q4 2024 sales by region and product with variance to forecast
- Which region had the highest forecast accuracy last quarter?
- Trend actual vs forecast sales by month as a line chart
- List top products by total revenue
- How many total Slack messages last month by channel?
- What is the average message length by channel and top thread counts?

9) Troubleshooting (UI-first)
No results or empty charts
- Confirm the view is Published (not Draft)
- Verify the Analyst service status is READY
- Check table row counts in the object browser

Unexpected joins or duplicates
- Review relationships; ensure name-based mappings are correct
- Temporarily remove relationships and validate single-table behavior, then re-add

Metric definitions look off
- Open the semantic view → Metrics → check formulas and aggregation types
- Use preview queries in the view editor to validate fields

Permissions
- Confirm PAWCORE_WEBINAR_ROLE has SELECT on the semantic views
- Ensure current session role is PAWCORE_WEBINAR_ROLE

Performance
- Start or scale PAWCORE_INTELLIGENCE_WH as needed

10) What’s Next
- Add customer dimensions (CUSTOMER_DIM) for segmentation
- Add marketing data and define Marketing ROI metrics
- Attach both semantic views to the main AI agent for cross-domain Q&A

Object Reference
- Database/Schema: PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA
- Tables: PAWCORE_SALES, TEAM_COMMUNICATIONS, PRODUCT_DIM, REGION_DIM
- Semantic Views: PAWCORE_SALES_SEMANTIC_VIEW, PAWCORE_OPERATIONS_SEMANTIC_VIEW
- Analyst Services: Analyst_PawCore_Sales_Performance, Analyst_PawCore_Operations


