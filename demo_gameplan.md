# PawCore Demo Gameplan

## Phase 1: Initial Problem Discovery
**Context:** Q4 2024 Financial Report shows revenue of $28.1M vs forecast $32.5M (-13.5% variance)

### Tool 1: AI_EXTRACT
**Question:** "Extract key financial metrics and anomalies from Q4 2024 Financial Report"
**Expected Findings:**
- Overall revenue significantly below target (-13.5% variance)
- SmartCollar revenue: $3.4M (-48% below forecast)
- EMEA revenue: $6.5M (-35% below forecast)
**Key Clue:** Major underperformance specifically in EMEA SmartCollar sales

### Tool 2: AI_SENTIMENT
**Question:** "Analyze customer sentiment trends for Q4 2024, focusing on product lines and regions"
**Expected Findings:**
- Multiple negative reviews for SmartCollar in EMEA region
- Reviews REV24Q4_001 through REV24Q4_015 show consistent battery issues
- Pattern of moisture-related complaints
**Key Clue:** EMEA SmartCollar customers experiencing battery failures

### Tool 3: AI_SUMMARIZE_AGG
**Question:** "Summarize Slack communications regarding SmartCollar issues in Q4 2024"
**Expected Findings:**
- October: Initial battery issues reported
- November: Lot 341 identified with moisture sensitivity
- December: Firmware hotfix deployed
**Key Clue:** Manufacturing Lot 341 appears to be the source of issues

## Phase 2: Deep Dive Analysis with Cortex Analyst

### Investigation 1: Manufacturing Quality
**Semantic View:** Manufacturing Quality Analysis
**Questions:**
1. "Compare quality test results between Lot 341 and previous lots"
2. "Analyze moisture resistance test results across lots"
**Expected Findings:**
- Lot 341 passed initial tests but with lower margins
- Moisture resistance tests show borderline results
**Key Clue:** Quality control process gaps in environmental testing

### Investigation 2: Device Performance
**Semantic View:** Device Telemetry Analysis
**Questions:**
1. "Show battery performance patterns by region and lot number"
2. "Correlate humidity readings with battery failures"
**Expected Findings:**
- EMEA devices show accelerated battery drain
- Strong correlation between humidity and battery issues
**Key Clue:** Environmental conditions in EMEA affecting device performance

## Phase 3: Unstructured Data Search

### Tool: Cortex Search Service
**Questions:**
1. "Find manufacturing quality control procedures for battery assembly"
2. "Search for moisture protection standards in device assembly"
**Expected Findings:**
- Current QC process lacks specific humidity exposure tests
- Need for enhanced environmental testing procedures
**Key Clue:** Quality control position needed with specific expertise

## Phase 4: Resume Analysis

### Tool: AI_EXTRACT on Resumes
**Questions:**
1. "Find candidates with battery quality control experience"
2. "Identify expertise in environmental testing and moisture-sensitive electronics"
**Expected Findings:**
- Sarah Chen's profile matches requirements:
  - IEEE Certified Battery Professional
  - Experience with moisture-sensitive electronics
  - International quality standards expertise
**Key Clue:** Qualified candidate identified to improve QC process

## Phase 5: Solution Implementation

### Tool: Snowflake Intelligence Agent
**Purpose:** Combine all findings to:
1. Confirm root cause of Q4 revenue anomaly
2. Propose comprehensive solution
3. Estimate impact and recovery timeline

**Expected Conclusions:**
1. Root Cause:
   - Manufacturing quality control gap for moisture sensitivity
   - EMEA climate conditions exposing the issue
   - Lot 341 particularly affected
   - Revenue impact: ~$4.4M shortfall ($3.1M from SmartCollar + broader EMEA impact)

2. Solution Components:
   - Hire dedicated Quality Control Manager (Sarah Chen)
   - Implement enhanced environmental testing
   - Update manufacturing procedures
   - Establish regional-specific quality controls

3. Impact Assessment:
   - Q4 revenue impact quantified: $4.4M
   - Customer satisfaction recovery plan
   - Long-term quality improvement roadmap
   - Expected recovery timeline: 2-3 quarters

## Key Demo Points to Emphasize

1. **Data Integration:**
   - Structured and unstructured data analysis
   - Multiple data sources providing confirming evidence
   - Cross-functional investigation capabilities

2. **Tool Progression:**
   - AISQL for initial discovery
   - Cortex Analyst for deep dive
   - Search Service for unstructured data
   - Intelligence Agent for solution development

3. **Business Impact:**
   - Significant revenue impact identified ($4.4M)
   - Quality improvement opportunity
   - Customer satisfaction recovery
   - Process enhancement needs

## Demo Requirements Checklist

- [ ] Financial data loaded and accessible
- [ ] Customer reviews indexed for sentiment analysis
- [ ] Slack messages prepared for analysis
- [ ] Device telemetry data populated
- [ ] Manufacturing quality logs loaded
- [ ] Resumes converted to PDF and indexed
- [ ] Semantic views configured
- [ ] Search services established
- [ ] Agent configured with all tools