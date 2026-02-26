# Intro to Cortex Code UI | Hands-On Lab

---

## Tab 1: Why Are We Here?

To learn about **Cortex Code in Snowsight**, the AI coding assistant built directly into Snowflake's web interface. Cortex Code's side panel lets you explore data, run AI-powered analysis, build Semantic Views, and create Intelligence agents — all without leaving your browser.

### Structure of the Session
1. **Getting Started** — Log in, load data, and open the Cortex Code panel
2. **Exercise 1: Explore Data with AI-Powered Analysis** — Use AI SQL functions to analyze customer experience
3. **Exercise 2: Build a Semantic View & Intelligence Agent** — Create self-service analytics with Cortex Analyst
4. **Exercise 3: Document Search & AI Functions Deep Dive** — Search unstructured data and generate insights

### Key Concepts

| Concept | What It Is |
|---------|------------|
| **Cortex Code Panel** | The AI assistant side panel in Snowsight. Ask questions, generate SQL, and build objects using natural language. |
| **AI SQL Functions** | Built-in Cortex functions like SENTIMENT, SUMMARIZE, and COMPLETE that add AI intelligence to standard SQL queries. |
| **Cortex Search** | AI-powered semantic search across unstructured documents (PDFs, text files) stored in Snowflake. |
| **Cortex Analyst** | AI-powered natural language to SQL. Users ask questions in plain English, Cortex Analyst generates and runs SQL. |
| **Snowflake Intelligence** | A conversational AI chat interface built on Cortex Agents. Lets users explore data through conversation. |

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

### Step 3: Load PawCore Data

**Choose your setup path:**

#### Option A: Snowflake Git Integration (Recommended)

1. Open a **new SQL Worksheet** in Snowsight
2. Paste the full **CoCo_PawCore_Setup.sql** script into the worksheet
   - You can find this script in the GitHub repo: `https://github.com/calebaalexander/HandsOnLabs`
   - Navigate to the `setup/` or `02_Scripts/` folder and copy the contents of `CoCo_PawCore_Setup.sql`
3. Click **"Run All"** (or select all and run)
4. The script will:
   - Create the `PAWCORE_ANALYTICS` database with 6 schemas (using IF NOT EXISTS)
   - Create an API integration with the public GitHub repo
   - Create a Git Repository object pointing to `https://github.com/calebaalexander/HandsOnLabs.git`
   - Copy all data files from the Git repo into an internal Snowflake stage
   - Create tables and load data (skips if data already exists)
   - Set up a Cortex Search Service for document search
   - Create a Semantic View

> **Note:** This script is non-destructive. If you already have a PAWCORE_ANALYTICS database from a previous demo, all existing objects are preserved.

> **What you should see:** Each statement will show a green checkmark as it completes. The full script takes 2-3 minutes.

#### Option B: Download from GitHub and Upload Manually

1. Go to **https://github.com/calebaalexander/HandsOnLabs**
2. Click the green **"Code"** button → **"Download ZIP"**
3. Extract the ZIP file on your computer
4. In a new SQL Worksheet, run the database and stage creation SQL:
   ```sql
   USE ROLE ACCOUNTADMIN;
   CREATE WAREHOUSE IF NOT EXISTS PAWCORE_DEMO_WH
       WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 300 AUTO_RESUME = TRUE;
   USE WAREHOUSE PAWCORE_DEMO_WH;
   CREATE DATABASE IF NOT EXISTS PAWCORE_ANALYTICS;
   USE DATABASE PAWCORE_ANALYTICS;
   CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
   CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
   CREATE SCHEMA IF NOT EXISTS SUPPORT;
   CREATE SCHEMA IF NOT EXISTS WARRANTY;
   CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
   CREATE SCHEMA IF NOT EXISTS SEMANTIC;
   USE SCHEMA SEMANTIC;
   CREATE STAGE IF NOT EXISTS PAWCORE_DATA_STAGE
       DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
   ```
