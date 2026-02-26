# Intro to Cortex Code CLI | Hands-On Lab

> **DISCLAIMER:** PawCore is a fictional company. All data, names, metrics, and scenarios in this lab are simulated for demonstration purposes only. Nothing here represents real customer data, real products, or real business outcomes.

---

## Tab 1: Why Are We Here?

To learn about **Cortex Code CLI**, the first truly Snowflake-native AI coding agent. Cortex Code turns complex data engineering, analytics, machine learning, and agent-building tasks into simple, natural language interactions with high accuracy.

### Structure of the Session
1. **Getting Started** — Install, authenticate, and load data
2. **Exercise 1: Build the PawCore Analytics Environment** — Set up data, create a Semantic View, and launch a Snowflake Intelligence agent
3. **Exercise 2: Master Cortex Code Skills** — Explore built-in skills and create a custom one
4. **Exercise 3: Generate Launch Documentation** — Produce stakeholder-ready reports and diagrams

### Key Concepts

| Concept | What It Is |
|---------|------------|
| **Cortex Analyst** | AI-powered natural language to SQL. Users ask questions in plain English, Cortex Analyst generates and runs SQL. |
| **Semantic Views** | A SQL-based data model layer that describes your tables, relationships, metrics, and business definitions to Cortex Analyst. |
| **Snowflake Intelligence** | A conversational AI chat interface built on Cortex Agents. Lets users explore data through conversation. |
| **Skills** | Reusable workflows packaged as markdown files that teach Cortex Code how to complete specific tasks consistently. |
| **Cortex Search** | AI-powered search across unstructured documents (PDFs, text files) stored in Snowflake. |

---

## Tab 2: Getting Started

**Time: ~10 minutes**

### Step 1: Download Use Case Context Files

Download the PawCore company context files that provide the business scenario for this lab:

- [**pawcore_company_brief.md**](pawcore_company_brief.md) — PawCore company profile and current growth phase
- [**pawcore_discovery_notes.md**](pawcore_discovery_notes.md) — Stakeholder meeting notes and success criteria

These files simulate real discovery artifacts you'd receive from a customer engagement. Save them to a folder you can easily access from your terminal.

### Step 2: Install Cortex Code CLI

Install Cortex Code CLI by running the following command in your terminal:

```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

This installs the `cortex` executable to `~/.local/bin` by default.

**Prerequisites:**
- macOS (Apple Silicon or Intel), Linux (Intel), or Windows Subsystem for Linux (WSL)
- Snowflake CLI installed
- Access to bash, zsh, or fish shell

### Step 3: Authenticate with Snowflake

Cortex Code requires a **Programmatic Access Token (PAT)** to connect to your Snowflake account.

1. **Generate a PAT in Snowsight:**
   - Log in to Snowsight
   - Click your username (bottom-left) → **My Profile**
   - Navigate to **Authentication** → **Programmatic access tokens**
   - Click **Generate token**, provide a name and expiration, then copy the token

2. **Add the token to your connections file:**
   - Open `~/.snowflake/connections.toml` in a text editor
   - Add or update your connection:
     ```toml
     [my_connection]
     account = "your_account"
     user = "your_username"
     authenticator = "programmatic_access_token"
     token = "your_pat_token_here"
     ```

### Step 4: Launch Cortex Code and Verify

```bash
cortex
```

In Cortex Code, verify your Snowflake connection:

```
List my available Snowflake connections
```

If you need to add a connection, use `/add-connection`.

Verify available skills:

```
list skills
```

You should see skills organized by category. Look for `semantic-view` and `cortex-agent` under **Snowflake Features**.

### Step 5: Load PawCore Data

**Choose your setup path:**

---

#### Option A: Pull from GitHub (Recommended)

No downloads required — Cortex Code fetches and executes the setup script directly from GitHub.

```
Fetch and execute the setup script from https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql to set up the PawCore environment. Proceed autonomously — when prompted for SQL permissions, allow all statements in PAWCORE_ANALYTICS.
```

The script will:
   - Create the `PAWCORE_ANALYTICS` database and schemas (using IF NOT EXISTS)
   - Create a Git integration with `https://github.com/calebaalexander/HandsOnLabs.git`
   - Copy data files from the Git repo to an internal stage
   - Create and load all tables (skips if data already exists)
   - Set up a Cortex Search Service
   - Create an initial Semantic View

