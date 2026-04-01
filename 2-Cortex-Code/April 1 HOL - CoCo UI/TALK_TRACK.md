# Webinar Talk Track — Cortex Code in Snowsight: Build a Full Data Pipeline with AI

> Internal presenter doc. Not for distribution.

---

## Transition to Snowsight — CoCo Orientation

*[Switch from slides to Snowsight]*

"Before we look at anything in the UI — two quick checks. First, the setup script we're about to run requires ACCOUNTADMIN. If you're on a personal trial account, you have it by default. If you're on a company account, check your active role in the top-right corner of Snowsight — if it doesn't say ACCOUNTADMIN, reach out to your Snowflake account admin to either grant it or run the setup on your behalf."

"Second, Cortex Code needs to be enabled on your account. If you don't see the CoCo panel at all, or it's grayed out, reach out to your account admin to get it enabled. If you're not sure — drop a message in the chat right now and we'll sort it out before we go any further."

"If you have both — you're good. Now let me show you where CoCo lives."

"You'll see this icon on the right sidebar — it looks like a small sparkle or chat bubble. Click that and the CoCo panel opens on the right side of whatever you have open. It doesn't matter if you're in a worksheet, a notebook, or a Streamlit app — CoCo is always available from that same panel."

"Notice it already knows your context: your active database, schema, and role are all visible at the top. That's what makes this different from pasting code into a chatbot — CoCo is connected to your environment from the start."

"The chat input is at the bottom. You type, hit enter, and CoCo responds inline. If it writes code, you can accept it directly into the editor with one click."

"That's all you need to know to get started. Let's run the setup."

---

## Setup: Load PawCore Data

"Before anything else, you need to get the demo data into your Snowflake account. The setup script is linked in the GitHub repo — it's `exercises/00_setup.sql`. Open it, copy the full contents, and paste it into a SQL worksheet."

"Once it's in the worksheet, click Run All to execute."

"The script takes about 1 minute. It's creating the `PAWCORE_ANALYTICS` database, six schemas, and seven tables loaded with demo data. It's non-destructive — if you already ran it before, it won't break anything."

"To verify everything loaded, `00_setup.sql` has a verification query at the bottom — run it and you should see row counts across all seven tables. TELEMETRY around 21,000 rows, SUPPORT_TICKETS around 240, and so on. If any table shows zero, the setup didn't complete — let me know in the chat."

"While everyone's running the setup, I'll demo it on my end so you can see what it looks like."

*[Run setup on demo account, show the verification query output]*

"Good. Once you see row counts across all seven tables, you're ready. Let's go to Exercise 1."

---

## Exercise 1: Fix Broken Code

### The Setup

"Before we build anything, let's talk about the most common thing that actually happens at work. Someone hands you a query. It doesn't run. You don't know whose it is or what it was supposed to do. This happens constantly — inherited code, a ticket from a teammate, something copied out of a Confluence doc three years ago. CoCo turns this from a debugging session into a thirty-second fix.

I've got a query here that's supposed to show support ticket volume by region and severity. Three errors are buried in it — a typo in the schema name, a bad sort direction, and a column that doesn't actually exist in the table. Let's walk through three different ways CoCo handles this."

### Explain Button

"First — I don't even know what this query does. So before I try to fix it, I'm going to highlight it and hit Explain. CoCo reads the code and tells me in plain English: this query is pulling support ticket counts grouped by region and priority level, sorted from highest to lowest. It's trying to show where the ticket load is heaviest and what kind of issues are driving it. Now I understand what I'm working with before I touch a single line. If you inherited code from someone who left the team, this is your first move — always."

### Method 1 — Natural Language

"I see `DES` on the ORDER BY. I'll select it, click Add to Chat, and just type: 'fix this, it should be DESC.' CoCo returns the corrected line. I accept it. Done in five seconds."

### Method 2 — Inline Fix Button

