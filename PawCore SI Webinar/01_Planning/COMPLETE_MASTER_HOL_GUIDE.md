# PawCore Snowflake Intelligence Hands-On Lab: Complete Master Guide

## 🎯 **Workshop Overview**

**Scenario:** PawCore, a pet wellness technology company, has a Q4 revenue mystery. SmartCollar returns surged due to faulty batteries, but the issue was under-reported by an overwhelmed support analyst. You'll play detective using Snowflake Intelligence features to solve this end-to-end.

**Duration:** 90 minutes  
**Audience:** Data analysts, AI practitioners, analytics leaders  
**Complexity:** Intermediate (SQL knowledge helpful but not required)

---

## 🔧 **Pre-Workshop Setup (5 minutes)**

### Prerequisites
✅ **Snowflake Account** with trial or enterprise tier  
✅ **ACCOUNTADMIN** privileges (for initial setup)  
✅ **Modern web browser** (Chrome, Firefox, Safari)  

### What You'll Learn
- **Semantic Views**: Create business-friendly data models
- **Cortex Analyst**: Natural language data querying
- **AI in SQL**: AI_EXTRACT, AI_CLASSIFY, AI_COMPLETE functions
- **Cortex Search**: Unstructured document analysis
- **Intelligent Agents**: Automated insights and actions
- **Custom Tools**: Email integration for executive reporting

---

## 📋 **Step 1: Environment Setup (15 minutes)**

### 1.1 Clone the Repository
```bash
git clone https://github.com/calebaalexander/SI_Webinar.git
cd SI_Webinar
```

### 1.2 Create Snowflake Account Objects
Run the following scripts in order in your Snowflake worksheet:

**Step 1a: Account Setup**
```sql
-- Copy/paste contents from: 05_Demo_Environment/Setup_Scripts/01_Account_Setup.sql
-- This creates roles, warehouses, and databases
```

**Step 1b: Data Loading**
```sql
-- Copy/paste contents from: 05_Demo_Environment/Setup_Scripts/02_Data_Loading.sql
-- This loads all demo data (sales, returns, slack messages, customer reviews, etc.)
```

### 1.3 Upload Files to Snowflake Stages
You'll need to upload the following files via Snowflake UI:

**Internal Data Stage** (`@INTERNAL_DATA_STAGE`):
- `02_Data/Internal Data Stage/pawcore_sales.csv`
- `02_Data/Internal Data Stage/returns.csv` ⭐ **Critical for mystery**
- `02_Data/Internal Data Stage/hr_resumes.csv`
- `02_Data/Internal Data Stage/device_sales_by_region.csv`
- `02_Data/Internal Data Stage/pet_owners.csv`
- `02_Data/Internal Data Stage/vet_feedback.csv`
- `02_Data/Internal Data Stage/fitbit_inventory.csv`
- `02_Data/Internal Data Stage/email_campaigns.csv`
- `02_Data/Internal Data Stage/enhanced_sales_data.csv`
- `02_Data/Internal Data Stage/social_media_posts.csv`

**Document Stage** (`@DOCUMENT_STAGE`):
- `02_Data/Document Stage/customer_reviews.csv` ⭐ **Critical for mystery**
- `02_Data/Document Stage/pawcore_slack.csv` ⭐ **Critical for mystery**
- `02_Data/Document Stage/Q4_2024_PawCore_Financial_Report.md`
- `02_Data/Document Stage/Sales_Performance_Q4_2024.md`
- `02_Data/Document Stage/Quarterly_Sales_Speech_PawCore.md`

**Audio Stage** (`@AUDIO_STAGE`):
- `02_Data/Audio Stage/PawCore Quarterly Call.mp3`

### 1.4 Create Semantic Views
```sql
-- Copy/paste contents from: 05_Demo_Environment/Semantic_Views/01_Sales_Semantic_View.sql
-- Copy/paste contents from: 05_Demo_Environment/Semantic_Views/02_Operations_Semantic_View.sql
```

### 1.5 Set Up Cortex Services
```sql
-- Copy/paste contents from: 05_Demo_Environment/Cortex_Services/02_Analyst_Services.sql
-- Copy/paste contents from: 05_Demo_Environment/Cortex_Services/01_Search_Services.sql
```