> **Note:** This script is non-destructive. If you already have a PAWCORE_ANALYTICS database from a previous demo, all existing objects are preserved.

**Important — Permission Prompts:**

When Cortex Code asks for permission to execute SQL, you'll see options like:
- **Yes** — Allow this specific statement
- **Allow CREATE in any schema** — Allow all CREATE statements  
- **Allow all non-read SQL** — Allow any statement that modifies data
- **No** — Deny this statement

**You are responsible for what you allow.** In a demo environment, "Allow all non-read SQL" speeds things up. In production, review each statement carefully.

---

#### Option B: Pull from Local Machine

If you prefer to work locally (offline, customizing data, etc.):

1. Clone the repo:
   ```bash
   git clone https://github.com/calebaalexander/HandsOnLabs.git
   cd HandsOnLabs/2-Cortex-Code/setup
   ```

2. Launch Cortex Code from that directory and run:
   ```
   Read and execute the setup script at ./CoCo_PawCore_Setup.sql to set up the PawCore environment. Proceed autonomously — when prompted for SQL permissions, allow all statements in PAWCORE_ANALYTICS.
   ```

Alternatively, you can manually upload data files via Snowsight:

1. Go to **https://github.com/calebaalexander/HandsOnLabs**
2. Click the green **"Code"** button → **"Download ZIP"**
3. Extract the ZIP file locally
4. In Snowsight, create the database and stage:
   ```sql
   USE ROLE ACCOUNTADMIN;
   CREATE DATABASE IF NOT EXISTS PAWCORE_ANALYTICS;
   USE DATABASE PAWCORE_ANALYTICS;
   CREATE SCHEMA IF NOT EXISTS SEMANTIC;
   USE SCHEMA SEMANTIC;
   CREATE STAGE IF NOT EXISTS PAWCORE_DATA_STAGE
       DIRECTORY = (ENABLE = TRUE)
       ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
   ```
5. Upload the data files from the extracted `data/` folder to the stage using Snowsight's UI (Data → Databases → PAWCORE_ANALYTICS → SEMANTIC → Stages → PAWCORE_DATA_STAGE → + Files) or via PUT commands:
   ```sql
   -- Example PUT commands (adjust local paths)
   PUT file:///path/to/data/Telemetry/device_telemetry.csv @PAWCORE_DATA_STAGE/Telemetry/;
   PUT file:///path/to/data/Manufacturing/quality_logs.csv @PAWCORE_DATA_STAGE/Manufacturing/;
   PUT file:///path/to/data/Document_Stage/customer_reviews.csv @PAWCORE_DATA_STAGE/Document_Stage/;
   PUT file:///path/to/data/Document_Stage/pawcore_slack.csv @PAWCORE_DATA_STAGE/Document_Stage/;
   ```
6. Run only the **table creation and COPY INTO** sections of the setup SQL (skip the Git integration section).

---

### Step 6: Verify Data Loaded

Ask Cortex Code to validate:

```
Run verification queries to confirm the PawCore data loaded correctly.
Show me row counts for all tables in PAWCORE_ANALYTICS.
```

**What you should see:**
- TELEMETRY table: ~21,000 rows
- QUALITY_LOGS table: ~800+ rows
- CUSTOMER_REVIEWS table: ~1,500+ rows
- SLACK_MESSAGES table: ~37 rows
- PARSED_CONTENT table: 7 documents

---

## Tab 3: Exercise 1 — Build the PawCore Analytics Environment

**Objective:** Set up the PawCore intelligence layer — Semantic View, Cortex Analyst, and Snowflake Intelligence — to support V2 launch readiness analysis.

