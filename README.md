# PawCore Demo Repository

Demo materials for PawCore — an IoT pet technology company building smart devices for pet health monitoring.

## Repository Structure

### 1-Cortex-AI-Snowflake-Intelligence/
Materials from the **Cortex AI & Snowflake Intelligence** webinar (LOT341 humidity investigation story).

- `pawcore_setup.sql` — Original environment setup
- `DQC_AISQL_PAWCORE.ipynb` — Data quality notebook
- `Agent Description_ PawCore.docx` — Agent configuration docs
- `paw_CLEANUP.sql` — Cleanup script

### 2-Cortex-Code/
Materials for the **Cortex Code CLI & UI** hands-on labs (V2 launch readiness story).

```
2-Cortex-Code/
├── setup/
│   └── CoCo_PawCore_Setup.sql    # One-click environment setup
├── labs/
│   ├── cli/                       # CLI lab materials
│   │   ├── README.md
│   │   ├── pawcore_company_brief.md
│   │   └── pawcore_discovery_notes.md
│   └── ui/                        # UI lab materials
│       └── README.md
└── data/                          # Sample data files
    ├── Telemetry/
    ├── Manufacturing/
    └── Document_Stage/
```

## Quick Start — Cortex Code Labs

**Setup URL:**
```
https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql
```

In Cortex Code CLI:
```
Fetch and execute the setup script from https://raw.githubusercontent.com/calebaalexander/HandsOnLabs/main/2-Cortex-Code/setup/CoCo_PawCore_Setup.sql
```

## Data Story Differences

| Webinar | Story | Key Question |
|---------|-------|--------------|
| Cortex AI & SI | LOT341 humidity investigation | "What caused the quality issues?" |
| Cortex Code | V2 launch readiness | "Which region should launch first?" |