### 1.6 Create Intelligent Agent
```sql
-- Copy/paste contents from: 05_Demo_Environment/Agent_Configuration/01_Main_Agent_Setup.sql
-- Copy/paste contents from: 05_Demo_Environment/Agent_Configuration/03_Email_Tool_Configuration.sql
```

### 1.7 Verification
Run this to confirm everything is loaded:
```sql
USE ROLE PAWCORE_WEBINAR_ROLE;
USE WAREHOUSE PAWCORE_INTELLIGENCE_WH;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;

-- Check data counts
SELECT 'PAWCORE_SALES', COUNT(*) FROM PAWCORE_SALES
UNION ALL SELECT 'RETURNS', COUNT(*) FROM RETURNS  -- Should be ~9 rows
UNION ALL SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS
UNION ALL SELECT 'SLACK_MESSAGES', COUNT(*) FROM SLACK_MESSAGES
UNION ALL SELECT 'HR_RESUMES', COUNT(*) FROM HR_RESUMES;

-- Check services
SHOW CORTEX ANALYST SERVICES;
SHOW CORTEX SEARCH SERVICES;
SHOW AGENTS;
```

**✅ Expected Results:**
- RETURNS: 9 rows (key mystery data)
- CUSTOMER_REVIEWS: ~26 rows with Q4 2024 SmartCollar complaints
- SLACK_MESSAGES: ~21 rows with support escalation
- HR_RESUMES: 8 candidates
- 5 Analyst Services, 5 Search Services, 1 Agent

---

## 🕵️ **Step 2: The Mystery Journey (60 minutes)**

### **The Setup: PawCore's Q4 Problem**
*"PawCore's CFO noticed Q4 revenue came in below forecast, especially in EMEA. The SmartCollar product line appears to be underperforming, but the reasons are unclear. As the lead data analyst, you need to investigate what happened and recommend fixes."*

---

### **🔍 Phase 1: Detect the Gap (10 minutes)**

**What you're learning:** Semantic Views + Cortex Analyst for business-friendly data analysis

**Set your context:**
```sql
USE ROLE PAWCORE_WEBINAR_ROLE;
USE WAREHOUSE PAWCORE_INTELLIGENCE_WH;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;
```

**📸 Screenshot Moment:** Show the context selector in Snowflake UI

**Natural Language Query with Cortex Analyst:**
Navigate to your semantic view and ask:
> *"Show Q4 2024 variance by region and product; highlight biggest negative gaps"*

**Alternative SQL approach:**
```sql
SELECT 
    REGION_NAME,
    PRODUCT_NAME,
    SUM(ACTUAL_SALES) as actual_sales,
    SUM(FORECAST_SALES) as forecast_sales,
    SUM(VARIANCE) as variance,
    AVG(PCT_OF_FORECAST) as pct_of_forecast
FROM PAWCORE_SALES_SEMANTIC_VIEW
WHERE DATE >= '2024-10-01' AND DATE <= '2024-12-31'
GROUP BY REGION_NAME, PRODUCT_NAME
ORDER BY variance ASC;
```

**📸 Screenshot Moment:** Results showing SmartCollar EMEA has the worst variance

**🎯 Discovery:** SmartCollar in EMEA region shows significant negative variance vs forecast

---

### **🔍 Phase 2: Focus on the Hotspot (10 minutes)**

**What you're learning:** Drill-down analysis with Cortex Analyst

**Natural Language Follow-up:**
> *"Show me SmartCollar performance trend in EMEA across Q4 2024. Break down by month and highlight when the problems started."*

**Alternative SQL:**
```sql
SELECT 
    DATE_TRUNC('MONTH', DATE) as month,
    REGION_NAME,
    PRODUCT_NAME,
    SUM(ACTUAL_SALES) as actual_sales,
    SUM(FORECAST_SALES) as forecast_sales,
    SUM(VARIANCE) as variance
FROM PAWCORE_SALES_SEMANTIC_VIEW
WHERE PRODUCT_NAME = 'PawCore Systems SmartCollar' 
    AND REGION_NAME = 'Europe'
    AND DATE >= '2024-10-01'
GROUP BY 1,2,3
ORDER BY month;
```

**📸 Screenshot Moment:** Time series showing progressive deterioration through Q4