**Time: ~25 minutes**

**Deliverables:**
- Working Semantic View for Cortex Analyst
- Tested natural language queries
- Cortex Agent enabled in Snowflake Intelligence

---

### Task 1: Review Your Requirements (5 min)

#### Step 1: Review the company background

```
Read the pawcore_company_brief.md file and summarize:

1. Company profile and current product lines
2. What happened in Q4 2024 and how it was resolved
3. What PawCore is focused on now (growth phase)
4. Key stakeholders and what they need from us
```

#### Step 2: Review the requirements meeting notes

```
Read pawcore_discovery_notes.md and identify:

1. Rina's top 3 requirements for the analytics POC
2. Derek's success criteria
3. The questions the POC needs to answer
4. The timeline and deliverables agreed upon
```

---

### Task 2: Create a Semantic View for Cortex Analyst (10 min)

A Semantic View tells Cortex Analyst how to understand your data — table relationships, business-friendly names, metrics, and sample questions.

#### Step 1: Understand Semantic Views

```
Explain what a Cortex Analyst semantic view is and why it's important
for natural language queries. How is it different from a YAML semantic
model? Keep it brief — 3-4 sentences.
```

#### Step 2: Generate the Semantic View

```
Create a Cortex Analyst semantic view for the PAWCORE_ANALYTICS database.
Proceed autonomously.

The semantic view should:
1. Include the TELEMETRY, QUALITY_LOGS, CUSTOMER_REVIEWS, and SLACK_MESSAGES tables
2. Define relationships between tables (lot_number, device_id)
3. Add business-friendly descriptions and synonyms
4. Define key metrics: avg_battery_level, pass_rate, avg_rating, device_count
5. Frame everything around V2 launch readiness analysis
6. Use CREATE SEMANTIC VIEW SQL syntax

Execute the SQL.
```

#### Step 3: Test with launch readiness questions

```
Using the semantic view we just created, test these questions that
Rina and Derek will ask:

1. "Which region should we prioritize for V2 launch based on customer satisfaction?"
2. "Compare regional performance — ratings, battery health, and quality pass rates"
3. "Show me quality pass rates by test type — are we above the 95% threshold?"

For each question, show me:
- The natural language question
- The SQL that Cortex Analyst generated
- The results
```

---

### Task 3: Create a Cortex Agent & Enable Snowflake Intelligence (10 min)

#### Step 1: Create the Cortex Agent

```
Create a Cortex Agent for PawCore's V2 launch readiness analysis.
Proceed autonomously and execute all SQL including grants.

The agent should:
1. Be named "PawCore Launch Analyst"
2. Use the semantic view we created
3. Include the Cortex Search Service (PAWCORE_DOCUMENT_SEARCH) for document search
4. Have instructions appropriate for product and executive stakeholders
5. Include sample questions based on the V2 launch scenario
6. Grant USAGE to appropriate roles
7. Use automatic model selection

Execute all SQL.
```

#### Step 2: Enable in Snowflake Intelligence

```
Make the PawCore Launch Analyst agent available in Snowflake Intelligence.
Proceed autonomously — assume yes to all grants.

1. Grant USAGE on the agent to PUBLIC
2. Add the agent to Snowflake Intelligence
3. Verify it was added successfully

Execute all SQL.
```

#### Step 3: Test the agent

```
Test the agent with questions Rina and Derek would ask:

1. "Rank our regions by V2 launch readiness — consider ratings and battery health"
2. "Which region has the highest customer engagement and satisfaction?"
```

---

### Validation Checklist — Exercise 1

Before proceeding, verify:
- [ ] Semantic View created in PAWCORE_ANALYTICS
- [ ] Cortex Analyst responds correctly to natural language queries
- [ ] Generated SQL is correct and references the right tables
- [ ] Cortex Agent created and responding
- [ ] Agent enabled in Snowflake Intelligence (USAGE granted)
- [ ] Agent answers V2 launch readiness questions meaningfully

---

