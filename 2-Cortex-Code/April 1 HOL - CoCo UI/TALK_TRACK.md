# Webinar Talk Track — Cortex Code in Snowsight: Build a Full Data Pipeline with AI

> Internal presenter doc. Not for distribution.

---

## Opening (Before Exercise 1)

"Today we're going to build something real. Not a toy example — an actual analytics pipeline for a company that has a product launching tomorrow. PawCore makes smart pet health collars. SmartCollar V2 is about to ship, and Marcus Thompson, their CX lead, needs to know one thing: *is my support team ready for the volume this launch is going to bring?*

By the end of this session, Marcus is going to have a notebook, a live data pipeline, a dashboard his whole team can use every morning, and a conversational agent he can ask ad-hoc questions. And we're going to build all of it using Cortex Code — in natural language, right inside Snowsight. No terminal, no IDE, no context switching."

---

## Exercise 1: Fix Broken Code

### The Setup

"Before we build anything, let's talk about the most common thing that actually happens at work. Someone hands you a query. It doesn't run. You don't know whose it is or what it was supposed to do. This happens constantly — inherited code, a ticket from a teammate, something copied out of a Confluence doc three years ago. CoCo turns this from a debugging session into a thirty-second fix.

I've got a query here that's supposed to show support ticket volume by region and severity. Three errors are buried in it — a typo in the schema name, a bad sort direction, and a column that doesn't actually exist in the table. Let's walk through three different ways CoCo handles this."

### Explain Button

"First — I don't even know what this query does. So before I try to fix it, I'm going to highlight it and hit Explain. CoCo reads the code and gives me plain English: it's pulling ticket counts by region and priority, sorting descending. Now I understand what I'm working with. If you inherited code from someone who left the team, this is your first move — always."

### Method 1 — Natural Language

"I see `DES` on the ORDER BY. I'll select it, click Add to Chat, and just type: 'fix this, it should be DESC.' CoCo returns the corrected line. I accept it. Done in five seconds."

### Method 2 — Inline Fix Button

"Now I'll run the query. I get a schema error — `SUPORT` doesn't exist. Notice that Fix button that appears right below the error? I click it, CoCo shows me a diff: SUPORT becomes SUPPORT. One click to accept. CoCo is reading the error message and resolving it in context — I didn't have to tell it anything."

### Method 3 — Schema Introspection

"Run again. Now I get an invalid identifier error on SEVERITY. I click Fix again — this time CoCo doesn't just fix a typo, it actually inspects the table schema, sees the column is called PRIORITY, and makes the right substitution. That's the key moment: CoCo isn't just pattern-matching, it's looking at your actual data environment. Eight rows come back. We're good."

---

## Exercise 2: Snowflake Notebook

### The Setup

"Now we get to the analysis. Marcus's team already has a starter model someone built — it tries to predict customer review ratings from device telemetry. The problem is it only uses two features, a simple linear regression, and the R-squared is negative. A negative R-squared means your model is worse than just guessing the average. This thing needs help.

We're going to upload this notebook into Snowflake and use CoCo to turn it into something actually useful — with better features, a stronger algorithm, proper evaluation, and an AI sentiment layer on top of the review text."

### Uploading

"Import the starter `.ipynb` from the GitHub repo. We set the location to PAWCORE_ANALYTICS.SUPPORT, pick our warehouse, and rename it. Now — here's what I want you to notice when it opens. Two cells. Two features. A negative R-squared. This is what 'good enough to ship' looks like before anyone invests time in it."

### The Prompt

"I'm going to give CoCo one prompt. I'm going to tell it: the model needs more features — pull in ticket counts and resolution times from the support tickets table. Add CORTEX.SENTIMENT to score the review text. Replace LinearRegression with RandomForest or GradientBoosting. Add cross-validation, feature importance, a before/after comparison, and a final cell that flags each region as SUPPORT_READY or AT_RISK.

Watch what happens. CoCo reads the existing notebook, understands the schema, and builds on top of what was already there — it doesn't start over. It adds cells, connects to the right tables, calls the Cortex sentiment function, and runs each cell as it goes. This is the moment I want you to internalize: *you didn't write a single line of Python.*"

### The Punchline

"Feature importance tells us battery level barely matters. What actually predicts a bad review? High ticket volume and negative sentiment. That's the insight Marcus needs. Now we need to operationalize it."

---

## Exercise 3: Dynamic Table

### The Setup

"Marcus just saw this analysis and his first question is: 'Great. But tickets come in every hour. When does this go stale?' That's always the question after a good notebook — now make it live.