**🎯 Discovery:** Performance declined progressively through Q4, suggesting an operational issue rather than market conditions

---

### **🔍 Phase 3: Hypothesis Testing with AI in SQL (10 minutes)**

**What you're learning:** AI in SQL functions for anomaly detection

**The Hypothesis:** *"Are defective product batches causing returns?"*

**Load Returns Data:**
```sql
-- Verify returns data is loaded
SELECT * FROM RETURNS 
WHERE PRODUCT = 'SmartCollar' AND REGION = 'EMEA'
ORDER BY DATE;
```

**Detect Batch Anomalies:**
```sql
WITH weekly_returns AS (
    SELECT 
        DATE_TRUNC('WEEK', DATE) AS week_start,
        LOT_ID,
        SUM(QTY) AS returned_units,
        SUM(TOTAL_COST_EUR) AS return_cost
    FROM RETURNS
    WHERE PRODUCT = 'SmartCollar' AND REGION = 'EMEA'
    GROUP BY 1, 2
),
baseline AS (
    SELECT AVG(returned_units) AS avg_baseline
    FROM weekly_returns
    WHERE week_start < '2024-10-01'  -- Pre-Q4 baseline
)
SELECT 
    w.week_start,
    w.LOT_ID,
    w.returned_units,
    b.avg_baseline,
    ROUND(w.returned_units / b.avg_baseline, 2) AS spike_multiplier,
    CASE 
        WHEN w.returned_units >= 3 * b.avg_baseline THEN '🚨 FLAGGED'
        ELSE 'Normal'
    END AS status
FROM weekly_returns w
CROSS JOIN baseline b
WHERE w.week_start >= '2024-10-01'
ORDER BY w.week_start, w.LOT_ID;
```

**📸 Screenshot Moment:** Table showing LOT_ID 341 flagged with 3-7x baseline returns

**🎯 Discovery:** Lot 341 shows abnormal return spikes throughout Q4

---

### **🔍 Phase 4: Unstructured Evidence Gathering (15 minutes)**

**What you're learning:** Cortex Search + AI_EXTRACT for unstructured data analysis

**4a) Check Internal Communications (Slack)**
```sql
-- Load and analyze Slack messages
SELECT 
    TO_TIMESTAMP_NTZ(TRY_TO_NUMBER(SUBSTR(THREAD_ID,1,10))) as timestamp,
    SLACK_CHANNEL,
    TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(TEXT) as sentiment
FROM TEAM_COMMUNICATIONS  -- This loads from pawcore_slack.csv
WHERE TEXT ILIKE '%SmartCollar%' 
   OR TEXT ILIKE '%battery%'
   OR TEXT ILIKE '%return%'
ORDER BY timestamp DESC;
```

**📸 Screenshot Moment:** Slack messages showing support team escalation and battery complaints

**4b) Customer Review Analysis**
```sql
-- Load customer reviews
COPY INTO CUSTOMER_REVIEWS
FROM @DOCUMENT_STAGE/customer_reviews.csv
FILE_FORMAT = CSV_FORMAT
FORCE = TRUE ON_ERROR = 'CONTINUE';

-- Analyze Q4 SmartCollar reviews
SELECT 
    DATE,
    CUSTOMER_NAME,
    RATING,
    REVIEW_TEXT,
    SENTIMENT,
    REGION
FROM CUSTOMER_REVIEWS
WHERE PRODUCT = 'SmartCollar' 
    AND DATE >= '2024-10-01'
    AND RATING <= 2  -- Poor reviews only
ORDER BY DATE;
```

**4c) Extract Defect Themes with AI**
```sql
SELECT AI_EXTRACT(
    'Extract common defect themes from these customer complaints. Return as JSON with theme and frequency count.',
    ARRAY_AGG(REVIEW_TEXT)
) AS defect_analysis
FROM CUSTOMER_REVIEWS
WHERE PRODUCT = 'SmartCollar' 
    AND DATE >= '2024-10-01'
    AND RATING <= 2;
```

**📸 Screenshot Moment:** AI_EXTRACT results showing battery, charging, and moisture themes

**🎯 Discovery:** Consistent pattern of battery failures, charging issues, and moisture-related defects

---

### **🔍 Phase 5: Quantify Business Impact (10 minutes)**

