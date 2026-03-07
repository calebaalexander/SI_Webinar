# Intro to Cortex Code UI | Hands-On Lab

> **DISCLAIMER:** PawCore is a fictional company. All data, names, metrics, and scenarios in this lab are simulated for demonstration purposes only. Nothing here represents real customer data, real products, or real business outcomes.

---

## Tab 1: Why Are We Here?

To learn about **Cortex Code in Snowsight**, the AI coding assistant built directly into Snowflake's web interface. In this lab, you'll use the Cortex Code side panel to load data, diagnose errors from screenshots, build a Snowflake Notebook, create a Dynamic Table pipeline, deploy a Streamlit application, and launch a Snowflake Intelligence agent — all without leaving your browser.

> **Prerequisites:** This lab assumes Cortex Code is already enabled and running in your Snowflake environment. If the CoCo panel does not appear in Snowsight, refer to the **Setup & Install video** linked in the video description before proceeding.

### Structure of the Session
1. **Getting Started** — Log in, open the Cortex Code panel, load data via CoCo
2. **Exercise 1: Screenshot Error Repair** — Paste a screenshot of an error and watch CoCo fix it
3. **Exercise 2: Snowflake Notebook** — Build a support operations analysis notebook from natural language
4. **Exercise 3: Dynamic Table Pipeline** — Operationalize support metrics as an auto-refreshing pipeline
5. **Exercise 4: Streamlit Application** — Build and deploy a live support ops dashboard from a single prompt
6. **Exercise 5: Semantic View & Intelligence Agent** — Create self-service support analytics with Cortex Analyst

### Key Concepts

| Concept | What It Is |
|---------|------------|
| **Cortex Code Panel** | The AI assistant side panel in Snowsight. Ask questions, generate SQL, and build objects using natural language. |
| **Screenshot Repair** | Paste a screenshot of an error into the CoCo panel. CoCo reads the image, diagnoses the issue, and generates the fix. |
| **Snowflake Notebooks** | Interactive notebooks that run directly in Snowflake. CoCo can create, edit, and debug notebook cells. |
| **Dynamic Tables** | Declarative tables that auto-refresh when source data changes. Define the query once, Snowflake handles the pipeline. |
| **Streamlit in Snowflake** | Build and deploy interactive web applications directly inside Snowflake with no external infrastructure. |
| **Snowflake Intelligence** | A conversational AI chat interface built on Cortex Agents. Lets users explore data through conversation. |

### Use Case: Support Ops Readiness

The CLI demo asks the **strategic** question: *"Is PawCore ready to launch SmartCollar V2?"*

This UI demo asks the **operational** question: *"Is Marcus's support team ready for the volume that V2 will bring?"*

Same company, same data — different lens. Marcus needs to understand ticket patterns, severity trends, customer sentiment signals, and device telemetry correlations to know where his team is stretched thin before V2 launches.

---

## Tab 2: Getting Started

**Time: ~10 minutes**

### Step 1: Log in to Snowsight

1. Open your browser and navigate to your Snowflake account URL
2. Log in with your credentials
3. Ensure you are using the **ACCOUNTADMIN** role (or a role with sufficient privileges)

### Step 2: Open Cortex Code

1. Click **Projects** in the left sidebar
2. Select **Workspaces** from the dropdown menu
3. Click **+ Workspace** to create a new workspace (or open an existing one)
4. Inside your workspace, click the **+** button in the tab bar (top-right)
5. Select **SQL file**
6. The **Cortex Code AI assistant panel** appears on the right side

> **Tip:** The Cortex Code panel is context-aware — it knows which project, database, and files you're working with.

### Step 3: Load PawCore Data via Cortex Code

Unlike the CLI, Cortex Code in the UI cannot fetch files from external URLs. The way to get SQL scripts into Snowsight is to **copy and paste** them into a worksheet. Once pasted, you can either ask CoCo to execute the script or click "Run All" manually.