5. Upload the data files to the stage:
   - In Snowsight: **Data** → **Databases** → **PAWCORE_ANALYTICS** → **SEMANTIC** → **Stages** → **PAWCORE_DATA_STAGE**
   - Click **"+ Files"** and upload files from the extracted `data/` subfolders
   - Upload to matching subfolders: `Telemetry/`, `Manufacturing/`, `Document_Stage/`, `HR/`
6. Run the **table creation and COPY INTO** sections of the setup SQL (skip the Git integration section marked in the script)

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
| UNSTRUCTURED.PARSED_CONTENT | 7 |

---

## Tab 3: Exercise 1 — Explore Data with AI-Powered Analysis

**Objective:** Use the Cortex Code panel and AI SQL functions to analyze PawCore's customer experience data and uncover insights for the V2 launch.

**Time: ~20 minutes**

**Background:** PawCore's Head of Customer Experience, **Marcus Thompson**, wants to understand how customers feel about PawCore products across channels. He needs AI-powered insights to help the CX team proactively address issues and identify upsell opportunities for SmartCollar V2.

---

### Task 1: Data Discovery (5 min)

Use the Cortex Code panel to explore PawCore's data.

#### Step 1: Explore the tables

In the Cortex Code panel, type:

```
Show me the structure of the customer_reviews table in PAWCORE_ANALYTICS.SUPPORT
```

**What you should see:** Column names, data types, and sample values including device_id, lot_number, region, rating, review_text, and review_date.

#### Step 2: Get an overview

```
How many customer reviews do we have by region? Show a breakdown.
```

#### Step 3: Preview the data

```
Show me 10 sample rows from the customer_reviews table. Include the review text.
```

> **Tip:** Notice how Cortex Code generates and runs SQL for you. You can see the actual SQL it wrote in the worksheet.

---

### Task 2: AI-Powered Sentiment Analysis (10 min)

Snowflake's built-in AI functions let you analyze text data directly in SQL. Let's use them on customer reviews.

#### Step 1: Run sentiment analysis

In the Cortex Code panel:

```
Run sentiment analysis on our customer reviews using SNOWFLAKE.CORTEX.SENTIMENT
and show the average sentiment score by region. Include the number of reviews
per region.
```

**What you should see:** A table showing each region with its average sentiment score (range: -1 to 1) and review count.

#### Step 2: Identify themes

```
Use SNOWFLAKE.CORTEX.SUMMARIZE to summarize the main themes in our customer
reviews. Group by region so we can see what each region's customers are
talking about.
```

#### Step 3: Find feature mentions

```
Which product features get the most positive vs negative mentions in customer
reviews? Use SNOWFLAKE.CORTEX.SENTIMENT on individual reviews and group the
results by the main topics mentioned.
```

> **Key Feature:** Notice how AI SQL functions run *inside* standard SQL queries. There's no separate tool or export needed — the AI analysis happens right where your data lives.

---

### Task 3: Cross-Data Exploration (5 min)

Let's connect insights across different data sources.

#### Step 1: Analyze internal communications

```
What are the most discussed topics in our Slack channels?
Show me a breakdown of message counts by channel from
PAWCORE_ANALYTICS.SUPPORT.SLACK_MESSAGES
```

#### Step 2: Compare internal vs external sentiment

```
Compare the sentiment of customer reviews with the sentiment of internal
Slack messages. Use SNOWFLAKE.CORTEX.SENTIMENT on both tables and show
the average sentiment side by side.
```

**What you should see:** A comparison showing whether internal team mood aligns with or diverges from customer sentiment.

---

### Validation Checklist — Exercise 1

- [ ] Explored table structures and row counts
- [ ] Ran SENTIMENT analysis on customer reviews by region
- [ ] Used SUMMARIZE to identify review themes
- [ ] Compared sentiment across customer reviews and internal Slack messages
- [ ] Understand how AI SQL functions integrate into standard SQL queries

---