Dynamic Tables are the answer. You write a query, you set a refresh interval, Snowflake handles everything else. No Airflow. No cron job. No orchestration layer to maintain. If your source data updates, your Dynamic Table updates. Let me show you how fast CoCo can build one."

### The Prompt

"I tell CoCo: create a Dynamic Table called SUPPORT_OPS_DASHBOARD. Aggregate ticket counts, critical ticket counts, customer ratings, low battery events, and AI sentiment scores by region. Flag each region as SUPPORT_READY when critical tickets are under 20 and sentiment is positive. One minute target lag. Execute it.

CoCo generates the full CREATE OR REPLACE DYNAMIC TABLE statement — joins across three tables, the CORTEX.SENTIMENT call, the CASE logic for the readiness flag, the warehouse setting, the lag. I didn't write any of that SQL."

### The Point

"The reason this matters: data engineers spend a huge amount of time maintaining pipelines. Scheduling, monitoring, re-running failed jobs. Dynamic Tables collapse that whole layer. You define what you want, Snowflake keeps it current. CoCo makes it so you don't even have to write the definition. That's two compounding wins."

---

## Exercise 4: Streamlit App

### The Setup

"The Dynamic Table is live. Marcus has the data. But he doesn't want to run a SQL query every morning before standup — he wants something he can open on his laptop and immediately understand. We're going to build him that in Snowflake, using CoCo, right now.

Streamlit in Snowflake is the fastest path from data to a real application. It runs inside your Snowflake environment, reads directly from your tables, and you don't need to deploy or host anything. CoCo can write the whole thing from a prompt."

### The Prompt

"I tell CoCo: build a Streamlit app called Support Ops Dashboard in PAWCORE_ANALYTICS.SUPPORT. Read from the Dynamic Table we just built. Give me a header, regional readiness cards — green for ready, red for at-risk — a bar chart comparing total tickets vs critical tickets by region, and a risk assessment section that flags anything dangerous.

CoCo generates a complete Python Streamlit file and deploys it. I navigate to Streamlit in Snowsight — and there it is. A real app. Cards are colored, the chart is live, the risk flags are there."

### The Iteration Moment

"Now watch this — this is the part that changes how you think about app development. I ask CoCo: add a sidebar dropdown to filter by region, and show the top 5 most critical tickets for whatever region I select. It makes the change. I refresh. The filter is there. I just iterated on a production application through conversation.

That's not a toy. Marcus can hand this URL to every manager on his CX team. Every morning, they open it, they see where they stand, they go into standup prepared."

---

## Exercise 5: Semantic View + Intelligence Agent

### The Setup

"Last exercise — and this one closes the loop. Everything we've built so far gives Marcus answers to questions we already knew to ask. But Marcus is going to have questions we didn't predict. 'What's driving the spike in EMEA this week?' 'Is there a correlation between low battery events and critical tickets?' He needs to be able to ask those questions himself, without a data analyst in the room.

That's what Snowflake Intelligence does. We're going to give Marcus a conversational agent that can answer any question about support operations in natural language. Two pieces to build: a Semantic View that defines the business context, and an Agent that uses it."

### Semantic View

"The Semantic View is the intelligence layer. It tells the agent: here are the tables, here's how they relate, here are the metrics that matter — total tickets, critical ticket count, average rating, average battery level. When Marcus asks a question in plain English, this is what the agent uses to translate it to SQL.

I give CoCo the prompt — include these four tables, define these six metrics, skip the data_type field. CoCo builds the YAML and creates the view."

### The Agent

"Now the agent. I tell CoCo: create a Cortex Agent that uses the SUPPORT_OPS semantic view and the Cortex Search service we loaded in setup — which has the parsed document content. Give it instructions to respond concisely with bullet points and regional breakdowns. Grant usage to PUBLIC.

CoCo creates it. I navigate to AI & ML → Agents → Snowflake Intelligence. I add the agent. I ask: *'Which region has the highest support ticket load and what's driving it?'*

It runs the query, it pulls the answer, it formats it. Then I ask: *'Is there a correlation between low battery events and critical support tickets?'*

It joins the telemetry and ticket tables on the fly and tells me. Marcus just became self-sufficient."

---

## Close

"Here's what we actually just did. We started with seven raw tables and a broken SQL query. In about 45 minutes, using nothing but natural language inside Snowsight, we built a feature-engineered ML analysis, a live auto-refreshing data pipeline, a dashboard Marcus's whole team can use, and a conversational analytics agent.

CoCo didn't replace any decision-making. Every prompt we wrote, we knew what we wanted. What CoCo removed was all the friction between knowing what you want and actually having it. That's the shift. The bottleneck used to be writing code. Now it's thinking clearly about what to build."
