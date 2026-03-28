author: Caleb Alexander
id: cortex-code-ui-hands-on-lab
language: en
summary: Learn how to use Cortex Code in Snowsight to fix broken queries, build notebooks, create dynamic table pipelines, deploy Streamlit apps, and launch Intelligence agents - all from natural language.
categories: snowflake-site:taxonomy/solution-center/certification/quickstart, snowflake-site:taxonomy/product/ai, snowflake-site:taxonomy/snowflake-feature/snowflake-intelligence, snowflake-site:taxonomy/snowflake-feature/dynamic-tables
environments: web
status: Published
feedback link: https://github.com/Snowflake-Labs/sfguides/issues
fork repo link: https://github.com/calebaalexander/HandsOnLabs
authors: Caleb Alexander

# Cortex Code in Snowsight: Build a Full Data Pipeline with AI
<!-- ------------------------ -->
## Overview
Duration: 5

**PawCore is a fictional company. All data, names, metrics, and scenarios are simulated for demonstration purposes only.**

In this guide you will use **Cortex Code**, the AI coding assistant built into Snowflake's web interface, to go from raw data to a fully operational analytics pipeline without writing a single line of code manually. You will fix broken queries, build a Snowflake Notebook, create a Dynamic Table pipeline, deploy a Streamlit application, and launch a Snowflake Intelligence agent - all through natural language conversation.

The scenario: PawCore, a pet health technology company, is preparing to launch SmartCollar V2. Marcus Thompson, the CX lead, needs to know whether his support team is operationally ready for the volume V2 will bring. You will build the analytics infrastructure he needs.

### Prerequisites
- A Snowflake account with the **ACCOUNTADMIN** role (or a role with sufficient privileges)
- Cortex Code enabled in your Snowflake environment (Settings > Cortex Code > toggle on)
- A modern web browser

### What You Will Learn
- How to fix broken SQL using natural language and the inline Fix button
- How to create Snowflake Notebooks from a single prompt
- How to build auto-refreshing Dynamic Table pipelines
- How to deploy Streamlit applications directly in Snowflake
- How to create Semantic Views and Cortex Agents for self-service analytics