## Tab 4: Exercise 2 — Build a Semantic View & Intelligence Agent

**Objective:** Create a Semantic View for Cortex Analyst, build a Cortex Agent, and test the Snowflake Intelligence chat experience.

**Time: ~20 minutes**

---

### Task 1: Create a Semantic View (8 min)

#### Step 1: Understand the goal

A Semantic View teaches Cortex Analyst how to interpret your data. It defines tables, columns, relationships, metrics, and business-friendly descriptions so users can ask questions in plain English.

#### Step 2: Generate the Semantic View

In the Cortex Code panel:

```
Create a Cortex Analyst semantic view for PAWCORE_ANALYTICS. Proceed autonomously.

Include these tables:
1. DEVICE_DATA.TELEMETRY — device sensor readings
2. MANUFACTURING.QUALITY_LOGS — QC test results
3. SUPPORT.CUSTOMER_REVIEWS — customer ratings and feedback
4. SUPPORT.SLACK_MESSAGES — internal team communications

Define relationships:
- TELEMETRY ↔ QUALITY_LOGS on lot_number
- CUSTOMER_REVIEWS ↔ TELEMETRY on device_id and lot_number

Add metrics for customer experience analysis:
- avg_rating, satisfaction_score, avg_sentiment
- pass_rate, failure_count
- avg_battery_level, device_count

Use CREATE SEMANTIC VIEW SQL syntax. Execute the SQL.
```

#### Step 3: Test it

```
Using the semantic view, answer: "Which region has the highest customer satisfaction and why?"
Show me the natural language question, the SQL generated, and the results.
```

---

### Task 2: Create & Test a Cortex Agent (5 min)

#### Step 1: Create the agent

```
Create a Cortex Agent for PawCore's customer experience team. Proceed
autonomously and execute all SQL including grants.

The agent should:
1. Be named "PawCore CX Analyst"
2. Use the semantic view we just created
3. Include the Cortex Search Service (PAWCORE_DOCUMENT_SEARCH) for document search
4. Have instructions oriented toward customer experience insights
5. Include sample CX questions
6. Grant USAGE to PUBLIC
7. Use automatic model selection

Execute all SQL.
```

#### Step 2: Test the agent

```
Test the PawCore CX Analyst with these questions:

1. "What regions have the strongest customer satisfaction — compare ratings?"
2. "How does device performance correlate with customer ratings by region?"
3. "What themes appear in reviews from our top-rated regions?"
```

---

### Task 3: Snowflake Intelligence Chat (7 min)

Now let's use the agent through Snowflake Intelligence — the conversational chat interface.

#### Step 1: Open Snowflake Intelligence

1. In Snowsight, click **"AI & ML"** in the left sidebar
2. Click **"Snowflake Intelligence"**
3. You should see the **PawCore CX Analyst** agent available
4. Click on it to open the chat interface

> **Note:** If you don't see the agent, verify the USAGE grant was applied: `GRANT USAGE ON CORTEX AGENT ... TO ROLE PUBLIC;`

#### Step 2: Run a conversational analysis

Try these questions in the Intelligence chat:

```
Give me a customer experience health check — compare satisfaction across regions
```

```
What should our CX team highlight as regional strengths this quarter?
```

```
Which region has the happiest customers and why?
```

> **Key Feature:** Snowflake Intelligence combines structured data queries (via Cortex Analyst) with document search (via Cortex Search) in a single conversational experience. Notice how it can reference both tables AND documents in its answers.

---

### Validation Checklist — Exercise 2

- [ ] Semantic View created with all 4 tables
- [ ] Cortex Analyst answers CX questions correctly
- [ ] Cortex Agent created and responding
- [ ] Agent accessible in Snowflake Intelligence
- [ ] Intelligence chat combines structured + unstructured data in answers

---

## Tab 5: Exercise 3 — Document Search & AI Functions Deep Dive

**Objective:** Use Cortex Search to find insights in unstructured documents and explore advanced AI SQL functions.