"Now I'll run the query. I get a schema error — `SUPORT` doesn't exist. Notice that Fix button that appears right below the error? I click it, CoCo shows me a diff: SUPORT becomes SUPPORT. One click to accept. CoCo is reading the error message and resolving it in context — I didn't have to tell it anything."

### Method 3 — Schema Introspection

"Run again. Now I get an invalid identifier error on SEVERITY. I click Fix again — this time CoCo doesn't just fix a typo, it actually inspects the table schema, sees the column is called PRIORITY, and makes the right substitution. That's the key moment: CoCo isn't just pattern-matching, it's looking at your actual data environment.

The results come back: EMEA is at the top — highest ticket volume, and most of those are CRITICAL or HIGH priority. Americas is in the middle. APAC is clean. That's the story we're going to spend the next four exercises solving. And we just got there without writing a single line of code ourselves."

*Now you know how to use CoCo to understand and fix inherited code in under a minute.*

---

## Exercise 2: Snowflake Notebook

### What Is a Notebook?

"A notebook is a document where code and results live together — you run one cell at a time and see the output immediately. It's the standard tool for data science work. In Snowflake, notebooks run directly inside your account with access to all your data and Cortex AI — no setup needed."

### Workspaces vs. Legacy Notebooks

"Before we get into the exercise — quick orientation on where we're working. If you've used Snowflake Notebooks before, you're probably used to going to Projects → Notebooks in the sidebar. That still works. But we're going to use **Workspaces** today — it's the newer unified environment where your SQL files, Python files, and notebooks all live together in one place. CoCo has context across all of them at once. Once you try it, it's hard to go back."

### Uploading

"To bring in the notebook, click **+ Add new** in the workspace sidebar and choose **Upload Files**. Select the `.ipynb` file from your machine — it'll appear in the file panel. Open it, set your database to PAWCORE_ANALYTICS, your schema to SUPPORT, pick the warehouse, and rename it to Support Ops Readiness Analysis.

When it opens — two cells, two features, a negative score. This is what 'good enough to ship' looks like before anyone invests time in it."

### The Setup

"Now — PawCore's analytics team already has a starter notebook someone built. Think of it like a basic calculator for predicting customer satisfaction scores. It looks at device data and tries to guess how a customer will rate their experience. The problem is it's only looking at two things — and even then, it's doing worse than if you just guessed the average every single time. That's what a negative R-squared means. In plain terms: the model is giving wrong answers more often than no model at all would.

If you're not familiar with machine learning — don't worry. At its core, a model is just a formula that learns patterns from your data and uses them to make predictions. The more good data you feed it, the smarter it gets. Right now, this one isn't smart enough.

We're going to use CoCo to fix it — more data inputs, a stronger algorithm, and an AI layer that reads the actual text of customer reviews to understand the emotion behind them."

### The Prompt