### What You Will Need
- A [Snowflake account](https://signup.snowflake.com/) with ACCOUNTADMIN access
- ~45 minutes

### What You Will Build
A complete analytics pipeline:

```
Raw Data (7 tables)
  -> Notebook (explore support patterns & telemetry correlations)
    -> Dynamic Table (operationalize as auto-refresh pipeline)
      -> Streamlit App (visual dashboard for daily standup)
      -> Intelligence Agent (conversational analytics for ad-hoc investigation)
```

<!-- ------------------------ -->
## Environment Setup
Duration: 10

### Create a Workspace

1. Open your browser and navigate to your Snowflake account URL
2. Log in with your credentials and ensure you are using the **ACCOUNTADMIN** role
3. Click **Projects** in the left sidebar
4. Select **Workspaces** from the dropdown menu
5. Click **+ Workspace** to create a new workspace (or open an existing one)
6. Inside your workspace, click the **+** button in the tab bar and select **SQL file**
7. The **Cortex Code AI assistant panel** appears on the right side

> **Tip:** The Cortex Code panel is context-aware. It knows which project, database, and files you're working with.

### Load PawCore Data

Cortex Code in the UI cannot fetch files from external URLs, so you will copy the setup script into a worksheet.

1. Open the setup script from the GitHub repo: [CoCo_PawCore_Setup.sql](https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql)
2. **Copy the full script** and **paste it into your SQL worksheet**
3. In the Cortex Code panel, type:

```
Execute this setup script in the worksheet. Proceed autonomously - allow all statements in PAWCORE_ANALYTICS.
```

4. CoCo will parse and execute each statement. You will see a **permission prompt** - choose **"Allow all non-read SQL"** to speed things up.
5. The script creates:
   - `PAWCORE_ANALYTICS` database with 6 schemas
   - An API integration with the public GitHub repo
   - A Git Repository object for data loading
   - 7 tables loaded with demo data
   - A Cortex Search Service for document search

> The script is non-destructive. If you already have a PAWCORE_ANALYTICS database, existing objects are preserved.

**Alternative:** Paste the script and click **"Run All"** in the worksheet manually.

### Verify Data Loaded

In the Cortex Code panel, type:

```
Show me row counts for all tables in PAWCORE_ANALYTICS
```

| Table | Expected Rows |
|-------|--------------|
| DEVICE_DATA.TELEMETRY | ~21,000 |
| MANUFACTURING.QUALITY_LOGS | ~800+ |
| SUPPORT.CUSTOMER_REVIEWS | ~1,500+ |
| SUPPORT.SLACK_MESSAGES | ~37 |
| SUPPORT.SUPPORT_TICKETS | ~240 |
| SUPPORT.V2_BETA_FEEDBACK | ~120 |
| UNSTRUCTURED.PARSED_CONTENT | 1+ |

<!-- ------------------------ -->
## Fix Broken Code with CoCo
Duration: 8

CoCo can diagnose and fix broken SQL using natural language, the inline Fix button, and the Explain feature.

### Stage the Broken Query

Copy and paste this **intentionally broken** SQL into your worksheet:

```sql
SELECT region, severity, COUNT(*) as tiket_count
FROM PAWCORE_ANALYTICS.SUPORT.SUPPORT_TICKETS
GROUP BY region, severity
ORDER BY tiket_count DES;
```

Three errors are hidden in this query:
1. `DES` should be `DESC`
2. `SUPORT` should be `SUPPORT`
3. `severity` should be `PRIORITY` (the actual column name)
4. `tiket_count` is a cosmetic typo the compiler will not catch

### Use the Explain Button

1. **Select the entire query** in the worksheet
2. The **inline toolbar** appears: Add to Chat, Explain, Quick Edit, Format
3. Click **Explain**
4. CoCo returns a plain-English explanation of what the query does

> If you inherited code from someone who left the team, you do not have to reverse-engineer it. Highlight and click Explain.

### Method 1: Natural Language Fix

Fix `DES` using natural language:

1. **Select `DES`** on line 4
2. Click **"Add to Chat"** in the inline toolbar
3. In the CoCo panel, type:

```
Fix this - it should be DESC
```

4. CoCo returns the corrected line. **Accept the change.**

### Method 2: Inline Fix Button

Fix `SUPORT` using the compiler:

1. **Run the query** - you get an error: `Schema 'PAWCORE_ANALYTICS.SUPORT' does not exist`
2. A **Fix** button appears below the error message
3. **Click Fix** - CoCo shows a diff view with the correction: `SUPORT` -> `SUPPORT`
4. Click **"Keep all in file"** to accept

### Method 3: Schema Introspection

Fix `severity` -> `PRIORITY`:

1. **Run the query** - you get: `invalid identifier 'SEVERITY'`
2. **Click Fix** - CoCo checks the actual table columns and finds the table uses `PRIORITY`
3. **Accept the change.** Run the query - 8 rows returned.

### Bonus: Cosmetic Fix

The column header says `TIKET_COUNT`. Select the query, click **Add to Chat**, and type:

```
Fix the typo in this query - tiket_count should be ticket_count
```

Accept the fix and re-run. Clean column: `TICKET_COUNT`.

**Validation:**
- [ ] Used the Explain button to understand the query
- [ ] Fixed `DES` -> `DESC` using natural language
- [ ] Fixed `SUPORT` -> `SUPPORT` using the Fix button
- [ ] Fixed `severity` -> `PRIORITY` using the Fix button
- [ ] Fixed `tiket_count` -> `ticket_count` using natural language

<!-- ------------------------ -->
## Build a Snowflake Notebook
Duration: 8

Marcus needs a repeatable analysis of his team's support operations - ticket volumes, severity patterns, customer frustration signals, and device issues driving support calls.

### Create the Notebook

In the Cortex Code panel, paste this prompt:

```
Create a Snowflake Notebook called "Support Ops Readiness Analysis" in
PAWCORE_ANALYTICS.SUPPORT.

I want to analyze whether our support team is operationally ready for V2
launch volume. Build cells that examine support ticket severity by region,
customer review patterns that predict future ticket volume, device
telemetry anomalies like low battery events that drive support calls,
and AI-powered sentiment analysis on customer reviews. Finish with a
composite summary that flags each region as SUPPORT_READY or not based
on critical ticket counts and sentiment scores.

Use data from SUPPORT_TICKETS, CUSTOMER_REVIEWS, and TELEMETRY tables.
Use SNOWFLAKE.CORTEX.SENTIMENT for the sentiment analysis cell.

Create and run the notebook. Continue autonomously.
```

CoCo creates a multi-cell notebook with ticket breakdown, customer frustration signals, telemetry patterns, AI sentiment, and a composite readiness score.

### Fix Broken Cells

After running all cells, you will see issues:

**Cell 2 (schema/column error):** Click the error, then in the CoCo panel type:

```
Fix this error
```

CoCo checks the actual schema/column names and corrects them.

**Cell 3 (no results):** The query ran but returned zero rows. In the CoCo panel:

```
Cell 3 returned no results. The filters are too restrictive. Fix the query so it returns data.
```

CoCo checks the actual data ranges and relaxes the WHERE clause.

> CoCo catches issues that produce no error message at all - like overly restrictive filters that return empty results.

**Validation:**
- [ ] Notebook created with multiple analysis cells
- [ ] All cells execute successfully with meaningful results
- [ ] Sentiment analysis shows regional patterns
- [ ] Support ops summary shows SUPPORT_READY flags

<!-- ------------------------ -->
## Create a Dynamic Table Pipeline
Duration: 5

Marcus says: *"Great analysis, but tickets come in every hour. I need this data live."* A Dynamic Table solves this - define a query, attach a refresh interval, and Snowflake handles the rest. No Airflow, no cron jobs, no orchestration layer.

### Build the Dynamic Table

In the Cortex Code panel:

```
Create a Dynamic Table called PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD
that keeps a live view of our support operations health by region.

Aggregate ticket counts and critical ticket counts from SUPPORT_TICKETS,
customer ratings and low-rating counts from CUSTOMER_REVIEWS, low battery
events from TELEMETRY, and AI-powered sentiment scores on review text
using SNOWFLAKE.CORTEX.SENTIMENT. Flag each region as SUPPORT_READY
when critical tickets are under 20 and sentiment is positive.

Use PAWCORE_DEMO_WH warehouse and a target lag of 1 minute.

Execute the SQL.
```

CoCo generates a `CREATE OR REPLACE DYNAMIC TABLE` statement with proper joins, aggregations, AI sentiment function, and target lag configuration.

### Verify the Pipeline

Query the Dynamic Table:

```
Show me all rows from the SUPPORT_OPS_DASHBOARD dynamic table
```

You should see one row per region with aggregated support ops metrics and the SUPPORT_READY flag.

Check refresh status:

```
Show me the refresh history for the SUPPORT_OPS_DASHBOARD dynamic table
```

> Dynamic Tables eliminate ETL scheduling. Define the query once, and Snowflake automatically refreshes the results when upstream data changes.

**Validation:**
- [ ] Dynamic Table created with proper target lag
- [ ] Query returns regional support ops metrics
- [ ] SUPPORT_READY flag correctly identifies ready regions

<!-- ------------------------ -->
## Deploy a Streamlit Application
Duration: 8

Marcus wants a dashboard his CX team can check every morning before standup - not a spreadsheet, not a notebook, but a real application.

### Generate the App

In the Cortex Code panel:

```
Build a Streamlit in Snowflake app called "Support Ops Dashboard"
in PAWCORE_ANALYTICS.SUPPORT.

The app should:
1. Read from the SUPPORT_OPS_DASHBOARD dynamic table
2. Show a header: "SmartCollar - Support Operations Dashboard"
3. Display regional readiness cards with color coding:
   green for SUPPORT_READY regions, red for NEEDS_ATTENTION regions
4. Show a bar chart comparing total_tickets vs critical_tickets
   by region
5. Show a metrics table with all columns including avg_sentiment,
   low_battery_events, and low_rating_count
6. Add a "Risk Assessment" section that flags regions where
   critical_tickets are high or avg_sentiment is negative

Use the Snowpark session for data access. Deploy the app.
```

CoCo generates a complete Streamlit Python file and creates the app in Snowflake.

### Open and Interact

1. Navigate to **Projects** -> **Streamlit** in Snowsight
2. Open the **Support Ops Dashboard**
3. Review regional readiness cards, the ticket severity bar chart, and the risk assessment

### Iterate with CoCo

Ask CoCo to enhance the app:

```
Add a section to the Streamlit app that shows the top 5 most critical
support tickets from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS,
filtered by the region selected in a sidebar dropdown.
```

> CoCo builds full applications from natural language. The app reads from the Dynamic Table, so it is always current. You can iterate on the design conversationally.

**Validation:**
- [ ] Streamlit app created and deployed in Snowflake
- [ ] Dashboard shows regional readiness with color coding
- [ ] Bar chart displays ticket severity comparisons
- [ ] App reads from the Dynamic Table (auto-refreshing data)

<!-- ------------------------ -->
## Build a Semantic View and Intelligence Agent
Duration: 5

The final step: give Marcus self-service analytics through Snowflake Intelligence. He can ask ad-hoc questions in natural language without writing SQL.

### Create the Semantic View

In the Cortex Code panel:

```
Create a Cortex Analyst semantic view called
PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS for support operations analysis.

Include these tables:
1. SUPPORT.SUPPORT_TICKETS: ticket volume, severity, and status by region
2. SUPPORT.CUSTOMER_REVIEWS: customer ratings and review text
3. DEVICE_DATA.TELEMETRY: device sensor readings and battery levels
4. SUPPORT.V2_BETA_FEEDBACK: beta tester feedback on V2

Define metrics: total_tickets, critical_ticket_count, avg_rating,
avg_battery_level, low_battery_event_count, avg_beta_rating.

IMPORTANT: Do NOT use "data_type" in the YAML. It is not a valid
semantic view field and will cause parsing errors. Continue autonomously.
```

### Create the Agent

```
Create a Cortex Agent PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_SUPPORT_OPS_AGENT
using model 'claude-haiku-4-5' with tools for
PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS semantic view and the Cortex Search
service PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH. Run
SHOW CORTEX SEARCH SERVICES IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC to confirm
it exists. If the search service doesn't exist, STOP and tell me. The
setup script should have created it. Do NOT create it yourself. Add
orchestration and response instructions so the agent knows its role, uses
the right tool for each question type, and responds concisely with bullet
points and regional breakdowns. Grant USAGE on the agent to PUBLIC.
Continue autonomously.
```

### Test in Snowflake Intelligence

1. Navigate to **AI & ML -> Agents -> Snowflake Intelligence tab**
2. Click **"Add existing agent"**, search for `PAWCORE_SUPPORT_OPS_AGENT`, and confirm
3. Switch to **Snowflake Intelligence** and test:

```
Which region has the highest support ticket load and what's driving it?
```

```
Is there a correlation between low battery events and critical support tickets?
```

> The full pipeline is now connected: raw data -> Dynamic Table -> Streamlit dashboard -> Intelligence agent.

**Validation:**
- [ ] Semantic View created with support ops metrics
- [ ] Cortex Agent created and granted to PUBLIC
- [ ] Agent visible in Snowflake Intelligence
- [ ] Intelligence answers support operations questions accurately

<!-- ------------------------ -->
## Conclusion And Resources
Duration: 2

Congratulations! You have built a complete analytics pipeline using Cortex Code in Snowsight - entirely through natural language.

### What You Learned
- How to fix broken SQL using the Explain button, natural language, and the inline Fix button
- How to create multi-cell Snowflake Notebooks from a single prompt
- How to build auto-refreshing Dynamic Table pipelines
- How to deploy Streamlit applications directly inside Snowflake
- How to create Semantic Views and Cortex Agents for self-service analytics via Snowflake Intelligence

### What You Built

| Asset | What It Does |
|-------|-------------|
| **Code Fixing** | Fixed errors using natural language and the inline Fix button |
| **Snowflake Notebook** | Interactive support ops analysis with AI sentiment scoring |
| **Dynamic Table** | Auto-refreshing pipeline aggregating regional support metrics |
| **Streamlit Dashboard** | Live Support Ops Dashboard deployed in Snowflake |
| **Semantic View + Agent** | Self-service natural language support analytics via Snowflake Intelligence |

### Cleanup

To remove objects created during this lab only:

```sql
USE ROLE ACCOUNTADMIN;
DROP DYNAMIC TABLE IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD;
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS;
DROP STREAMLIT IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD;
```

To remove everything:

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS PAWCORE_ANALYTICS;
DROP WAREHOUSE IF EXISTS PAWCORE_DEMO_WH;
DROP API INTEGRATION IF EXISTS github_api;
```

### Related Resources
- [GitHub Repository](https://github.com/calebaalexander/HandsOnLabs)
- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/ui-snowsight-cortex-code)
- [Dynamic Tables Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-about)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/snowflake-intelligence)