**Time: ~10 minutes**

---

### Task 1: Cortex Search (5 min)

PawCore's QC standards and internal documentation are indexed in the Cortex Search Service. Let's search them.

#### Step 1: Search QC documentation

In the Cortex Code panel:

```
Search our PawCore document search service for:
"What quality improvements were made after the 2024 review?"
```

**What you should see:** Relevant passages from the QC standards PDF about testing protocol updates.

#### Step 2: Search for launch protocols

```
Search PawCore documents for:
"What are the recommended testing protocols for new product launches?"
```

#### Step 3: Search internal communications

If Slack messages are indexed in the search service:

```
Search PawCore documents for:
"What did the team discuss about the V2 product timeline?"
```

> **Key Feature:** Cortex Search uses semantic understanding — it finds conceptually relevant results, not just keyword matches. "Quality improvements" will find passages about "enhanced testing protocols" even if those exact words aren't used.

---

### Task 2: AI SQL Functions Showcase (5 min)

Let's explore the breadth of AI SQL functions available in Snowflake.

#### Step 1: SENTIMENT — Tone analysis

```
Write and run a SQL query that uses SNOWFLAKE.CORTEX.SENTIMENT to analyze
the tone of the 10 most recent customer reviews. Show the review text,
rating, and sentiment score side by side.
```

#### Step 2: SUMMARIZE — Executive summaries

```
Write and run a SQL query that uses SNOWFLAKE.CORTEX.SUMMARIZE to create
a one-paragraph executive summary of all customer feedback for each region.
```

#### Step 3: COMPLETE — Generate action items

```
Using SNOWFLAKE.CORTEX.COMPLETE, generate a CX improvement action plan
based on a summary of our customer review data. The prompt should include
the average ratings by region and the top complaint themes.
```

> **Key Takeaway:** AI SQL functions turn Snowflake into an AI-native analytics platform. Sentiment analysis, summarization, and text generation all happen in SQL — no external APIs, no data movement, no additional tools.

---

### Validation Checklist — Exercise 3

- [ ] Successfully searched QC documentation with Cortex Search
- [ ] Search returned semantically relevant results
- [ ] Ran SENTIMENT on customer reviews with meaningful scores
- [ ] Used SUMMARIZE to generate regional feedback summaries
- [ ] Used COMPLETE to generate an AI-powered action plan

---

## Congratulations!

You've completed the **Intro to Cortex Code UI** Hands-On Lab.

### What You Accomplished
- Explored PawCore data using the Cortex Code panel in Snowsight
- Ran AI-powered sentiment analysis and summarization with AI SQL functions
- Created a Semantic View and Cortex Agent for self-service analytics
- Used Snowflake Intelligence for conversational data exploration
- Searched unstructured documents with Cortex Search
- Generated AI-powered insights and action plans

### What You Can Do Next
- Refine the Semantic View based on real user questions
- Create additional Cortex Agents for other teams (Engineering, Finance)
- Explore more AI SQL functions: EXTRACT_ANSWER, CLASSIFY_TEXT, TRANSLATE
- Try the **Intro to Cortex Code CLI** lab for the terminal-based experience with skills and automation

### Cleanup

To remove CoCo-specific objects only (preserves shared data for other demos):

```sql
USE ROLE ACCOUNTADMIN;
-- Drop semantic view created during this lab
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS;
-- Drop any Cortex Agents created during this lab
-- DROP AGENT IF EXISTS <your_agent_name>;
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
1. **Context matters** — The Cortex Code panel knows where you are in Snowsight. Work in the right database/schema.
2. **Iterate** — Ask a question, review the SQL, refine with follow-ups
3. **Combine tools** — AI SQL functions + Cortex Search + Cortex Analyst are more powerful together
4. **Show the SQL** — Builds trust with technical stakeholders who want to verify AI-generated answers
5. **Save queries** — Keep useful SQL in worksheets for future reference
