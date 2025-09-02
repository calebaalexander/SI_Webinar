## Hands‑On Lab: From Revenue Gap to Resolution with Snowflake Intelligence (PawCore)

### Audience & Duration
- **Audience**: Data/AI practitioners, analytics leaders
- **Duration**: 90 minutes total (75–80 min build + 10–15 min Q&A)

### Storyline (what we’ll prove)
Q4 last year shows an unexplained revenue gap. Returns of the SmartCollar surged due to faulty batteries. The spike was under‑reported because an overwhelmed support analyst failed to log RMAs consistently. We’ll detect the gap, find the root cause across structured and unstructured data, quantify impact, recommend fixes, automate insights with an Intelligent Agent, and email an executive brief—with a bonus: sourcing resumes to fill the staffing gap.

### Tools We’ll Use
- **Cortex Analyst** over semantic views (structured analysis)
- **Semantic views/models** for sales/ops
- **Cortex Search Service** over docs (unstructured)
- **Slack messages, customer reviews, manuals, PDFs, images, audio**
- **AI in SQL**: AI_EXTRACT, AI_CLASSIFY, AI_COMPLETE (plus SENTIMENT)
- **Snowflake Intelligent Agent** with custom email tool

### Agenda (minute by minute)
1. 0–5: Setup context & goal
2. 5–15: Detect the gap with Cortex Analyst (Sales semantic view)
3. 15–25: Drill into SmartCollar EMEA variance
4. 25–35: Hypothesis test with AI in SQL (returns anomaly by lot/week)
5. 35–50: Why it happened (Cortex Search across Slack, reviews, docs) + Extract themes
6. 50–60: Quantify business impact and risk (AI_EXTRACT/COMPLETE)
7. 60–70: Resolution plan + checks/alerts (Analyst + AI_COMPLETE)
8. 70–80: Automate with Intelligent Agent + email the executive; resumes bonus
9. 80–90: Q&A

---

### 0) Setup (5 min)
Use role, warehouse, db, schemas.
```sql
USE ROLE PAWCORE_DEMO_ROLE;
USE WAREHOUSE PAWCORE_INTELLIGENCE_WH;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;
```

[Screenshot here: Snowflake UI context selector showing role/warehouse/db/schema]

---

### 1) Detect the gap with Cortex Analyst (10 min)
Goal: Find Q4 revenue underperformance by region/product.

Ask Cortex Analyst (Sales): “Show Q4 last year variance by region and product; highlight biggest negative.”

If needed, verify service exists (Analyst_PawCore Systems_Sales_Performance).
```sql
SELECT *
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_ANALYST_SERVICES
WHERE ANALYST_SERVICE_NAME = 'Analyst_PawCore Systems_Sales_Performance';
```

[Screenshot here: Analyst chat or SQL result highlighting SmartCollar EMEA variance]

---

### 2) Focus on SmartCollar in EMEA (10 min)
Goal: Confirm where/when the gap appears.
Prompt (Analyst): “Trend SmartCollar in EMEA across Q4; variance vs forecast; annotate spikes.”

[Screenshot here: line chart of ACTUAL vs FORECAST for SmartCollar EMEA]

---

### 3) Hypothesis test with AI in SQL (10 min)
Goal: Are defective batches causing returns?

Create/load RETURNS if needed (already staged as `returns.csv`).
```sql
CREATE TABLE IF NOT EXISTS RETURNS (
  RETURN_ID STRING, DATE DATE, REGION STRING, PRODUCT STRING, LOT_ID STRING,
  REASON STRING, QTY NUMBER, UNIT_COST_EUR NUMBER(10,2), TOTAL_COST_EUR NUMBER(10,2)
);

COPY INTO RETURNS
FROM @INTERNAL_DATA_STAGE/returns.csv
FILE_FORMAT = CSV_FORMAT
FORCE = TRUE ON_ERROR = 'CONTINUE';
```

Weekly anomaly by lot (≥3× baseline pre‑Q4):
```sql
WITH r AS (
  SELECT DATE_TRUNC('WEEK', DATE) AS wk, LOT_ID, SUM(QTY) AS returned
  FROM RETURNS
  WHERE PRODUCT='SmartCollar' AND REGION='EMEA'
  GROUP BY 1,2
), base AS (
  SELECT AVG(returned) AS baseline FROM r WHERE wk < '2024-10-01'
)
SELECT r.wk, r.LOT_ID, r.returned, b.baseline,
       CASE WHEN r.returned >= 3*b.baseline THEN 'FLAG' END AS status
FROM r, base
ORDER BY r.wk, r.LOT_ID;
```

[Screenshot here: table with flagged lot (e.g., 341) showing ≥3× baseline]

---

### 4) Why it happened: unstructured evidence (15 min)
Goal: Corroborate with Slack, reviews, manuals, PDFs, images, audio.

Slack messages (loaded via `SLACK_MESSAGES`):
```sql
SELECT TIMESTAMP, CHANNEL, MESSAGE_TEXT,
       SNOWFLAKE.CORTEX.SENTIMENT(MESSAGE_TEXT) AS sentiment
FROM SLACK_MESSAGES
WHERE MESSAGE_TEXT ILIKE '%SmartCollar%' AND TIMESTAMP >= '2024-10-01'
ORDER BY TIMESTAMP;
```

Customer reviews (`CUSTOMER_REVIEWS`):
```sql
SELECT DATE, CUSTOMER_NAME, RATING, REVIEW_TEXT,
       SNOWFLAKE.CORTEX.SENTIMENT(REVIEW_TEXT) AS sentiment
FROM CUSTOMER_REVIEWS
WHERE PRODUCT='SmartCollar' AND DATE >= '2024-10-01'
ORDER BY DATE;
```