*[Remind audience: all prompts are in the GitHub repo under `exercises/` — they don't need to type anything out. Direct them to `02_notebook_prompt.sql`.]*

> **Copy-paste prompt:**
> ```
> Improve this notebook. Pull in ticket counts, critical ticket counts, and average resolution time from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS. Add SNOWFLAKE.CORTEX.SENTIMENT on review text as a feature. Replace the model with a RandomForestRegressor. Add a final cell flagging each region as SUPPORT_READY or AT_RISK based on predicted rating and sentiment score.
> ```

"I'm going to give CoCo one prompt — and watch what it does with it.

We're asking it to do three things: first, bring in more data — ticket counts and how long it took to resolve them. Second, use AI to read every customer review and score the emotion behind it — is this person frustrated or happy? Third, swap out the basic model for a stronger one and flag each region as SUPPORT_READY or AT_RISK based on what the data shows.

One prompt. Three upgrades."

> **Aside — you could also just say:** *"Improve this notebook"*
> CoCo will read the existing code, look at the available tables, and infer what to do next on its own. The long prompt gives you more control. The short one gives CoCo more creative freedom. Either works — and that's the point.

"CoCo reads the existing notebook, understands the data, and builds on top of what's already there — it doesn't start over. It adds cells, connects the right tables, and runs each one as it goes. *You didn't write a single line of Python.*"

> **Note — CoCo may add commentary on the model inline.** Let it run — it's evaluating the output as it goes, not just executing. That's the difference between a code generator and an actual AI assistant.

### The Punchline

"We went from 2 features to 6. The starter notebook couldn't see ticket volume, resolution time, or customer emotion — it was flying blind. Now it can.

Scroll to the last cell. APAC is SUPPORT_READY — the only region where sentiment is holding up. Americas and EMEA are AT_RISK — sentiment score deep negative, predicted rating near the floor.

EMEA is the worst of the two. Negative sentiment and 500 low-battery device events. That's a hardware crisis showing up in the review text — customers are frustrated, and the telemetry data confirms exactly why. That's the insight. Now we need to make it live."

*Now you know how to use CoCo to upgrade a data science notebook without writing a single line of Python.*

---

## Exercise 3: Dynamic Table

### The Setup

"The team just saw this analysis and the first question is: 'Great. But tickets come in every hour. When does this go stale?' That's always the question after a good notebook — now make it live.

A Dynamic Table is a table that Snowflake keeps up to date for you. You write a query — joins, aggregations, transformations, whatever you need — and you tell Snowflake how fresh you want it. Every minute, every hour, it doesn't matter. Snowflake watches your source tables and refreshes the output automatically when something changes. No Airflow pipeline. No cron job. No ETL job to babysit.

For PawCore, that means the moment a new support ticket comes in or a customer leaves a review, that data flows into the dashboard automatically. The CX team is always looking at current numbers — not last night's export."

### The Prompt

*[Remind audience: this prompt is in the GitHub repo — `exercises/03_dynamic_table_prompt.sql`.]*

> **Copy-paste prompt:**
> ```
> Create a Dynamic Table called SUPPORT_OPS_DASHBOARD in PAWCORE_ANALYTICS.SUPPORT using warehouse PAWCORE_DEMO_WH with a target lag of 1 minute. Aggregate by region: total ticket count, critical ticket count, average customer rating, count of low battery events where battery_level < 0.20, and average SNOWFLAKE.CORTEX.SENTIMENT score from customer review text. Add a READINESS_STATUS column: flag as 'SUPPORT_READY' when critical tickets are 25 or fewer and average sentiment is above 0.5, otherwise 'AT_RISK'. Join SUPPORT.SUPPORT_TICKETS, SUPPORT.CUSTOMER_REVIEWS, and DEVICE_DATA.TELEMETRY.
> ```

"We're asking CoCo to do four things: first, create a table that refreshes itself every minute — no pipeline, no job, Snowflake handles it automatically. Second, roll up the data by region: how many tickets, how many critical ones, what's the average rating, how often is battery critically low. Third, run AI sentiment scoring across every customer review and include that score in the rollup. And fourth, apply the same readiness logic we built in the notebook — flag each region as SUPPORT_READY or AT_RISK based on what the data shows.

CoCo generates the full SQL — joins across three tables, the CORTEX.SENTIMENT call, the CASE logic for the readiness flag, the warehouse and lag settings. I didn't write any of that."

### The Showcase

*[After CoCo creates the table — run this in the same worksheet or a new one.]*

**Step 1 — Verify the table first** *(do this before presenting)*

```sql
SELECT * FROM PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD ORDER BY REGION;
```

> **Pre-demo check:** You should see APAC as SUPPORT_READY and Americas/EMEA as AT_RISK. If all three regions show identical sentiment scores (~-0.78) and all show AT_RISK, CoCo generated a join that inflates rows. Run the **CORRECTED VERSION** in `03_dynamic_table_prompt.sql` to rebuild it with proper CTEs before presenting.

**Step 2 — Present the query to the audience**

"Same readiness flags the notebook just produced — APAC SUPPORT_READY, Americas and EMEA AT_RISK. Same logic. But now it's a live table, not a notebook output. Any time a new ticket comes in or a customer leaves a review, this refreshes automatically. The CX team queries this and they're always looking at current data — not last night's export."

**Step 3 — Show the monitoring UI**

*[Left sidebar → Monitoring → Dynamic Tables → click SUPPORT_OPS_DASHBOARD]*

"This is the control panel. Last refresh time, target lag, health status — all here. Snowflake is running this for you on a schedule. No job scheduler, no pipeline to babysit. It just runs."

### The Point

"The reason this matters: data engineers spend a huge amount of time maintaining pipelines. Scheduling, monitoring, re-running failed jobs. Dynamic Tables collapse that whole layer. You define what you want, Snowflake keeps it current. CoCo makes it so you don't even have to write the definition. That's two compounding wins."

*Now you know how to use CoCo to build a self-refreshing data pipeline from a single prompt.*

---

## Exercise 4: Streamlit App

### The Setup

"The Dynamic Table is live. PawCore has the data. But the CX team doesn't want to run a SQL query every morning before standup — they want something they can open on any laptop and immediately understand. We're going to build that in Snowflake, using CoCo, right now.

Streamlit in Snowflake is the fastest path from data to a real application. It runs inside your Snowflake environment, reads directly from your tables, and you don't need to deploy or host anything. CoCo can write the whole thing from a prompt."

### Creating the Shell First

"Before CoCo writes any code, you need a Streamlit app to write it into. The easiest workflow: create the shell first, then let CoCo fill it.

In Snowsight: **Projects → Streamlit → + Streamlit App**. Name it `Support_Ops_Dashboard`, set the database to `PAWCORE_ANALYTICS`, schema to `SUPPORT`, warehouse to `PAWCORE_DEMO_WH`. That creates a blank app with a default placeholder — you don't need to write anything. Now open the CoCo panel and give it the prompt. CoCo sees the open file, writes the full app into it, and you run it."

### The Prompt

*[Remind audience: this prompt is in the GitHub repo — `exercises/04_streamlit_prompt.sql`.]*

"I'm going to give CoCo one prompt. I want a dashboard — a title at the top, a card for each region that turns green if they're good and red if they're not, a chart showing how many tickets came in and how many were critical, and a section at the bottom that calls out anything that needs attention. That's it. Watch what comes out."

CoCo writes the full Python code into the open editor. Replace the default placeholder code with it and click Run. A real app — cards are colored, the chart is live, the risk flags are there."

> **Copy-paste prompt:**
> ```
> Build a Streamlit dashboard that reads from PAWCORE_ANALYTICS.SUPPORT.SUPPORT_OPS_DASHBOARD. Use get_active_session() to query the table. Include a header with the title "PawCore Support Ops Dashboard", regional readiness cards with green background for SUPPORT_READY and red for AT_RISK, a bar chart comparing TOTAL_TICKET_COUNT vs CRITICAL_TICKET_COUNT by region, and a risk section that calls out any AT_RISK region with a summary of what's driving it.
> ```

### The Iteration Moment

"Now watch this — this is the part that changes how you think about app development. I ask CoCo: add a sidebar dropdown to filter by region, and show the top 5 most critical tickets for whatever region I select. It makes the change. I refresh. The filter is there. I just iterated on a production application through conversation.

> **Copy-paste prompt:**
> ```
> Add a sidebar dropdown to filter by region. When a region is selected, query PAWCORE_ANALYTICS.SUPPORT.SUPPORT_TICKETS and show the top 5 most critical open tickets for that region in a table below the chart.
> ```

That's not a toy. PawCore's CX lead can hand this URL to every manager on the team. Every morning, they open it, they see where they stand, they go into standup prepared."

*Now you know how to use CoCo to build and iterate on a live Streamlit app through conversation.*

---

## Exercise 5: Semantic View + Intelligence Agent

### The Setup

"Last exercise — and this one closes the loop. Everything we've built so far gives PawCore answers to questions we already knew to ask. But the business will always have questions we didn't predict. That's where Snowflake Intelligence comes in. We're going to use CoCo to build the two pieces that make it work: a Semantic View and an Agent."

### Semantic View

*[Remind audience: both prompts for this exercise are in the GitHub repo — `exercises/05_semantic_view_agent_prompt.sql`.]*

"The Semantic View is what gives the agent business context. Instead of raw tables, it understands metrics — total tickets, critical ticket count, average rating, battery levels. I give CoCo a prompt describing what I want defined, and it builds the YAML and creates the view. I didn't write a single line of configuration."

> **Copy-paste prompt:**
> ```
> Create a semantic view called SUPPORT_OPS in PAWCORE_ANALYTICS.SEMANTIC over these tables: SUPPORT.SUPPORT_TICKETS, SUPPORT.CUSTOMER_REVIEWS, DEVICE_DATA.TELEMETRY, and SUPPORT.SLACK_MESSAGES. Define these metrics: total_tickets, critical_ticket_count, average_customer_rating, low_battery_event_count (battery_level < 0.20), and average_sentiment_score using SNOWFLAKE.CORTEX.SENTIMENT on review text. Set up joins between tables on device_id and region. Do not include a data_type field.
> ```

### While the Semantic View Builds

*[CoCo is generating the YAML and running the CREATE SEMANTIC VIEW — takes 1-2 minutes. Talk through this while it runs.]*

"While that runs — let me explain what CoCo is actually building here, because it's worth understanding.

A Semantic View is not a regular database view. It doesn't store rows. What it stores is *meaning* — the business definition of your data. It says: a 'ticket' is a row in SUPPORT_TICKETS. A 'critical ticket' is one where priority equals critical. An 'average sentiment score' is the CORTEX.SENTIMENT function applied to review text, averaged by region. It defines how your tables join, what your metrics mean, and what questions are valid to ask.

When the Intelligence Agent gets a question in plain English — 'which region has the most critical tickets?' — it doesn't guess at SQL. It reads the Semantic View, understands that critical_ticket_count is already defined, looks up which table it comes from and how to filter it, and writes the query correctly every time. That's what makes the answers reliable instead of hallucinated.

The reason this is a different kind of asset from the Dynamic Table or the Streamlit app: those two things answer questions you already knew to ask. The Semantic View answers questions you haven't thought of yet. You build it once, and every analyst, manager, and exec in the company can ask their own question directly — without opening a SQL editor, without filing a ticket with the data team, without waiting for a dashboard to be built.

That's the actual unlock here. Not the agent. The fact that the semantic layer exists. CoCo just made it so you don't have to write the YAML by hand."

*[Check if it's done — if not, take a question from the audience or ask:]*

> **Audience prompt:** "What's a question you'd want to ask about your own support data that you currently have to wait for someone else to answer?" *[Let 1-2 people respond, then use EMEA as the example answer.]*

### The Agent

"Now I tell CoCo: create a Cortex Agent using the semantic view we just built. CoCo creates it. I navigate to Snowflake Intelligence, add the agent, and start asking questions in plain English.

> **Copy-paste prompt:**
> ```
> Create a Cortex Agent called PAWCORE_SUPPORT_OPS_AGENT in PAWCORE_ANALYTICS.SEMANTIC. Use the SUPPORT_OPS semantic view. Give it these instructions: respond concisely with bullet points, always include a regional breakdown when relevant, and highlight EMEA specifically when ticket volume or sentiment is a concern. Grant usage to PUBLIC role.
> ```

*'Which region has the highest support ticket load and what's driving it?'* — it answers.

*'Is there a correlation between low battery events and critical tickets?'* — it joins the tables and tells me.

The point isn't the answer. The point is that CoCo built the entire intelligence layer — and now anyone on PawCore's team can ask their own questions without touching SQL."

*Now you know how to use CoCo to build an AI agent that makes your data available to anyone, in plain English.*

---

## Transition Back to Slides

"Alright — let's come back to the slides and wrap this up."
