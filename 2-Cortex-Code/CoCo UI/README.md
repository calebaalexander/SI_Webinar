# Intro to Cortex Code UI | Hands-On Lab

> **DISCLAIMER:** PawCore is a fictional company. All data, names, metrics, and scenarios in this lab are simulated for demonstration purposes only. Nothing here represents real customer data, real products, or real business outcomes.

---

## Tab 1: Why Are We Here?

To learn about **Cortex Code in Snowsight**, the AI coding assistant built directly into Snowflake's web interface. In this lab, you'll use the Cortex Code side panel to load data, diagnose errors from screenshots, build a Snowflake Notebook, create a Dynamic Table pipeline, deploy a Streamlit application, and launch a Snowflake Intelligence agent — all without leaving your browser.

> **Prerequisites:** This lab assumes Cortex Code is already enabled and running in your Snowflake environment. If the CoCo panel does not appear in Snowsight, refer to the **Setup & Install video** linked in the video description before proceeding.

### Structure of the Session
1. **Getting Started** — Log in, open the Cortex Code panel, load data via CoCo
2. **Exercise 1: Three Ways to Fix Code** — Fix errors using natural language, the Fix button, and screenshot repair
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

## Tab 3: Exercise 1 — Three Ways to Fix Code

**Objective:** Demonstrate three escalating methods for fixing code with CoCo — natural language, the inline Fix button, and screenshot repair — plus the Explain button for code comprehension.

**Time: ~8 minutes**

**Background:** PawCore's CX team tries to run SQL queries to understand their support ticket load but keeps hitting errors. This exercise shows three different ways CoCo can help, from simplest to most powerful.

---

### Task 1: Stage the Broken Query (1 min)

Copy and paste this **intentionally broken** SQL into your worksheet:

```sql
SELECT region, severity, COUNT(*) as tiket_count
FROM PAWCORE_ANALYTICS.SUPORT.SUPPORT_TICKETS
GROUP BY region, severity
ORDER BY tiket_count DES;
```

> **What's wrong:** Three errors are hidden in this query:
> 1. `DES` — should be `DESC`
> 2. `SUPORT` — should be `SUPPORT`
> 3. `severity` — should be `PRIORITY` (the actual column name in the table)
>
> Plus a cosmetic issue: `tiket_count` should be `ticket_count` — but the compiler won't catch this one.

---

### Task 2: Use the Explain Button (1 min)

Before fixing anything, try the **Explain** feature:

1. **Select the entire query** in the worksheet
2. The **inline toolbar** appears: Add to Chat, Explain, Quick Edit, Format
3. Click **Explain**
4. CoCo returns a plain-English explanation of what the query does — the aggregation, grouping, and sort

> **Key Feature:** If you inherited code from someone who left the team, you don't have to reverse-engineer it. Highlight and click Explain.

---

### Task 3: Method 1 — Natural Language Fix (1 min)

Fix the `DES` error using natural language:

1. **Select `DES`** on line 4
2. The inline toolbar appears — click **"Add to Chat"**
3. In the CoCo panel, type:

```
Fix this — it should be DESC
```

4. CoCo returns the corrected line. **Accept the change.**

> **Why this method:** You can see the problem and know the fix. Just tell CoCo in plain English.

---

### Task 4: Method 2 — Fix Button (1 min)

Fix the `SUPORT` error using the inline Fix button:

1. **Run the query** — you'll get an error: `Schema 'PAWCORE_ANALYTICS.SUPORT' does not exist or not authorized.`
2. A **Fix** button appears below the error message
3. **Click Fix** — CoCo shows a diff view (red/green changes)
4. CoCo identifies the typo: `SUPORT` → `SUPPORT`
5. Click **"Keep all in file"** to accept

> **Why this method:** You don't even need to diagnose the problem. The Fix button reads the compiler error and resolves it automatically.

---

### Task 5: Method 3 — Screenshot Fix (2 min)

Fix the `severity` → `PRIORITY` error using a screenshot:

1. **Run the query** — you'll get: `invalid identifier 'SEVERITY'`
2. **Screenshot the entire screen** — query and error together (Cmd+Shift+4 on Mac, Win+Shift+S on Windows)
3. **Paste the screenshot** into the CoCo panel and type:

```
Fix this error
```

4. CoCo reads the image, checks the actual table columns, and finds that the table uses `PRIORITY`, not `severity`
5. **Accept the change.** Run the query — success! 8 rows returned.

> **Why this method:** When you don't know the right column name, CoCo can introspect the table and figure it out from a screenshot.

