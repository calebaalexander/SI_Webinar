# PawCore — V2 Launch Readiness: Discovery Notes

## Meeting Details
| Field | Details |
|-------|---------|
| Date | February 10, 2026 |
| Attendees | Rina Vasquez (VP Product), Derek Huang (CFO), Analytics Team |
| Purpose | Define requirements for V2 Launch Readiness analytics POC |
| Facilitator | You (Data Analyst) |

---

## Rina Vasquez — VP of Product

### What she needs
- A way to assess **regional readiness** for V2 launch
- Visibility into **current product quality trends** — are we stable enough to launch something new?
- Understanding of **customer sentiment by region** — where are customers happiest? Where is there risk?
- **Device performance benchmarks** — how are current SmartCollars performing across regions?

### Key quotes
> "After the LOT341 situation, I'm not launching anything without data backing every decision. Show me quality pass rates trending upward, show me customer satisfaction recovering, and show me which regions are primed for a new product."

> "I want the board to see this in 5 minutes or less. No 50-slide decks. Give me the headline numbers and a clear recommendation."

> "Can we get a system where I can just *ask* questions about our data in plain English? I don't have time to learn SQL."

### Success criteria
1. Regional performance comparison (Americas vs EMEA vs APAC)
2. Quality trend analysis — pass rates over time
3. Customer satisfaction scores by region and product line
4. Self-service interface where she can explore data herself
5. Board-ready summary with go/no-go recommendation

---

## Derek Huang — CFO

### What he needs
- **Cost efficiency data** — which regions give the best ROI for a V2 launch?
- Confidence that **quality is stable** before committing launch budget
- Understanding of **device utilization** — are customers actively using their SmartCollars?

### Key quotes
> "I'll approve the budget when I see the data. Show me the regions with the highest engagement and the strongest quality metrics — that's where we launch first."

> "The LOT341 recall cost us $2.3M. I need to know our current quality posture before I sign off on anything."

### Success criteria
1. Device engagement metrics (charging cycles, active devices)
2. Quality stability confirmation (no downward trends)
3. Regional ranking by performance and customer satisfaction

---

## Existing Data Available

The team confirmed the following data is already in Snowflake (PAWCORE_ANALYTICS database):

| Dataset | Schema | Table | Description |
|---------|--------|-------|-------------|
| Device Telemetry | DEVICE_DATA | TELEMETRY | Sensor readings: battery, humidity, temperature, charging cycles |
| Quality Logs | MANUFACTURING | QUALITY_LOGS | QC test results: pass/fail, measurement values, test types |
| Customer Reviews | SUPPORT | CUSTOMER_REVIEWS | Customer ratings (1-5) and review text by region |
| Slack Messages | SUPPORT | SLACK_MESSAGES | Internal team communications across channels |
| QC Standards | UNSTRUCTURED | PARSED_CONTENT | Parsed PDF content from QC documentation |
| HR Resumes | UNSTRUCTURED | IMAGE_FILES | Candidate resume files |

---

## Agreed Next Steps
1. **Build analytics POC** using Cortex Code CLI
2. **Create a Semantic View** so Cortex Analyst can answer questions in plain English
3. **Set up Snowflake Intelligence** for self-service access
4. **Generate a board presentation** with key metrics and recommendation
5. **Demo to Rina** by end of week — she'll present to the board the following Monday

---

## Questions the POC Should Answer
- What are our top-performing regions based on customer ratings and device performance?
- Compare regional readiness — who leads in quality, battery health, and satisfaction?
- What do quality pass rates look like by test type — are we above 95%?
- Which region should we prioritize for V2 launch and why?
- How does device engagement compare across regions?
- What themes emerge in customer reviews by region?