**What you're learning:** AI_COMPLETE for business impact synthesis

**Calculate Financial Impact:**
```sql
WITH return_costs AS (
    SELECT 
        SUM(TOTAL_COST_EUR) as total_return_cost,
        COUNT(*) as return_incidents,
        SUM(QTY) as total_units_returned
    FROM RETURNS
    WHERE PRODUCT = 'SmartCollar' 
        AND REGION = 'EMEA' 
        AND DATE BETWEEN '2024-10-01' AND '2024-12-31'
)
SELECT 
    total_return_cost,
    return_incidents,
    total_units_returned,
    AI_COMPLETE(
        'Given return costs of €' || total_return_cost || 
        ' from ' || return_incidents || ' incidents affecting ' || total_units_returned || 
        ' units, provide a 3-bullet executive summary of business impact and urgency.'
    ) AS impact_summary
FROM return_costs;
```

**📸 Screenshot Moment:** Financial impact summary with AI-generated executive bullets

**🎯 Discovery:** Quantified impact shows significant cost and reputational risk

---

### **🔍 Phase 6: Generate Resolution Plan (10 minutes)**

**What you're learning:** AI_COMPLETE for action planning

**Create Resolution Strategy:**
```sql
SELECT AI_COMPLETE(
    'Create a 6-step remediation plan for SmartCollar battery defects in EMEA. Include: 1) immediate quality control, 2) customer communications, 3) supplier changes, 4) process improvements, 5) monitoring, and 6) staffing fixes. Be specific and actionable.'
) AS remediation_plan;
```

**Set Up Monitoring Alert:**
```sql
CREATE OR REPLACE VIEW RETURNS_ALERT_MONITOR AS
SELECT 
    LOT_ID,
    COUNT(*) as incident_count,
    SUM(QTY) as total_returned,
    SUM(TOTAL_COST_EUR) as cost_impact,
    'HIGH PRIORITY' as alert_level
FROM RETURNS
WHERE DATE >= DATEADD(day, -7, CURRENT_DATE())
    AND PRODUCT = 'SmartCollar'
    AND REGION = 'EMEA'
GROUP BY LOT_ID
HAVING SUM(QTY) >= 25  -- Threshold for immediate attention
ORDER BY total_returned DESC;

-- Check current alerts
SELECT * FROM RETURNS_ALERT_MONITOR;
```

**📸 Screenshot Moment:** Generated remediation plan and active alerts

---

### **🔍 Phase 7: Automate with Intelligent Agent (10 minutes)**

**What you're learning:** Snowflake Intelligent Agent + Custom Tools

**7a) Compose Executive Brief:**
```sql
SELECT PAWCORE_INTELLIGENCE_DEMO.AGENTS.FORMAT_EMAIL_CONTENT(
    'URGENT: Q4 SmartCollar Returns Analysis - Action Required',
    '<h2>Executive Summary</h2>' ||
    '<p><strong>Issue:</strong> SmartCollar returns in EMEA spiked 3-7x normal levels in Q4 due to battery defects in Lot 341.</p>' ||
    '<h3>Key Findings</h3>' ||
    '<ul>' ||
    '<li>🚨 Lot 341 shows abnormal return pattern starting October 2024</li>' ||
    '<li>💰 Return costs: €16,815 from defective units</li>' ||
    '<li>🔋 Root cause: Battery charging/moisture issues confirmed by customer reviews</li>' ||
    '<li>📢 Internal Slack shows support team overwhelmed with RMA process</li>' ||
    '</ul>' ||
    '<h3>Immediate Actions</h3>' ||
    '<ul>' ||
    '<li>✅ Stop shipments from Lot 341 immediately</li>' ||
    '<li>✅ Implement enhanced battery QC testing</li>' ||
    '<li>✅ Issue proactive customer advisory</li>' ||
    '<li>✅ Hire additional support analyst (candidates identified)</li>' ||
    '</ul>' ||
    '<p><strong>Next Steps:</strong> Detailed remediation plan and candidate recommendations attached.</p>'
) AS executive_email;
```

**7b) Send Executive Email:**
```sql
-- Replace with your actual email address
CALL PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL(
    'your-email@company.com',
    'URGENT: Q4 SmartCollar Returns Analysis - Action Required',
    (SELECT executive_email FROM TABLE(result_scan(last_query_id())))
);
```

