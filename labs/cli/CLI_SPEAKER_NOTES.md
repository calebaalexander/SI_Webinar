# Cortex Code CLI Demo — Speaker Notes

**Total Time:** ~60-70 minutes (adjust pace based on audience)

---

## OPENING (2-3 min)

### Set the Stage

> "Today we're going to experience Cortex Code CLI — Snowflake's AI coding agent that lives in your terminal. This isn't just another AI assistant. It's deeply integrated with Snowflake, understands your data, and can actually execute against your environment."

**Key message:** Cortex Code isn't a chatbot. It's an agent that takes action.

### Why This Matters to Them

> "Think about the last time you had to:
> - Set up a data environment for a POC
> - Build a semantic model for business users
> - Create documentation for stakeholders
> - Repeat the same analysis pattern across multiple projects
>
> That's exactly what we're doing today — but in a fraction of the time."

### The Scenario

> "We're playing the role of a Snowflake team helping PawCore — an IoT pet tech company — prepare for their SmartCollar V2 launch. They had some quality issues last year that they've resolved, and now leadership wants to know: are we ready to launch V2?"

---

## TAB 2: GETTING STARTED (10 min)

### Step 1-3: Installation & Authentication

**If pre-installed:** Skip to Step 4

**If installing live:**

> "The install is a single curl command. What's happening behind the scenes is it's downloading the cortex binary and putting it in your local bin. Nothing invasive — no admin rights needed."

**On PAT Authentication:**

> "Cortex Code uses Programmatic Access Tokens — the same secure authentication pattern you'd use for any programmatic Snowflake access. This means it has exactly the permissions of your Snowflake user. No elevated access, no security concerns."

**WHY THIS MATTERS:** "Your security team will ask about this. The answer is: same auth as your user, same permissions, nothing extra."

---

### Step 4: Launch & Verify

**Demo the launch:**

```bash
cortex
```

> "Notice the clean interface. This is a full terminal experience — you can use it over SSH, in VS Code's terminal, wherever you work."

**List connections:**

> "First thing I always do is verify my Snowflake connection. Cortex Code can see all your configured connections."

```
List my available Snowflake connections
```

**List skills:**

> "Now let's see what skills are available. Skills are like recipes — pre-built workflows that encode best practices."

```
list skills
```

> "See `semantic-view-optimization` and `agent-optimization`? We'll use these later. The key insight is: **someone already figured out the best way to do these tasks** — you don't have to reinvent it."

---

### Step 5: Load Data via Git Integration

**This is a key demo moment:**

> "Here's where it gets interesting. I'm going to ask Cortex Code to read a SQL setup file and execute it. Watch what happens."

```
Read the file CoCo_PawCore_Setup.sql and summarize what it does. Then execute it to set up the PawCore environment. Proceed autonomously — when prompted for SQL permissions, allow all statements in PAWCORE_ANALYTICS.
```

**While it runs, explain:**

> "What's happening here:
> 1. Cortex Code is reading the SQL file — understanding it, not just blindly running it
> 2. It's using Snowflake's **native Git integration** to pull data directly from GitHub
> 3. It's creating databases, schemas, tables — the full environment
> 4. And it's asking for permission before executing potentially destructive SQL
>
> This would normally be 15-20 minutes of copy-paste work. We're doing it in one natural language request."

**WHY THIS MATTERS:** "How many times have you set up a demo environment? How many times did you miss a step or have to debug a typo? This is repeatable, consistent, and documented."

---

### Step 6: Verify Data

```
Run verification queries to confirm the PawCore data loaded correctly. Show me row counts for all tables.
```

> "Always verify. Cortex Code will write and execute the verification queries for us."

**Expected counts:** Telemetry ~21k, Quality Logs ~1k, Reviews ~1.5k

---

## TAB 3: EXERCISE 1 — Build Analytics Environment (25 min)

### Task 1: Review Requirements (5 min)

**Read the context files:**

> "Before we build anything, let's understand the business problem. This is a habit I want you to take away — **always start with context**."

```
Read the pawcore_company_brief.md file and summarize:
1. Company profile and current product lines
2. What happened in Q4 2024 and how it was resolved
3. What PawCore is focused on now
4. Key stakeholders and what they need
```

> "Notice I'm not asking for a generic summary. I'm asking for specific things the business cares about. **The quality of your questions determines the quality of the output.**"

**Follow with discovery notes:**

```
Read pawcore_discovery_notes.md and identify:
1. Rina's top 3 requirements
2. Derek's success criteria
3. The questions the POC needs to answer
```

> "Now we know exactly what success looks like. This isn't just documentation — this is our acceptance criteria."

---

### Task 2: Create Semantic View (10 min)

**Explain the concept first:**

> "A Semantic View is how you teach Cortex Analyst to understand your data. It's not just table definitions — it's business context, relationships, metrics, even sample questions."

```
Explain what a Cortex Analyst semantic view is and why it's important for natural language queries. How is it different from a YAML semantic model? Keep it brief — 3-4 sentences.
```