1. Open the **CoCo_PawCore_Setup.sql** script from the GitHub repo:
   - `https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql`
2. **Copy the full script** and **paste it into your SQL worksheet**
3. In the Cortex Code panel, type:

```
Execute this setup script in the worksheet. Proceed autonomously — allow all statements in PAWCORE_ANALYTICS.
```

4. CoCo will parse and execute each statement. You'll see a **permission prompt** — choose "Allow all non-read SQL" to speed things up.
5. The script will:
   - Create the `PAWCORE_ANALYTICS` database with 6 schemas (using IF NOT EXISTS)
   - Create an API integration with the public GitHub repo
   - Create a Git Repository object pointing to `https://github.com/calebaalexander/HandsOnLabs.git`
   - Copy all data files from the Git repo into an internal Snowflake stage
   - Create tables and load data (skips if data already exists)
   - Set up a Cortex Search Service for document search

> **Note:** This script is non-destructive. If you already have a PAWCORE_ANALYTICS database from a previous demo, all existing objects are preserved.

> **Note:** Cortex Code in the UI cannot fetch external URLs directly. You must paste the SQL into the worksheet first, then ask CoCo to execute it.

> **What you should see:** CoCo processes each statement sequentially and reports progress. The full script takes 2-3 minutes.

---

#### Alternative: Run Manually

If you prefer not to use CoCo for the setup, you can paste the script and click **"Run All"** in the worksheet, or clone the repo locally:

```bash
git clone https://github.com/calebaalexander/HandsOnLabs.git
```

Then copy `HandsOnLabs/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql` into a worksheet and run it.

---

### Step 4: Verify Data Loaded

In the Cortex Code panel, type:

```
Show me row counts for all tables in PAWCORE_ANALYTICS
```

**What you should see:**

| Table | Expected Rows |
|-------|--------------|
| DEVICE_DATA.TELEMETRY | ~21,000 |
| MANUFACTURING.QUALITY_LOGS | ~800+ |
| SUPPORT.CUSTOMER_REVIEWS | ~1,500+ |
| SUPPORT.SLACK_MESSAGES | ~37 |
| SUPPORT.SUPPORT_TICKETS | ~240 (V1 issues) |
| SUPPORT.V2_BETA_FEEDBACK | ~120 (V2 beta ratings) |
| UNSTRUCTURED.PARSED_CONTENT | 1+ |

---

## Tab 3: Exercise 1 — Screenshot Error Repair

**Objective:** Demonstrate that Cortex Code can read screenshots — paste an image of an error and CoCo diagnoses and fixes it.

**Time: ~5 minutes**

**Background:** PawCore's CX team tries to run SQL queries to understand their support ticket load but keeps hitting errors. They don't know SQL well enough to debug them. CoCo to the rescue.

---

### Task 1: Stage the Broken Query (1 min)

Copy and paste this **intentionally broken** SQL into your worksheet:

```sql
SELECT region, severity, COUNT(*) as tiket_count,
FROM PAWCORE_ANALYTICS.SUPORT.SUPPORT_TICKETS
GROUP BY region, severity
ORDER BY tiket_count DES;
```

Run it. You will get an error.

> **What's wrong:** Three bugs are hidden in this query:
> 1. `tiket_count` — should be `ticket_count` (missing C)
> 2. `SUPORT` — should be `SUPPORT`
> 3. `DES` — should be `DESC`

---

### Task 2: Screenshot the Error (1 min)

1. Take a **screenshot** of the error message in Snowsight (Cmd+Shift+4 on Mac, Win+Shift+S on Windows)
2. Save the screenshot to your desktop or clipboard

> **Tip:** Capture both the query and the error message in the screenshot for best results.

---

### Task 3: Paste into CoCo and Fix (3 min)

1. Click into the Cortex Code panel
2. **Paste the screenshot** directly into the chat input (Cmd+V / Ctrl+V)
3. Add a message:

```
Fix this error
```