**📸 Screenshot Moment:** Email sent confirmation

**🎯 Achievement:** Executive briefed with data-driven insights and actionable recommendations

---

### **🔍 Phase 8: Hiring Bonus - Fill the Staffing Gap (5 minutes)**

**What you're learning:** AI_CLASSIFY for candidate screening

**Screen Candidates for Support Analyst Role:**
```sql
SELECT 
    CANDIDATE_NAME,
    POSITION_APPLIED,
    APPLICATION_DATE,
    AI_CLASSIFY(
        'Based on this resume, is this candidate well-suited for a Support Analyst role involving RMA processing, quality control documentation, and customer communication? Answer: Excellent/Good/Fair/Poor with brief reasoning.',
        RESUME_TEXT
    ) AS suitability_assessment,
    AI_EXTRACT(
        'Extract 3 key qualifications that make this candidate suitable for support/QA work. Return as bullet points.',
        RESUME_TEXT
    ) AS key_qualifications
FROM HR_RESUMES
WHERE POSITION_APPLIED IN ('Support Analyst', 'Support Manager')
ORDER BY suitability_assessment DESC;
```

**📸 Screenshot Moment:** Ranked candidate list with AI assessments

**🎯 Final Discovery:** Identified qualified candidates to prevent future under-reporting issues

---

## 🎊 **Workshop Wrap-Up & Q&A (15 minutes)**

### **What We Accomplished**
✅ **Detected** revenue gap using Semantic Views + Cortex Analyst  
✅ **Investigated** with AI in SQL anomaly detection  
✅ **Validated** with unstructured data via Cortex Search  
✅ **Quantified** impact using AI_EXTRACT and AI_COMPLETE  
✅ **Resolved** with automated plan generation  
✅ **Automated** executive reporting via Intelligent Agent  
✅ **Prevented** future issues with AI-assisted hiring  

### **Snowflake Features Mastered**
1. **Semantic Views** - Business-friendly data modeling
2. **Cortex Analyst** - Natural language data queries
3. **AI in SQL** - AI_EXTRACT, AI_CLASSIFY, AI_COMPLETE
4. **Cortex Search** - Unstructured document analysis
5. **Intelligent Agents** - Workflow automation
6. **Custom Tools** - Email integration and external actions

### **Real-World Applications**
- **Financial Services**: Fraud detection and regulatory reporting
- **Healthcare**: Patient outcome analysis and compliance monitoring  
- **Retail**: Customer behavior analysis and inventory optimization
- **Manufacturing**: Quality control and supply chain optimization
- **Technology**: User behavior analysis and system performance monitoring

### **Common Q&A Topics**
- **Q: How to adapt this to other industries?**
  - A: The pattern works for any scenario with structured KPIs, unstructured feedback, and operational data. Change the domain but keep the discovery workflow.

- **Q: Can I integrate with external systems?**
  - A: Yes! Intelligent Agents support webhooks, APIs, and custom procedures for Slack, Teams, ServiceNow, etc.

- **Q: How do I handle larger datasets?**
  - A: Semantic Views scale automatically. For very large datasets, consider partitioning strategies and incremental processing.

- **Q: What about real-time alerts?**
  - A: Use Snowflake Tasks and Streams to trigger alerts based on data changes. The RETURNS_ALERT_MONITOR view can drive automated notifications.

---

## 📚 **Additional Resources**

### **Documentation**
- [Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Cortex Search Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search)
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/en/user-guide/snowflake-intelligence)
- [AI Functions in SQL](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions)

### **Next Steps**
1. **Explore your own data** - Apply these patterns to your organization's data
2. **Build custom agents** - Create agents tailored to your business processes  
3. **Integrate with BI tools** - Connect semantic views to Tableau, PowerBI, etc.
4. **Scale monitoring** - Implement production-ready alerting and automation

### **Support**
- **Snowflake Community**: [community.snowflake.com](https://community.snowflake.com)
- **Documentation**: [docs.snowflake.com](https://docs.snowflake.com)
- **Training**: [learn.snowflake.com](https://learn.snowflake.com)

---

**🎯 Congratulations! You've completed the PawCore Snowflake Intelligence mystery and mastered end-to-end AI-powered analytics!**