---

### Task 6: Bonus — Screenshot Catches What Compilers Can't (1 min)

The query works, but notice the column header says `TIKET_COUNT` — a cosmetic typo the compiler ignored.

1. **Screenshot the successful results** showing the `TIKET_COUNT` header
2. **Paste into CoCo:**

```
Fix the typo in this query
```

3. CoCo reads the image, spots `tiket_count`, corrects it to `ticket_count`
4. Accept and re-run — clean column: `TICKET_COUNT`

> **Key Feature:** The screenshot method catches issues no compiler ever will — wrong columns, cosmetic typos, misleading aliases. One gesture: screenshot, paste, fix.

---

### Validation Checklist — Exercise 1

- [ ] Used the Explain button to understand the query
- [ ] Fixed `DES` → `DESC` using natural language (Add to Chat)
- [ ] Fixed `SUPORT` → `SUPPORT` using the Fix button
- [ ] Fixed `severity` → `PRIORITY` using a screenshot
- [ ] Fixed `tiket_count` → `ticket_count` using a screenshot of results
- [ ] Final query runs successfully with clean column names

---

## Tab 4: Exercise 2 — Snowflake Notebook: Support Ops Analysis

**Objective:** Have CoCo create a Snowflake Notebook that analyzes PawCore's support operations readiness, then use the screenshot method to fix a cell that returns no results.

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

Create and run the notebook. Continue autonomously.
```

**What you should see:** A multi-cell notebook with ticket breakdown, customer frustration signals, telemetry patterns, AI sentiment, and a composite readiness score.

---

### Task 2: Fix the "No Results" Cell with a Screenshot (3 min)

After the notebook runs, check the cells. Cell 4 (the telemetry anomalies cell) may return **"Query produced no results"** — the query ran clean with no error, but zero rows came back. This is the kind of issue a compiler will never catch.

1. **Screenshot Cell 4** — capture both the query and the "Query produced no results" output
2. **Paste the screenshot** into the CoCo panel:

```
This cell returned no results. Fix the query so it returns data.
```

3. CoCo reads the image, checks the actual column values in the table, and finds that the WHERE filter doesn't match the data
4. **Accept the corrected query.** Re-run Cell 4 — results appear.

> **Key Feature:** Same pattern from Exercise 1 — screenshot, paste, fix. The screenshot method works on notebooks too, and catches issues that produce no error message at all.

---

### Validation Checklist — Exercise 2

- [ ] Notebook created with multiple analysis cells
- [ ] All cells execute successfully with meaningful results
- [ ] Sentiment analysis shows regional patterns
- [ ] Support ops summary shows SUPPORT_READY flags
- [ ] Screenshot fix resolved the Cell 4 "no results" issue

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

Include these tables:
1. SUPPORT.SUPPORT_TICKETS — ticket volume, severity, and status by region
2. SUPPORT.CUSTOMER_REVIEWS — customer ratings and review text
3. DEVICE_DATA.TELEMETRY — device sensor readings and battery levels
4. SUPPORT.V2_BETA_FEEDBACK — beta tester feedback on V2

Define metrics: total_tickets, critical_ticket_count, avg_rating,
avg_battery_level, low_battery_event_count, avg_beta_rating.

IMPORTANT: Do NOT use "data_type" in the YAML — it is not a valid
semantic view field and will cause parsing errors. Continue autonomously.
```

---

### Task 2: Create the Agent & Test in Intelligence (2 min)

```
Create a Cortex Agent PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_SUPPORT_OPS_AGENT
using model 'claude-haiku-4-5' with tools for
PAWCORE_ANALYTICS.SEMANTIC.SUPPORT_OPS semantic view and the Cortex Search
service PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH. Run
SHOW CORTEX SEARCH SERVICES IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC to confirm
it exists. If the search service doesn't exist, STOP and tell me — the
setup script should have created it. Do NOT create it yourself. Add
orchestration and response instructions so the agent knows its role, uses
the right tool for each question type, and responds concisely with bullet
points and regional breakdowns. Grant USAGE on the agent to PUBLIC.
Continue autonomously.
```

Then navigate to **AI & ML → Agents → Snowflake Intelligence tab**. Click **"Add existing agent"**, search for `PAWCORE_SUPPORT_OPS_AGENT`, select it, and confirm. Then switch to **Snowflake Intelligence** and test:

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
| **Three Fix Methods** | Fixed errors using natural language, Fix button, and screenshot repair |
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