4. CoCo will:
   - Read the screenshot image
   - Identify the SQL errors (alias typo, schema name, sort order)
   - Generate corrected SQL
5. Run the corrected SQL — success!

> **Key Feature:** Cortex Code can read images. Paste error screenshots, broken queries, even UI error dialogs — CoCo diagnoses the problem and generates the fix. This is transformative for teams that aren't SQL experts.

---

### Validation Checklist — Exercise 1

- [ ] Ran the broken SQL and got an error
- [ ] Took a screenshot of the error
- [ ] Pasted the screenshot into the CoCo panel
- [ ] CoCo identified all three errors
- [ ] Corrected SQL runs successfully

---

## Tab 4: Exercise 2 — Snowflake Notebook: Support Ops Analysis

**Objective:** Have CoCo create a Snowflake Notebook that analyzes PawCore's support operations readiness, then demonstrate screenshot error repair on a notebook cell.

**Time: ~8 minutes**

**Background:** Marcus Thompson needs a repeatable analysis of his team's support operations — ticket volumes, severity patterns, customer frustration signals, and device issues driving support calls. A Snowflake Notebook is the perfect format for this kind of multi-dimensional exploration. Notebooks are interactive, multi-cell documents that run directly inside Snowflake — think of them as a lab journal for data where you write SQL or Python in individual cells, run them one at a time or all at once, and the results stay inline so you can see the full story top to bottom.

---

### Task 1: Create the Notebook (5 min)

In the Cortex Code panel:

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

