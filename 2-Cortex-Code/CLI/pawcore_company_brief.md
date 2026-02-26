# PawCore - Company Brief

## Company Overview
| Field | Details |
|-------|---------|
| Company | PawCore Inc. |
| Industry | Pet Technology / IoT Manufacturing |
| Founded | 2019 |
| Headquarters | Austin, TX |
| Size | 280 employees, 3 global offices |
| Product | SmartCollar — GPS-enabled smart pet collar with health & activity sensors |
| Markets | Americas, EMEA, APAC |
| Annual Revenue | ~$45M (FY2024) |

## Product Line
PawCore manufactures the **SmartCollar**, a smart pet collar that tracks:
- GPS location and activity levels
- Battery health and charging cycles
- Environmental conditions (temperature, humidity)
- Health metrics transmitted to the PawCore mobile app

Current product lines:
- **SmartCollar Pro** — flagship model, full sensor suite
- **SmartCollar Lite** — budget-friendly, GPS + activity only
- **SmartCollar Puppy** — designed for growing pets, adjustable fit

## Recent History
In Q4 2024, PawCore experienced quality issues with manufacturing lot LOT341, particularly in EMEA markets. Using Snowflake's Cortex AI and Intelligence tools, the team identified the root cause (insufficient moisture resistance testing in high-humidity environments) and implemented corrective actions:
- Enhanced QC testing protocols for moisture resistance
- Recalled and replaced affected devices in EMEA
- Updated manufacturing standards for regional climate adaptation

**These issues are fully resolved.** PawCore's quality metrics have returned to baseline and customer satisfaction is recovering.

## Current Situation — Growth Phase
With the quality crisis behind them, PawCore leadership is focused on growth:

### SmartCollar V2 Launch
PawCore is developing **SmartCollar V2**, the next generation of their smart collar featuring:
- Extended battery life (2x current models)
- New health sensors (heart rate, skin temperature)
- Improved water resistance (IP68 rating)
- Integration with veterinary clinic management systems

**Target launch: Q3 2025**

### Market Expansion
- **Veterinary clinics** — B2B partnerships for pet health monitoring
- **Pet resorts & daycares** — bulk device management for commercial clients
- **APAC growth** — expanding distribution in Japan and Australia

### Data-Driven Decision Making
PawCore has data across multiple domains in Snowflake:
- Device telemetry from deployed SmartCollars
- Manufacturing quality control test results
- Customer reviews and ratings
- Internal Slack communications
- QC standards documentation (PDFs)
- HR candidate resumes

Leadership wants to use this data to make informed decisions about the V2 launch.

## Key Stakeholders

### Rina Vasquez — VP of Product
- Owns the SmartCollar V2 launch timeline
- Needs: Regional performance data, quality readiness metrics, customer demand signals
- Quote: *"We can't launch V2 until I'm confident the data shows we're ready. I need a dashboard that tells me — region by region — where we stand."*

### Derek Huang — CFO
- Controls launch budget allocation
- Needs: Data-driven ROI projections, risk assessment
- Quote: *"Show me the numbers. Which regions give us the best return on a V2 launch investment?"*

### Board of Directors
- Final approval on V2 launch timing
- Needs: Executive summary, 5-minute presentation with key metrics
- Expect: Clear go/no-go recommendation backed by data

## Your Role
You are a **data analyst** on PawCore's analytics team. Rina has asked you to build a proof-of-concept analytics environment in Snowflake that demonstrates how the team can use AI-powered tools to:
1. Analyze existing data for V2 launch readiness signals
2. Enable self-service analytics so business users can ask questions without SQL
3. Present a data-driven launch recommendation to the board

You'll use **Cortex Code CLI** to build this POC.