## Tab 4: Exercise 2 — Master Cortex Code Skills

**Objective:** Learn to use built-in Cortex Code skills and create a custom skill that encodes PawCore's launch readiness workflow.

**Time: ~25 minutes**

**Deliverables:**
- Experience with built-in skills
- A custom `pawcore-launch-readiness` skill

---

### Task 1: Explore Built-in Skills (10 min)

#### Step 1: List available skills

```
List all available skills and briefly describe what each does.
```

You should see skills organized by category:
- **Data & Analytics:** `analyzing-data`, `data-governance`, `lineage`
- **Snowflake Features:** `semantic-view`, `cortex-agent`, `dynamic-tables`, `cost-management`
- **Development:** `developing-with-streamlit`, `machine-learning`, `dbt-projects-on-snowflake`

#### Step 2: Understand skill structure

```
Explain the structure of a Cortex Code skill:
- What files does it contain?
- What is the SKILL.md format?
- How do skills get triggered?

Keep it concise — bullet points preferred.
```

**Key concept: Skill Storage Locations**

| Type | Location | Scope |
|------|----------|-------|
| Bundled | `~/.local/share/cortex/*/bundled_skills/` | All projects (read-only) |
| Global | `~/.cortex/skills/` | All projects |
| Project-local | `.cortex/skills/` in project root | Single project only |

Precedence: Project-local > Global > Bundled

#### Step 3: Review the semantic-view skill

```
Show me the structure of the semantic-view skill.
What are its main workflow steps?
What sub-skills does it contain?
```

---

### Task 2: Understand a Bundled Skill (5 min)

Let's examine the `cortex-agent` skill structure to understand how skills work.

```
Show me the structure of the cortex-agent skill.
What workflow steps does it follow?
What checks does it perform on a Cortex Agent?
```

**What you should see:** A breakdown showing:
- Directory structure with sub-skills (audit, debug, best-practices)
- Workflow: gather agent config → audit against best practices → identify gaps → apply fixes
- Checks for guardrails, tool descriptions, error handling, edge cases

> **Key Insight:** Skills encode repeatable workflows so you get consistent, thorough results every time. The cortex-agent skill handles agent creation, debugging, and evaluation automatically.

---

### Task 3: Create a Custom Skill (10 min)

Now create your own skill that encodes a repeatable launch readiness workflow.

#### Step 1: Define the skill scope

```
I want to create a custom skill called "pawcore-launch-readiness" that
helps our team quickly assess launch readiness for new products.
Proceed autonomously.

The skill should:
1. Gather launch requirements (target regions, product line, stakeholders)
2. Analyze quality metrics for stability trends
3. Assess customer sentiment by region
4. Generate a launch readiness scorecard
5. Produce a board-ready executive summary

Help me outline the workflow steps. Do not generate the skill yet.
```

#### Step 2: Create the skill

```
Create the pawcore-launch-readiness skill in the .cortex/skills/ directory.
Proceed autonomously.

.cortex/skills/
└── pawcore-launch-readiness/
    └── SKILL.md

The SKILL.md should include:

## Frontmatter
- name: pawcore-launch-readiness
- description: Trigger phrases and when to use

## Workflow Steps
1. Gather Requirements — Target regions, product, stakeholders
2. Quality Assessment — Analyze pass rates, failure trends
3. Customer Sentiment — Review scores, feedback themes by region
4. Device Performance — Telemetry metrics, engagement levels
5. Generate Scorecard — Regional readiness scores
6. Executive Summary — Board-ready recommendation

## Stopping Points
- After requirements gathering (confirm understanding)
- After analysis (verify findings look correct)
- After executive summary (approve before sharing)

## Output
What artifacts this skill produces

Keep it under 200 lines.
```

#### Step 3: Test the skill (Optional)

```
Use the pawcore-launch-readiness skill to assess whether PawCore is
ready to launch SmartCollar V2 in the APAC region.
```

#### Step 4: Promote to Global Skill (Optional)