**WHY THIS MATTERS:** "Your business users don't know SQL. They know 'show me customer satisfaction by region.' The semantic view bridges that gap."

**Create the semantic view:**

```
Create a Cortex Analyst semantic view for the PAWCORE_ANALYTICS database. Proceed autonomously.

The semantic view should:
1. Include the TELEMETRY, QUALITY_LOGS, CUSTOMER_REVIEWS, and SLACK_MESSAGES tables
2. Define relationships between tables (lot_number, device_id)
3. Add business-friendly descriptions and synonyms
4. Define key metrics: avg_battery_level, pass_rate, avg_rating, device_count
5. Frame everything around V2 launch readiness analysis
6. Use CREATE SEMANTIC VIEW SQL syntax

Execute the SQL.
```

**While it generates, explain:**

> "Watch what Cortex Code is doing:
> - It's examining the table structures
> - It's inferring relationships from column names
> - It's creating business-friendly descriptions
> - It's defining calculated metrics
>
> This is the kind of work that usually takes a data engineer half a day to do properly."

**Test it immediately:**

```
Using the semantic view we just created, test these questions:
1. "Which region should we prioritize for V2 launch based on customer satisfaction?"
2. "Compare regional performance — ratings, battery health, and quality pass rates"
3. "Show me quality pass rates by test type — are we above the 95% threshold?"
```

> "These are the actual questions Rina and Derek will ask. We're validating before we ship."

**KEY INSIGHT:** "Notice we're not just testing 'does it work' — we're testing 'does it answer the business questions.' That's the difference between a demo and a solution."

---

### Task 3: Create Cortex Agent & Enable Intelligence (10 min)

**Explain the progression:**

> "We now have:
> - Data (tables)
> - Intelligence (semantic view for Cortex Analyst)
>
> Now we need a user-friendly interface. That's where Cortex Agents come in. An agent combines structured data queries with unstructured document search."

```
Create a Cortex Agent for PawCore's V2 launch readiness analysis. Proceed autonomously and execute all SQL including grants.

The agent should:
1. Be named "PawCore Launch Analyst"
2. Use the semantic view we created
3. Include the Cortex Search Service (PAWCORE_DOCUMENT_SEARCH)
4. Have instructions appropriate for product and executive stakeholders
5. Include sample questions based on the V2 launch scenario
6. Grant USAGE to appropriate roles
7. Use automatic model selection

Execute all SQL.
```

**WHY THIS MATTERS:** "This agent will be the interface for non-technical stakeholders. Rina doesn't need to know SQL or even understand semantic views. She just asks questions in Snowflake Intelligence."

**Enable in Snowflake Intelligence:**

```
Make the PawCore Launch Analyst agent available in Snowflake Intelligence. Proceed autonomously.
```

> "Snowflake Intelligence is the conversational UI where business users interact with agents. With one command, we've made our analytics accessible to the entire organization."

**Test the agent:**

```
Test the agent with questions Rina and Derek would ask:
1. "Rank our regions by V2 launch readiness — consider ratings and battery health"
2. "Which region has the highest customer engagement?"
```

---

## TAB 4: EXERCISE 2 — Master Skills (25 min)

### Task 1: Explore Built-in Skills (10 min)

**List skills:**

```
List all available skills and briefly describe what each does.
```

> "Skills are the secret weapon. Each skill encodes a workflow that someone — usually an expert — has figured out. Instead of reinventing that wheel, you leverage it."

**Highlight relevant skills:**

> "See these?
> - `semantic-view-optimization` — we used something similar when we built our semantic view
> - `agent-optimization` — audits and improves Cortex Agents
> - `cost-management` — analyzes your Snowflake spend
> - `data-governance` — audits access and security
>
> These aren't just shortcuts. They encode **best practices** and **completeness checks** that you'd otherwise miss."

**Explain skill structure:**

```
Explain the structure of a Cortex Code skill:
- What files does it contain?
- What is the SKILL.md format?
- How do skills get triggered?

Keep it concise.
```

**KEY INSIGHT:** "A skill is just a markdown file with a specific structure. You can read it, modify it, create your own. It's not magic — it's documentation that the AI follows."

---

### Task 2: Examine a Bundled Skill (5 min)

```
Show me the structure of the agent-optimization skill.
What workflow steps does it follow?
What checks does it perform on a Cortex Agent?
```

> "This is the value of skills: the agent-optimization skill runs 10+ checks automatically — guardrails, error handling, edge cases, documentation. That would take 30+ minutes to do manually. And you'd probably miss something."

**WHY THIS MATTERS:** "When you're under deadline pressure, are you going to run 10 manual checks? Skills ensure consistency even when you're rushing."

---

### Task 3: Create a Custom Skill (10 min)

**Motivate it:**

> "Built-in skills are great, but the real power is creating your own. Let's build a skill that encodes PawCore's specific launch readiness workflow."

**Define scope first:**

