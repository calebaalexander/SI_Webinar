# PawCore Demo Repository

Demo materials for PawCore — a fictional IoT pet technology company building smart devices for pet health monitoring. Used in Snowflake Cortex Code hands-on labs.

## Repository Structure

### 1-Cortex-AI-Snowflake-Intelligence/
Materials from the **Cortex AI and Snowflake Intelligence** webinar (LOT341 humidity investigation story).

- `pawcore_setup.sql` — Original environment setup
- `DQC_AISQL_PAWCORE.ipynb` — Data quality notebook
- `Agent Description_ PawCore.docx` — Agent configuration documentation
- `paw_CLEANUP.sql` — Cleanup script

### 2-Cortex-Code/
Materials for the **Cortex Code CLI and UI** hands-on labs (SmartCollar V2 launch readiness story).

```
2-Cortex-Code/
├── setup/
│   └── CoCo_PawCore_Setup.sql    # One-click environment setup
├── CoCo CLI/                      # CLI lab materials (~30 min)
│   ├── README.md                  # Full walkthrough with Tell-Show-Tell structure
│   ├── pawcore_company_brief.md   # PawCore company profile and growth phase
│   └── pawcore_discovery_notes.md # Stakeholder meeting notes and success criteria
├── CoCo UI/                       # UI lab materials (~33 min)
│   └── README.md                  # Full walkthrough with 5 exercises
├── CoCo Install/                  # Installation and setup guide
│   └── README.md                  # CLI + Snowsight setup for macOS, Windows, Linux
└── data/                          # Sample data files
    ├── Telemetry/                 # Device sensor readings (~21k rows)
    ├── Manufacturing/             # QC test results (~1k rows)
    └── Document_Stage/            # Customer reviews, support tickets, beta feedback
```

## Quick Start — Cortex Code Labs

### Prerequisites

- Snowflake account with ACCOUNTADMIN (or CREATE DATABASE privileges)
- Cortex Code CLI installed ([Install Guide](2-Cortex-Code/CoCo%20Install/README.md))

### Setup

In Cortex Code CLI:
```
Fetch and execute the setup script from https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql to set up the PawCore environment. Proceed autonomously — when prompted for SQL permissions, allow all statements in PAWCORE_ANALYTICS.
```

Or copy the setup script into a Snowsight worksheet and Run All.

### Labs

| Lab | Time | Format | What You Build |
|-----|------|--------|---------------|
| [CoCo CLI](2-Cortex-Code/CoCo%20CLI/) | ~30 min | Terminal + slides | Semantic View, Cortex Agent, custom skill, stakeholder documentation |
| [CoCo UI](2-Cortex-Code/CoCo%20UI/) | ~33 min | Snowsight browser | Screenshot repair, notebook, Dynamic Table, Streamlit app, Intelligence agent |
| [CoCo Install](2-Cortex-Code/CoCo%20Install/) | ~10 min | Setup guide | CLI installation, authentication, Snowsight enablement |

## Data Story

PawCore is preparing to launch SmartCollar V2. Both labs use the same underlying data but ask different questions:

| Lab | Persona | Key Question |
|-----|---------|-------------|
| Cortex AI and SI | Engineering / QA | "What caused the quality issues?" (LOT341) |
| CoCo CLI | Rina Vasquez (VP Product) | "Are we ready to launch V2? Which region first?" |
| CoCo UI | Marcus Thompson (CX Lead) | "Is our support team ready for V2 launch volume?" |