If your skill works well, promote it so it's available across all projects:

```
Copy the pawcore-launch-readiness skill from the project's .cortex/skills/
directory to my global skills directory (~/.cortex/skills/) so I can
use it in any project.
```

---

### Validation Checklist — Exercise 2

Before proceeding, verify:
- [ ] Explored and listed available bundled skills
- [ ] Examined the `cortex-agent` skill structure
- [ ] Created `pawcore-launch-readiness` skill with proper structure
- [ ] Skill has clear frontmatter and workflow steps
- [ ] Skill includes appropriate stopping points

---

## Tab 5: Exercise 3 — Generate Launch Documentation

**Objective:** Produce stakeholder-ready documentation for the SmartCollar V2 launch presentation to the board.

**Time: ~10 minutes**

**Deliverables:**
- Architecture diagram (Mermaid)
- V2 Launch Readiness report
- Board presentation script

---

### Task 1: Architecture Diagram (3 min)

```
Create a Mermaid architecture diagram showing PawCore's data platform.
Proceed autonomously.

Include:
1. Data Sources — Device telemetry, Manufacturing QC, Customer reviews,
   Internal comms, QC documents
2. Snowflake Platform — Schemas (DEVICE_DATA, MANUFACTURING, SUPPORT,
   UNSTRUCTURED, SEMANTIC), Cortex Search, Semantic View
3. Intelligence Layer — Cortex Analyst, Cortex Agent, Snowflake Intelligence
4. Consumers — Rina (VP Product), Derek (CFO), Board, Analytics Team

Save the diagram to a file called pawcore_architecture.md
```

### Task 2: Launch Readiness Report (4 min)

```
Based on the data analysis from Exercise 1, create a V2 Launch Readiness
Report. Proceed autonomously.

Include:
1. Executive Summary (3-4 sentences)
2. Regional Readiness Scores (Americas, EMEA, APAC)
3. Quality Metrics Summary (pass rates, trends)
4. Customer Sentiment Summary (ratings, themes)
5. Risk Factors
6. Recommendation (go / no-go / conditional)

Save to a file called v2_launch_readiness_report.md
```

### Task 3: Board Presentation Script (3 min)

```
Based on the launch readiness report, create a 5-minute board
presentation script for Rina. Proceed autonomously.

1. Opening — Remind the board of the Q4 2024 recovery story (30 sec)
2. Current State — Quality is stable, customers are engaged (1 min)
3. Regional Analysis — Where we're strong, where we need more time (1.5 min)
4. Recommendation — Clear go/no-go with supporting data (1 min)
5. Q&A Prep — Anticipated questions from Derek (1 min)

Format as brief talking points with the exact queries to reference.
Save to a file called board_presentation_script.md
```

---

### Validation Checklist — Exercise 3

- [ ] Architecture diagram renders correctly (paste into mermaid.live to verify)
- [ ] Launch readiness report covers all regions with data-backed scores
- [ ] Presentation script is under 5 minutes when read aloud
- [ ] All artifacts saved to files

---

## Congratulations!

You've completed the **Intro to Cortex Code CLI** Hands-On Lab.

### What You Accomplished
- Built a working analytics environment with Cortex Code CLI
- Created a Semantic View and Cortex Agent for Snowflake Intelligence
- Mastered using built-in skills and created a custom skill for your team
- Generated professional documentation for a board presentation

### What You Can Do Next
- Refine the Semantic View based on real user questions
- Share the `pawcore-launch-readiness` skill with colleagues
- Explore more bundled skills: `cost-management`, `data-governance`, `dynamic-tables`
- Try the **Intro to CoCo UI** lab for the visual Snowsight experience

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
1. **Use the right skill** — Check if a bundled skill exists before doing manual work
2. **Include context** — Reference PawCore's specific needs in your prompts
3. **Iterate** — First outputs are starting points; refine with follow-ups
4. **Save everything** — Write outputs to files for your stakeholder presentations
5. **Capture patterns** — Turn repeated workflows into skills for your team