```
I want to create a custom skill called "pawcore-launch-readiness" that helps our team quickly assess launch readiness for new products. Proceed autonomously.

The skill should:
1. Gather launch requirements (target regions, product line, stakeholders)
2. Analyze quality metrics for stability trends
3. Assess customer sentiment by region
4. Generate a launch readiness scorecard
5. Produce a board-ready executive summary

Help me outline the workflow steps. Do not generate the skill yet.
```

> "Notice I'm asking it to plan before creating. This is a good habit — understand the structure before you commit."

**Create the skill:**

```
Create the pawcore-launch-readiness skill in the .cortex/skills/ directory. Proceed autonomously.
```

**WHY THIS MATTERS:** "This skill is now sharable. You can commit it to Git, share it with your team, version it. Every analyst on your team will follow the same rigorous process."

**Test the skill (if time permits):**

```
Use the pawcore-launch-readiness skill to assess whether PawCore is ready to launch SmartCollar V2 in the APAC region.
```

---

## TAB 5: EXERCISE 3 — Generate Documentation (10 min)

### Task 1: Architecture Diagram (3 min)

> "Let's generate stakeholder-ready documentation. First, an architecture diagram."

```
Create a Mermaid architecture diagram showing PawCore's data platform. Proceed autonomously.

Include:
1. Data Sources — Device telemetry, Manufacturing QC, Customer reviews, Internal comms
2. Snowflake Platform — Schemas, Cortex Search, Semantic View
3. Intelligence Layer — Cortex Analyst, Cortex Agent, Snowflake Intelligence
4. Consumers — Rina (VP Product), Derek (CFO), Board, Analytics Team

Save to pawcore_architecture.md
```

> "Mermaid diagrams render in GitHub, Confluence, Notion — anywhere you share documentation. This is immediately usable."

---

### Task 2: Launch Readiness Report (4 min)

```
Based on our analysis, create a V2 Launch Readiness Report. Proceed autonomously.

Include:
1. Executive Summary
2. Regional Readiness Scores
3. Quality Metrics Summary
4. Customer Sentiment Summary
5. Risk Factors
6. Recommendation (go / no-go / conditional)

Save to v2_launch_readiness_report.md
```

> "This is the report Rina takes to the board. It's grounded in actual data — the queries we ran, the analysis we did."

---

### Task 3: Board Presentation Script (3 min)

```
Create a 5-minute board presentation script for Rina. Proceed autonomously.

1. Opening — Reference the Q4 2024 recovery
2. Current State — Quality and customer engagement
3. Regional Analysis — Where we're strong, where we need time
4. Recommendation — Go/no-go with supporting data
5. Q&A Prep — Anticipated questions

Save to board_presentation_script.md
```

> "This is the polished output. We went from raw data to board-ready presentation in under an hour."

---

## CLOSING (3-5 min)

### Recap What We Accomplished

> "Let's step back. In about an hour, we:
> - Set up a complete data environment from a GitHub repo
> - Built a semantic layer that business users can query in natural language
> - Created a Cortex Agent and enabled it in Snowflake Intelligence
> - Explored built-in skills and created a custom one
> - Generated architecture diagrams, reports, and presentation scripts
>
> This would normally be 2-3 days of work. We did it live, in one session."

### The Bigger Picture

> "Cortex Code isn't about replacing engineers. It's about:
> - **Speed** — Get to value faster
> - **Consistency** — Skills encode best practices
> - **Accessibility** — Natural language lowers the barrier
> - **Reusability** — Capture patterns once, use them forever"

### What They Can Do Monday Morning

> "Here's what I want you to try:
> 1. Install Cortex Code CLI — it's one command
> 2. Run `list skills` — see what's already built for you
> 3. Pick one task you do repeatedly — explore if there's a skill for it
> 4. If not, consider creating one and sharing it with your team"

### Q&A Transition

> "I'll stay for questions. What workflows would you like to automate? What parts of your day-to-day could benefit from this?"

---

## TROUBLESHOOTING NOTES

**If SQL execution times out:**
- Simplify the query
- Check warehouse size
- Acknowledge and move on: "Sometimes complex queries need more time — let's proceed and revisit"

**If semantic view queries return unexpected results:**
- Show how to iterate: "This is normal — semantic views need tuning based on real questions"
- Use it as a teaching moment about iteration

**If skill creation fails:**
- Check the .cortex/skills directory exists
- Verify skill.md format
- Simplify the skill and iterate

**If audience gets lost:**
- Pause and recap where we are in the flow
- Reference the Tab structure: "We're in Exercise 2, Task 3"
- Offer to slow down or take questions

---

## KEY PHRASES TO USE

- "This would normally take..." (emphasizes time savings)
- "Notice what's happening here..." (draws attention to key moments)
- "Why this matters to you..." (connects to their use cases)
- "The key insight is..." (highlights takeaways)
- "In the real world, you'd..." (grounds it in practical application)

---

## PHRASES TO AVOID

- "It's just like ChatGPT" (undersells the Snowflake integration)
- "This is magic" (makes it seem unreliable)
- "I'm not sure why it did that" (undermines confidence — instead, explain what happened)
- "Let me try something else" (sounds unprepared — instead, "Let me show another approach")