Create and run the notebook.
```

**What you should see:** A multi-cell notebook showing which regions have support operations under control and which are stretched thin.

---

### Task 2: Break and Fix a Cell (3 min)

Now let's demonstrate screenshot repair in a notebook context.

#### Step 1: Intentionally break a cell

Edit Cell 5 to introduce an error — change a column name:

```sql
-- Change "critical_tickets" to "critical_count" (doesn't exist)
```

Run the cell. It will fail.

#### Step 2: Screenshot the error

Take a screenshot of the failed notebook cell showing the error output.

#### Step 3: Fix with CoCo

Paste the screenshot into the CoCo panel:

```
Fix this notebook cell error
```

CoCo reads the screenshot, identifies the wrong column name, and provides the corrected SQL.

> **Key Feature:** The screenshot repair pattern works everywhere in Snowsight — SQL worksheets, notebooks, Streamlit errors, even the Activity panel. One interaction pattern, many surfaces.

---

### Validation Checklist — Exercise 2

- [ ] Notebook created with 5 cells
- [ ] All cells execute successfully with meaningful results
- [ ] Sentiment analysis shows regional patterns
- [ ] Support ops summary shows SUPPORT_READY flags
- [ ] Screenshot error repair worked on the notebook cell

---

## Tab 5: Exercise 3 — Dynamic Table Pipeline

**Objective:** Operationalize the notebook analysis as an auto-refreshing Dynamic Table. Support tickets come in constantly — Marcus needs metrics that update themselves.

**Time: ~5 minutes**

**Background:** Marcus says: *"Great analysis, but tickets come in every hour. I need this data live — not a report I re-run manually every Monday."* A Dynamic Table is the answer — you write a query that defines the result set you want, attach a refresh interval (called a "target lag"), and Snowflake handles the rest. When new tickets get filed, new reviews come in, or new telemetry readings land, the table refreshes automatically. No Airflow, no cron jobs, no orchestration layer.

---

### Task 1: Create the Dynamic Table (3 min)

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

**What you should see:** CoCo generates a `CREATE OR REPLACE DYNAMIC TABLE` statement with the proper joins, aggregations, AI sentiment function, and target lag configuration.

---

### Task 2: Verify the Pipeline (2 min)

#### Step 1: Query the Dynamic Table

```
Show me all rows from the SUPPORT_OPS_DASHBOARD dynamic table
```

**What you should see:** One row per region with aggregated support ops metrics and the SUPPORT_READY flag.

#### Step 2: Check refresh status

```
Show me the refresh history for the SUPPORT_OPS_DASHBOARD dynamic table
```

> **Key Feature:** Dynamic Tables eliminate ETL scheduling. Define the query once, and Snowflake automatically refreshes the results when upstream data changes. The Streamlit app we build next will read from this table — always showing current data.

---

### Validation Checklist — Exercise 3

- [ ] Dynamic Table created with proper target lag
- [ ] Query returns regional support ops metrics
- [ ] SUPPORT_READY flag correctly identifies ready regions
- [ ] Refresh history shows the table is actively managed

---

## Tab 6: Exercise 4 — Build a Streamlit Application

**Objective:** Have CoCo build and deploy a Streamlit in Snowflake application that reads from the Dynamic Table — creating a live, auto-refreshing support operations dashboard.

**Time: ~8 minutes**

**Background:** Marcus wants a dashboard his CX team can check every morning before standup — not a spreadsheet, not a notebook, but a real application. CoCo builds it from a single prompt.

---

### Task 1: Generate the App (5 min)

In the Cortex Code panel:

```
Build a Streamlit in Snowflake app called "Support Ops Dashboard"
in PAWCORE_ANALYTICS.SUPPORT.

The app should:
1. Read from the SUPPORT_OPS_DASHBOARD dynamic table
2. Show a header: "SmartCollar — Support Operations Dashboard"
3. Display regional readiness cards with color coding:
   - Green for SUPPORT_READY = TRUE
   - Red for SUPPORT_READY = FALSE
4. Show a bar chart comparing total_tickets vs critical_tickets
   by region
5. Show a metrics table with all columns including avg_sentiment,
   low_battery_events, and low_rating_count
6. Add a "Risk Assessment" section that flags regions where
   critical_tickets are high or avg_sentiment is negative

Use the Snowpark session for data access. Deploy the app.
```

**What you should see:** CoCo generates a complete Streamlit Python file and creates the app in Snowflake.

---

### Task 2: Open and Interact (2 min)

1. Navigate to **Projects** → **Streamlit** in Snowsight
2. Open the **Support Ops Dashboard**
3. Interact with the dashboard:
   - Review regional readiness cards
   - Check the ticket severity bar chart
   - Read the risk assessment

---

### Task 3: Iterate with CoCo (1 min)

Ask CoCo to enhance the app:

```
Add a section to the Streamlit app that shows the top 5 most critical
support tickets from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS,
filtered by the region selected in a sidebar dropdown.
```

> **Key Feature:** CoCo builds full applications from natural language — not just SQL queries. The app reads from the Dynamic Table, so it's always current. And you can iterate on the design conversationally.

---

### Validation Checklist — Exercise 4

- [ ] Streamlit app created and deployed in Snowflake
- [ ] Dashboard shows regional readiness with color coding
- [ ] Bar chart displays ticket severity comparisons
- [ ] Risk assessment section flags problem regions
- [ ] App reads from the Dynamic Table (auto-refreshing data)

---

## Tab 7: Exercise 5 — Semantic View & Intelligence Agent

**Objective:** Create a Semantic View and Cortex Agent so Marcus can ask ad-hoc questions about support operations in natural language through Snowflake Intelligence.

**Time: ~4 minutes**

---

### Task 1: Create the Semantic View (2 min)

In the Cortex Code panel:

```
Create a Cortex Analyst semantic view called
PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS for support operations analysis.
Proceed autonomously.

Include these tables:
1. SUPPORT.SUPPORT_TICKETS — ticket volume, severity, and status by region
2. SUPPORT.CUSTOMER_REVIEWS — customer ratings and review text
3. DEVICE_DATA.TELEMETRY — device sensor readings and battery levels
4. SUPPORT.V2_BETA_FEEDBACK — beta tester feedback on V2

Define metrics: total_tickets, critical_ticket_count, avg_rating,
avg_battery_level, low_battery_event_count, avg_beta_rating.

Execute the SQL.
```

---

### Task 2: Create the Agent & Test in Intelligence (2 min)

```
Create a Cortex Agent called PAWCORE_SUPPORT_OPS_AGENT in PAWCORE_ANALYTICS.SEMANTIC.
Proceed autonomously and execute all SQL including grants.

Use the SUPPORT_OPS semantic view and the PAWCORE_DOCUMENT_SEARCH
Cortex Search service. Grant USAGE to PUBLIC. Use automatic model selection.

Execute all SQL.
```

Then open **Snowflake Intelligence** (AI & ML → Snowflake Intelligence) and test:

```
Which region has the highest support ticket load and what's driving it?
```

```
Is there a correlation between low battery events and critical support tickets?
```

> **Key Feature:** The full pipeline is now connected: raw data → Dynamic Table → Streamlit dashboard → Intelligence agent. Marcus can check the dashboard for a quick pulse, or dive into Snowflake Intelligence for deeper investigation.

---

### Validation Checklist — Exercise 5

- [ ] Semantic View created with support ops metrics
- [ ] Cortex Agent created and granted to PUBLIC
- [ ] Agent visible in Snowflake Intelligence
- [ ] Intelligence answers support operations questions accurately

---

## Congratulations!

You've completed the **Intro to Cortex Code UI** Hands-On Lab.

### What You Built in ~33 Minutes

| Asset | What It Does |
|-------|-------------|
| **Screenshot Error Repair** | Diagnosed and fixed SQL errors from a pasted screenshot |
| **Snowflake Notebook** | Interactive support ops analysis with AI sentiment scoring |
| **Dynamic Table** | Auto-refreshing pipeline aggregating regional support metrics |
| **Streamlit Dashboard** | Live Support Ops Dashboard deployed in Snowflake |
| **Semantic View + Agent** | Self-service natural language support analytics via Snowflake Intelligence |

### The Pipeline Story

```
Raw Data (7 tables)
  → Notebook (explore support patterns & telemetry correlations)
    → Dynamic Table (operationalize as auto-refresh pipeline)
      → Streamlit App (visual dashboard for daily standup)
      → Intelligence Agent (conversational analytics for ad-hoc investigation)
```

### What You Can Do Next
- Refine the Semantic View based on real user questions
- Add more metrics to the Dynamic Table as new data sources arrive
- Extend the Streamlit app with additional pages (Engineering view, Finance view)
- Create additional Cortex Agents for other teams
- Try the **Intro to CoCo CLI** lab for the terminal-based experience with skills and automation

### Cleanup

To remove objects created during this lab only (preserves shared data):

```sql
USE ROLE ACCOUNTADMIN;
-- Dynamic Table
DROP DYNAMIC TABLE IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD;
-- Semantic View
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS;
-- Streamlit App (adjust name if different)
DROP STREAMLIT IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD;
-- Cortex Agent (adjust name if different)
-- DROP CORTEX AGENT IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_SUPPORT_OPS_AGENT;
-- Notebook (adjust name if different)
-- DROP NOTEBOOK IF EXISTS PAWCORE_ANALYTICS.SUPPORT."Support Ops Readiness Analysis";
```

To remove **everything** (only if no other demos depend on this data):

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS PAWCORE_ANALYTICS;
DROP WAREHOUSE IF EXISTS PAWCORE_DEMO_WH;
DROP API INTEGRATION IF EXISTS github_api;
```

---

### Tips for Success
1. **Screenshot everything** — CoCo reads images. Error dialogs, broken charts, failed cells — paste them in.
2. **Build the pipeline** — Notebook → Dynamic Table → App creates a compelling end-to-end story.
3. **Iterate conversationally** — Ask CoCo to modify the Streamlit app, add cells to the notebook, or refine the semantic view.
4. **Context matters** — The Cortex Code panel knows where you are in Snowsight. Work in the right database/schema.
5. **Show the SQL** — Builds trust with technical stakeholders who want to verify AI-generated answers.