Extract defect themes with AI_EXTRACT:
```sql
SELECT AI_EXTRACT(
  'Extract defect themes (battery, charging, corrosion, moisture, packaging). Return JSON with {theme, evidence}.',
  ARRAY_AGG(REVIEW_TEXT ORDER BY DATE)
) AS defect_themes
FROM CUSTOMER_REVIEWS
WHERE PRODUCT='SmartCollar' AND DATE >= '2024-10-01';
```

Cortex Search over operations/quality docs (service names in Documents schema):
Prompt examples:
- “Find references to SmartCollar battery issues, humidity tests, or packaging changes in Q4.”
- “Summarize procedures related to incoming lot QC for SmartCollar.”

[Screenshot here: Cortex Search results with Quality Control/Packaging references]

Optional: Audio transcript (Quarterly call .mp3) via AI_EXTRACT:
```sql
-- If AUDIO is staged; example extract from text/notes if transcript exists
SELECT AI_EXTRACT(
  'From this transcript, extract mentions of revenue risk, returns, and staffing gaps. JSON list.',
  :transcript_text
);
```

[Screenshot here: extracted bullets from call transcript]

---

### 5) Quantify impact and risk (10 min)
Goal: Size revenue leakage and warranty exposure.
```sql
WITH returns_cost AS (
  SELECT SUM(TOTAL_COST_EUR) AS cost_eur
  FROM RETURNS
  WHERE PRODUCT='SmartCollar' AND REGION='EMEA' AND DATE BETWEEN '2024-10-01' AND '2024-12-31'
)
SELECT cost_eur,
       AI_COMPLETE('Summarize business impact in 3 bullets given cost ' || cost_eur) AS impact_summary
FROM returns_cost;
```

[Screenshot here: numeric impact + crisp AI summary]

---

### 6) Resolution plan + monitoring (10 min)
Goal: Draft and codify a remediation playbook; create a simple alert.
```sql
SELECT AI_COMPLETE(
  'Draft a 6-step remediation plan to address SmartCollar battery returns in EMEA. Include packaging/humidity QC, targeted RA, firmware, and staffing fix.'
) AS plan;

-- Example alert rule sketch (conceptual)
CREATE OR REPLACE VIEW RETURNS_ALERT AS
SELECT LOT_ID, SUM(QTY) AS returned
FROM RETURNS
WHERE DATE >= DATEADD(day,-7,CURRENT_DATE) AND PRODUCT='SmartCollar' AND REGION='EMEA'
GROUP BY LOT_ID
HAVING SUM(QTY) >= 3*(SELECT AVG(QTY) FROM RETURNS WHERE PRODUCT='SmartCollar' AND REGION='EMEA' AND DATE < '2024-10-01');
```

[Screenshot here: generated plan text + alert view preview]

---

### 7) Automate with Snowflake Intelligent Agent (10 min)
Goal: Package findings and deliver to an executive, plus hiring bonus.

Agent exists as `PAWCORE_BI_AGENT` with tools for Analyst + Search + email.

Compose executive email content:
```sql
SELECT PAWCORE_INTELLIGENCE_DEMO.AGENTS.FORMAT_EMAIL_CONTENT(
  'Q4 Revenue Gap – SmartCollar Returns (EMEA): Findings & Actions',
  '<h2>Executive Summary</h2>' ||
  '<p>Identified defective batch returns under-reported due to staffing.</p>' ||
  '<h3>Key Findings</h3><ul>' ||
  '<li>Lot 341: ≥3× baseline returns</li>' ||
  '<li>Slack/reviews indicate battery & packaging/moisture themes</li>' ||
  '<li>Estimated cost exposure detailed in attached summary</li>' ||
  '</ul>' ||
  '<h3>Actions</h3><ul>' ||
  '<li>Reinstate humidity QC; targeted RA; firmware guidance</li>' ||
  '<li>Backfill support analyst to restore RMA logging</li>' ||
  '</ul>'
) AS html_body;
```

Send email via procedure tool:
```sql
CALL PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL(
  'you@example.com',
  'Executive Brief: Q4 SmartCollar Returns (EMEA) – Resolution Plan',
  (SELECT html_body FROM TABLE(result_scan(last_query_id())))
);
``;

[Screenshot here: agent/tool invocation and success message]

Bonus – resumes for staffing gap (use AI_EXTRACT + CLASSIFY on a staged resumes table if present; otherwise prompt Search over HR docs):
```sql
-- Example: Classify candidates by relevance
SELECT candidate_name,
       AI_CLASSIFY('Is this candidate suited for Support Analyst (RMA logging, QA comms)? Return Yes/No.', resume_text) AS suited
FROM HR_RESUMES
ORDER BY suited DESC;
```

[Screenshot here: shortlist of candidates]

---

### Q&A (10–15 min)
- How to adapt to other products/regions?
- Hardening alerts into Tasks/Notifications
- Adding dashboards or powering BI tools
- Extending agent tools (e.g., Slack/Teams post)

---

### Appendix: Handy references
- Semantic views: `PAWCORE_SALES_SEMANTIC_VIEW`, `PAWCORE_OPERATIONS_SEMANTIC_VIEW`
- Analyst services: see `02_Analyst_Services.sql`
- Search services: see `01_Search_Services.sql`
- Returns data: `returns.csv` → `RETURNS`
- Slack: `SLACK_MESSAGES`; Reviews: `CUSTOMER_REVIEWS`
- Device sales: `DEVICE_SALES_BY_REGION`
- Agent: `PAWCORE_BI_AGENT`; Email tool: `SEND_MAIL` + `FORMAT_EMAIL_CONTENT`






